import 'web3';
import { ensureEthAccountExist } from 'utils/mvm';
import { RegistryABI } from 'utils/abis';

export const RegisterAddress = '0x3c84B6C98FBeB813e05a7A7813F0442883450B1F';

export function fetchAssetContract(assetId) {
  return RegistryContract.methods
    .contracts(`0x${assetId.replaceAll('-', '')}`)
    .call();
}

export const RegistryContract = async () => {
  const { web3 } = await ensureEthAccountExist();
  return new web3.eth.Contract(RegistryABI, RegisterAddress);
};
