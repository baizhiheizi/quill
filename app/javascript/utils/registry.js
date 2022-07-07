import Web3 from 'web3/dist/web3.min.js';
import { RegistryABI } from './abis';
import { Buffer } from 'buffer';
import { initWallet } from './mvm';

export const RegisterAddress = '0x3c84B6C98FBeB813e05a7A7813F0442883450B1F';

export class RegistryContract {
  constructor() {
    if (!window.w3) {
      initWallet();
    }

    this.Contract = new w3.eth.Contract(RegistryABI, RegisterAddress);
  }

  fetchAssetContract(assetId) {
    return this.Contract.methods
      .contracts(`0x${assetId.replaceAll('-', '')}`)
      .call();
  }

  fetchUsersContract(userIds, threshold = 1) {
    const bufLen = Buffer.alloc(2);
    bufLen.writeUInt16BE(userIds.length);
    const bufThres = Buffer.alloc(2);
    bufThres.writeUInt16BE(threshold);
    const ids = userIds.join('').replaceAll('-', '');
    const identity = `0x${bufLen.toString('hex')}${ids}${bufThres.toString(
      'hex',
    )}`;
    console.log(identity);
    return this.Contract.methods
      .contracts(Web3.utils.keccak256(identity))
      .call();
  }
}
