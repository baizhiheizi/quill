import detectEthereumProvider from '@metamask/detect-provider';
import 'web3';
import { hideLoading } from 'utils/toast';

export const provider = await detectEthereumProvider();
export const MVM_CHAIN_ID = '0x120c7';

export async function ensureEthAccountExist() {
  if (provider !== window.ethereum) return;

  await addMvmChain();
  if (ethereum.chainId !== MVM_CHAIN_ID) return;

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
