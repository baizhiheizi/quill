import detectEthereumProvider from '@metamask/detect-provider';
import Web3 from 'web3/dist/web3.min.js';
import { hideLoading } from './toast';

export const MVM_CHAIN_ID = '0x120c7';

export async function ensureEthAccountExist() {
  const provider = await detectEthereumProvider();
  if (provider !== window.ethereum) return;

  await addMvmChain();
  if (ethereum.chainId !== MVM_CHAIN_ID) return;

  await ethereum.request({ method: 'eth_requestAccounts' });

  const web3 = new Web3(ethereum);
  const accounts = await web3.eth.getAccounts();

  return {
    account: accounts[0],
    web3,
  };
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
