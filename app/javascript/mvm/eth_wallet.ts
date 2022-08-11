import { post } from '@rails/request.js';
import detectEthereumProvider from '@metamask/detect-provider';
import CoinbaseWalletSDK from '@coinbase/wallet-sdk';
import {
  BridgeAddress,
  GasPrice,
  NativeAssetId,
  MVM_CHAIN_ID,
  MVM_RPC_URL,
  RPC_LIST,
} from './constants';
import { RegistryContract } from './registry';
import { BridgeABI, ERC20ABI } from './abis';
import BigNumber from 'bignumber.js';
import WalletConnectProvider from '@walletconnect/web3-provider/dist/umd/index.min.js';
import Web3 from 'web3/dist/web3.min.js';

interface AppType {
  name: string;
  logoUrl: string;
}

export class EthWallet {
  public provider: string;
  public web3: any;
  public account: string;
  public app: AppType;
  public Registry: RegistryContract;

  constructor(
    provider: 'MetaMask' | 'Coinbase' | 'WalletConnect',
    app: AppType,
  ) {
    this.provider = provider;
    this.app = app;
  }

  async init() {
    switch (this.provider) {
      case 'MetaMask':
        await this.initMetaMask();
        break;
      case 'Coinbase':
        await this.initCoinBase();
        break;
      case 'WalletConnect':
        await this.initWalletConnect();
        break;
      default:
        throw new Error('provider not supported!');
    }
    await this.web3.currentProvider.enable();

    const accounts = await this.web3.eth.getAccounts();
    this.account = accounts[0];

    this.Registry = new RegistryContract(this.web3);

    return this.web3;
  }

  async initMetaMask() {
    const provider = await detectEthereumProvider();
    if (provider !== window.ethereum) return;

    this.web3 = new Web3(window.ethereum);
  }

  async initCoinBase() {
    const coinbaseWallet = new CoinbaseWalletSDK({
      appName: this.app.name,
      appLogoUrl: this.app.logoUrl,
    });
    const provider = coinbaseWallet.makeWeb3Provider(
      MVM_RPC_URL,
      parseInt(MVM_CHAIN_ID),
    );

    this.web3 = new Web3(provider);
  }

  async initWalletConnect() {
    const provider = new WalletConnectProvider({
      rpc: RPC_LIST,
      supportedChainIds: Object.keys(RPC_LIST),
    });
    this.web3 = new Web3(provider);
  }

  async payWithMVM(
    params: {
      assetId: string;
      symbol: string;
      amount: string;
      opponentIds: string[];
      threshold: number;
      memo: string;
      mixinUuid: string;
    },
    success: (hash?: string) => void,
    fail: (error?: Error) => void,
  ) {
    const { assetId, symbol, amount, opponentIds, threshold, memo, mixinUuid } =
      params;
    if (memo.length > 200) {
      fail(new Error('Memo too long!'));
      return;
    }
    const contract = await this.Registry.fetchUsersContract([mixinUuid], 1);
    if (!contract || !parseInt(contract)) {
      fail(new Error('User contract empty, please deposit some asset first.'));
      return;
    }
    const { extra } = await this.fetchExtra(opponentIds, threshold, memo);

    if (assetId === NativeAssetId) {
      return this.payNative(
        {
          assetId,
          symbol,
          amount,
          contract,
          extra,
        },
        success,
        fail,
      );
    } else {
      return this.payERC20(
        {
          assetId,
          symbol,
          amount,
          contract,
          extra,
        },
        success,
        fail,
      );
    }
  }

  async payERC20(
    params: {
      assetId: string;
      symbol: string;
      amount: string;
      contract: string;
      extra: string;
    },
    success: () => void,
    fail: (error: Error) => void,
  ) {
    const { assetId, symbol, amount, contract, extra } = params;
    const assetContractAddress = await this.Registry.fetchAssetContract(
      assetId,
    );
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      fail(new Error(`${symbol} not registered yet`));
      return;
    }

    const IERC20 = new this.web3.eth.Contract(ERC20ABI, assetContractAddress);
    IERC20.options.gasPrice = GasPrice;

