export const BridgeAddress: string =
  '0x0915EaE769D68128EEd9711A0bc4097831BE57F3';
export const RegisterAddress: string =
  '0x3c84B6C98FBeB813e05a7A7813F0442883450B1F';
export const MirrorAddress: string =
  '0x3a04D4BeDF76C176C09Ac1F66F583070Ba540DC7';
export const NativeAssetId: string = '43d61dcd-e413-450d-80b8-101d5e903357';
export const GasPrice: string = '10000000';
export const MVM_CHAIN_ID: string = '0x120c7';
export const MVM_RPC_URL: string = 'https://geth.mvm.dev';
export const MVM_EXPLORER_URL: string = 'https://scan.mvm.dev/';
export const MVM_CONFIG = {
  chainId: MVM_CHAIN_ID,
  chainName: 'Mixin Virtual Machine',
  nativeCurrency: {
    name: 'ETH',
    symbol: 'ETH',
    decimals: 18,
  },
  rpcUrls: [MVM_RPC_URL],
  blockExplorerUrls: [MVM_EXPLORER_URL],
};
export const RPC_LIST = {
  1: 'https://cloudflare-eth.com',
  10: 'https://mainnet.optimism.io',
  56: 'https://bsc-dataseed.binance.org',
  137: 'https://polygon-rpc.com',
  42161: 'https://arb1.arbitrum.io/rpc',
  73927: 'https://geth.mvm.dev',
};
