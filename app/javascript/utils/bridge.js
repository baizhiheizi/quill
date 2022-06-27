import 'web3';
import { ensureEthAccountExist } from 'utils/mvm';
import { BridgeABI } from 'utils/abis';

export const BridgeAddress = '0x12266b2BbdEAb152f8A0CF83c3997Bc8dbAD0be0';

export const BridgeContract = async () => {
  const { web3 } = await ensureEthAccountExist();
  return new web3.eth.Contract(BridgeABI, BridgeAddress);
};
