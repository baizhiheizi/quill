import detectEthereumProvider from '@metamask/detect-provider';
import Web3 from 'web3/dist/web3.min.js';
import CoinbaseWalletSDK from '@coinbase/wallet-sdk';
import WalletConnectProvider from '@walletconnect/web3-provider/dist/umd/index.min.js';
import { ERC20ABI } from './abis';
import { RegistryContract } from './registry';
import { NativeAssetId } from './constants';
import BigNumber from 'bignumber.js';

export const MVM_CHAIN_ID = '0x120c7';
export const MVM_RPC_URL = 'https://geth.mvm.dev';

export async function initCoinBase() {
  const coinbaseWallet = new CoinbaseWalletSDK({
    appName: 'Quill',
    appLogoUrl: '/logo.svg',
  });
  const provider = coinbaseWallet.makeWeb3Provider(MVM_RPC_URL, MVM_CHAIN_ID);

  window.w3 = new Web3(provider);

  const addresses = await w3.currentProvider.enable();
  localStorage.setItem('isCoinbaseWallet', addresses);
  w3.provider = 'Coinbase';
}

export async function initMetaMask() {
  const provider = await detectEthereumProvider();
  if (provider !== window.ethereum) return;

  await ethereum.request({ method: 'eth_requestAccounts' });

  window.w3 = new Web3(ethereum);
  w3.provider = 'MetaMask';
}

export async function initWalletConnect() {
  const provider = new WalletConnectProvider({
    rpc: {
      1: 'https://cloudflare-eth.com',
      10: 'https://mainnet.optimism.io',
      56: 'https://bsc-dataseed.binance.org',
      137: 'https://polygon-rpc.com',
      42161: 'https://arb1.arbitrum.io/rpc',
      73927: 'https://geth.mvm.dev',
    },
    supportedChainIds: [1, 10, 56, 137, 42161, 73927],
  });

  await provider.enable();
  window.w3 = new Web3(provider);
  w3.provider = 'WalletConnect';
}

export async function switchToMVM() {
  if (!w3.currentProvider.isMetaMask && !w3.currentProvider.isCoinbaseWallet)
    return;

  ethereum.request({
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

export async function balanceOf(assetId, account) {
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
