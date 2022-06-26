import 'web3';
import { ensureEthAccountExist } from 'utils/mvm';
import { RegisterABI } from 'utils/abis';

export const RegisterAddress = '0x3c84B6C98FBeB813e05a7A7813F0442883450B1F';

export async function fetchAssetContract(assetId) {
  const { web3 } = await ensureEthAccountExist();
  let Contract = new web3.eth.Contract(RegisterABI, RegisterAddress);
  return await Contract.methods
    .contracts(`0x${assetId.replaceAll('-', '')}`)
    .call();
}
