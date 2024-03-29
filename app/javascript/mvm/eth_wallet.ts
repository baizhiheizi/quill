import detectEthereumProvider from '@metamask/detect-provider';
import CoinbaseWalletSDK from '@coinbase/wallet-sdk';
import {
  BridgeAddress,
  GasPrice,
  NativeAssetId,
  MVM_CHAIN_ID,
  MVM_RPC_URL,
  RPC_LIST,
  RegisterAddress,
  MVM_CONFIG,
  MirrorAddress,
  RegistryID,
  StorageAddress,
} from './constants';
import RegistryABI from './abis/registry.json' assert { type: 'json' };
import BridgeABI from './abis/bridge.json' assert { type: 'json' };
import ERC20ABI from './abis/erc20.json' assert { type: 'json' };
import ERC721ABI from './abis/erc721.json' assert { type: 'json' };
import MirrorABI from './abis/mirror.json' assert { type: 'json' };
import { EthereumProvider } from '@walletconnect/ethereum-provider';
import { Web3 } from 'web3';
import BigNumber from 'bignumber.js';

interface AppType {
  name: string;
  logoUrl: string;
  wcProjectId: string;
}

export class EthWallet {
  public provider: string;
  public web3: any;
  public account: string;
  public app: AppType;
  public Registry: any;
  public Mirror: any;

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
        throw new Error(`${this.provider} provider not supported!`);
    }

    const accounts = await this.web3.eth.getAccounts();
    this.account = accounts[0];

    this.Registry = new this.web3.eth.Contract(RegistryABI, RegisterAddress);
  }

  async initMetaMask() {
    const provider = await detectEthereumProvider();
    if (provider !== window.ethereum) return;

    if (window.ethereum.providers) {
      const provider = window.ethereum.providers.find((el) => el.isMetaMask);
      this.web3 = new Web3(provider);
    } else {
      this.web3 = new Web3(window.ethereum);
    }
    this.web3.currentProvider.request({ method: 'eth_requestAccounts' });
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
    this.web3.currentProvider.enable();
  }

  async initWalletConnect() {
    const provider = await EthereumProvider.init({
      projectId: this.app.wcProjectId,
      chains: [1],
      optionalChains: Object.keys(RPC_LIST).map((el) => parseInt(el)),
      showQrModal: true,
      rpcMap: RPC_LIST,
    });
    await provider.enable();

    this.web3 = new Web3(provider);
    // if (this.web3.currentProvider.connected) return;
    this.web3.currentProvider.enable();
  }

  async payWithMVM(
    params: {
      assetId: string;
      symbol: string;
      amount: string;
      receivers: string[];
      threshold: number;
      memo: string;
      payerId: string;
    },
    success: (hash?: string) => void,
    fail: (error?: Error) => void,
  ) {
    const { assetId, symbol, amount, receivers, threshold, memo, payerId } =
      params;
    if (memo.length > 200) {
      fail(new Error('Memo too long!'));
      return;
    }

    const contract = await this.fetchUsersContract([payerId], 1);
    if (!contract || !parseInt(contract)) {
      fail(new Error('User contract empty, please deposit some asset first.'));
      return;
    }

    const extra = this.generateExtra(receivers, threshold, memo);

    if (assetId === NativeAssetId) {
      return this.payNative(
        {
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
    const assetContractAddress = await this.fetchAssetContract(assetId);
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      fail(new Error(`${symbol} not registered yet`));
      return;
    }

    const IERC20 = new this.web3.eth.Contract(
      ERC20ABI,
      assetContractAddress,
      this.web3,
    );

    const balance = await IERC20.methods.balanceOf(this.account).call();
    const payAmount = BigNumber(amount).multipliedBy(1e8);
    if (BigNumber(balance).isLessThan(payAmount)) {
      fail(new Error('Insufficient balance'));
      return;
    }
    IERC20.options.gasPrice = await this.web3.eth.getGasPrice();
    IERC20.methods
      .transferWithExtra(contract, payAmount.toFixed(), `0x${extra}`)
      .send({ from: this.account })
      .on('transactionHash', success)
      .on('error', fail);
  }

  async payNative(
    params: {
      symbol: string;
      amount: string;
      contract: string;
      extra: string;
    },
    success: () => void,
    fail: (error: Error) => void,
  ) {
    const { amount, contract, extra } = params;
    const BridgeContract = new this.web3.eth.Contract(
      BridgeABI,
      BridgeAddress,
      {
        from: this.account,
        gasPrice: await this.web3.eth.getGasPrice(),
      },
    );

    const balance = await this.web3.eth.getBalance(this.account);
    const payAmount = BigNumber(amount).multipliedBy(1e18);
    if (BigNumber(balance).isLessThan(payAmount)) {
      fail(new Error('Insufficient balance'));
      return;
    }

    BridgeContract.methods
      .release(contract, `0x${extra}`)
      .send({ from: this.account, value: payAmount.toFixed() })
      .on('transactionHash', success)
      .on('error', fail);
  }

  async transferNFT(
    params: {
      collectionId: string;
      tokenId: number;
      receivers: string[];
      threshold: number;
      memo: string;
      payerId: string;
    },
    success: (hash?: string) => void,
    fail: (error: Error) => void,
  ) {
    const { collectionId, tokenId, receivers, threshold, memo, payerId } =
      params;
    const Mirror = new this.web3.eth.Contract(MirrorABI, MirrorAddress);
    const tokenContract = await Mirror.methods
      .contracts(
        this.web3.utils.hexToNumberString(
          '0x' + collectionId.replaceAll('-', ''),
        ),
      )
      .call();

    const ERC721 = new this.web3.eth.Contract(ERC721ABI, tokenContract);
    const owner = await ERC721.methods.ownerOf(tokenId).call();

    if (this.web3.utils.toChecksumAddress(owner) !== this.account) {
      fail(new Error('Unauthorized'));
      return;
    }

    const extra = this.generateExtra(receivers, threshold, memo);
    const contract = await this.fetchUsersContract([payerId], 1);
    ERC721.options.gasPrice = GasPrice;
    ERC721.methods
      .safeTransferFrom(this.account, MirrorAddress, tokenId, contract + extra)
      .send({ from: this.account })
      .on('transactionHash', success)
      .on('error', fail);
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
      params: [MVM_CONFIG],
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

    const assetContractAddress = await this.fetchAssetContract(assetId);
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

    if (assetId == NativeAssetId) {
      const balance = await this.web3.eth.getBalance(account);
      return BigNumber(balance).dividedBy(1e18).toFixed(8);
    } else {
      try {
        const assetContractAddress = await this.fetchAssetContract(assetId);
        let IERC20 = new this.web3.eth.Contract(ERC20ABI, assetContractAddress);

        const balance = await IERC20.methods.balanceOf(account).call();
        return BigNumber(balance).dividedBy(1e8).toFixed();
      } catch (error) {
        console.error(error);
        return '0';
      }
    }
  }

  fetchAssetContract(assetId: string) {
    return this.Registry.methods
      .contracts(`0x${assetId.replaceAll('-', '')}`)
      .call();
  }

  fetchUsersContract(userIds: string[], threshold = 1) {
    const bufLen = Buffer.alloc(2);
    bufLen.writeUInt16BE(userIds.length);
    const bufThres = Buffer.alloc(2);
    bufThres.writeUInt16BE(threshold);
    const ids = userIds.join('').replaceAll('-', '');
    const identity = `0x${bufLen.toString('hex')}${ids}${bufThres.toString(
      'hex',
    )}`;
    return this.Registry.methods
      .contracts(this.web3.utils.sha3(identity))
      .call();
  }

  generateExtra(receivers: string[], threshold: number, memo: string): string {
    const action = JSON.stringify({
      receivers,
      threshold,
      extra: memo,
    });
    const hex = Buffer.from(action).toString('hex');
    return (
      RegistryID.replaceAll('-', '') +
      StorageAddress.slice(2).toLowerCase() +
      this.web3.utils.sha3(hex).slice(2) +
      hex
    );
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