    const balance = await this.balanceOf(assetId, this.account);
    if (BigNumber(balance).isLessThan(BigNumber(amount))) {
      fail(new Error('Insufficient balance'));
      return;
    }
    let payAmount = BigNumber(amount).multipliedBy(BigNumber(1e8));

    IERC20.methods
      .transferWithExtra(contract, payAmount.toString(), `0x${extra}`)
      .send({ from: this.account })
      .on('transactionHash', success)
      .on('error', fail);
  }

  async payNative(
    params: {
      assetId: string;
      symbol: string;
      amount: string;
      contract: string;
      extra: string;
    },
    success: () => void,
    fail: (error: Error) => void,
  ) {
    const { assetId, amount, contract, extra } = params;
    const BridgeContract = new this.web3.eth.Contract(BridgeABI, BridgeAddress);
    BridgeContract.options.gasPrice = GasPrice;

    const balance = await this.balanceOf(assetId, this.account);
    if (BigNumber(balance).isLessThan(BigNumber(amount))) {
      fail(new Error('Insufficient balance'));
      return;
    }
    const payAmount = BigNumber(amount).multipliedBy(BigNumber(1e18));

    BridgeContract.methods
      .release(contract, `0x${extra}`)
      .send({ from: this.account, value: payAmount.toString() })
      .on('transactionHash', success)
      .on('error', fail);
  }

  async fetchExtra(
    opponentIds: string[],
    threshold: number,
    memo: string,
  ): Promise<any> {
    const res = await post('/mvm/extras', {
      body: {
        receivers: opponentIds,
        threshold: threshold,
        extra: memo,
      },
    });
    return await res.json;
  }

  switchToMVM() {
    if (
      !this.web3.currentProvider.isMetaMask &&
      !this.web3.currentProvider.isCoinbaseWallet
    ) {
      return;
    }

    this.web3.currentProvider.request({
      method: 'wallet_addEthereumChain',
      params: [
        {
          chainId: MVM_CHAIN_ID,
          chainName: 'Mixin Virtual Machine',
          nativeCurrency: {
            name: 'ETH',
            symbol: 'ETH',
            decimals: 18,
          },
          rpcUrls: ['https://geth.mvm.dev'],
          blockExplorerUrls: ['https://scan.mvm.dev/'],
        },
      ],
    });
  }

  async addTokenToMetaMask(
    assetId: string,
    assetSymbol: string,
    assetIconUrl: string,
    success?: () => void,
    fail?: (error?: Error) => void,
  ) {
    if (!this.web3.currentProvider.isMetaMask) return;
    if (assetId === NativeAssetId) return;

    const assetContractAddress = await this.Registry.fetchAssetContract(
      assetId,
    );
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      fail(new Error(`Asset ${assetSymbol} not registered yet`));
      return;
    }
    await this.web3.currentProvider
      .request({
        method: 'wallet_watchAsset',
        params: {
          type: 'ERC20',
          options: {
            address: assetContractAddress,
            symbol: assetSymbol,
            decimals: 8,
            image: assetIconUrl,
          },
        },
      })
      .then((res: boolean) => {
        if (res) {
          success();
        } else {
          fail(new Error('Failed to add token'));
        }
      });
  }

  async balanceOf(assetId: string, account?: string) {
    if (!account) {
      account = this.account;
    }

    const registry = new RegistryContract(this.web3);
    let balance: number | BigNumber = 0;

    if (assetId == NativeAssetId) {
      balance = await this.web3.eth.getBalance(account);
      balance = BigNumber(balance).dividedBy(1e18);
    } else {
      try {
        const assetContractAddress = await registry.fetchAssetContract(assetId);
        let IERC20 = new this.web3.eth.Contract(ERC20ABI, assetContractAddress);

        balance = await IERC20.methods.balanceOf(account).call();
        balance = BigNumber(balance).dividedBy(1e8);
      } catch (error) {
        console.error(error);
      }
    }

    return balance.toString();
  }

  isCurrentNetworkMvm() {
    if (this.web3) {
      return (
        parseInt(this.web3.currentProvider.chainId) === parseInt(MVM_CHAIN_ID)
      );
    } else {
      return false;
    }
  }
}
