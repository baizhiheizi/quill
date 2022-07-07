import detectEthereumProvider from '@metamask/detect-provider';
import Web3 from 'web3/dist/web3.min.js';
import WalletConnectProvider from '@walletconnect/web3-provider/dist/umd/index.min.js';
import { hideLoading } from './toast';

export const MVM_CHAIN_ID = '0x120c7';

export async function initWallet() {
  if (window.w3) return;

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

export async function initMetaMask() {
  const provider = await detectEthereumProvider();
  if (provider !== window.ethereum) return;

  await addMvmChain();
  if (ethereum.chainId !== MVM_CHAIN_ID) return;

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

export async function addMvmChain() {
  ethereum
    .request({
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
    })
    .finally(hideLoading);
}
