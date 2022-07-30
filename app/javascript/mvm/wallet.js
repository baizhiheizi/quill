import detectEthereumProvider from '@metamask/detect-provider';
import Web3 from 'web3/dist/web3.min.js';
import WalletConnectProvider from '@walletconnect/web3-provider/dist/umd/index.min.js';
import { ERC20ABI } from './abis';
import { RegistryContract } from './registry';
import { NativeAssetId } from './constants';
import BigNumber from 'bignumber.js';

export const MVM_CHAIN_ID = '0x120c7';

export async function initWallet() {
  if (!window.w3) {
    let walletConnect = localStorage.getItem('walletconnect');
    walletConnect = walletConnect && JSON.parse(walletConnect);

    if (walletConnect && walletConnect.connected) {
      await initWalletConnect();
    } else if (window.ethereum && ethereum.isConnected()) {
      await initMetaMask();
    } else {
      throw new Error('No wallet connected');
    }
  }
}

export async function initMetaMask() {
  const provider = await detectEthereumProvider();
  if (provider !== window.ethereum) return;

  await ethereum.request({ method: 'eth_requestAccounts' });

  window.w3 = new Web3(ethereum);
}

export async function initWalletConnect() {
  const provider = new WalletConnectProvider({
    rpc: {
      73927: 'https://geth.mvm.dev',
    },
    chainId: 73927,
    supportedChainIds: [73927],
  });

  await provider.enable();
  window.w3 = new Web3(provider);
}

export async function switchMetaMaskToMVM() {
  if (!window.w3) initMetaMask();
  if (!w3.currentProvider.isMetaMask) return;

  ethereum.request({
    method: 'wallet_addEthereumChain',
    params: [
      {
        chainId: MVM_CHAIN_ID,
        chainName: 'Mixin Virtual Machine',
        nativeCurrency: {
          name: 'Mixin',
          symbol: 'XIN',
          decimals: 18,
        },
        rpcUrls: ['https://geth.mvm.dev'],
        blockExplorerUrls: ['https://scan.mvm.dev/'],
      },
    ],
  });
}

export async function balanceOf(assetId, account) {
  await initWallet();

  if (!account) {
    const accounts = await w3.eth.getAccounts();
    account = accounts[0];
  }
  const registry = new RegistryContract();
  let balance = 0;

  if (assetId == NativeAssetId) {
    balance = await w3.eth.getBalance(account);
    balance = BigNumber(balance).dividedBy(1e18);
  } else {
    try {
      const assetContractAddress = await registry.fetchAssetContract(assetId);
      let IERC20 = new w3.eth.Contract(ERC20ABI, assetContractAddress);

      balance = await IERC20.methods.balanceOf(account).call();
      balance = BigNumber(balance).dividedBy(1e8);
    } catch (error) {
      console.error(error);
    }
  }

  return balance.toString();
}
