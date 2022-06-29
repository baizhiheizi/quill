import Web3 from 'web3/dist/web3.min.js';
import { RegistryABI } from './abis';

export const RegisterAddress = '0x3c84B6C98FBeB813e05a7A7813F0442883450B1F';

export class RegistryContract {
  constructor() {
    const web3 = new Web3(ethereum);
    this.Contract = new web3.eth.Contract(RegistryABI, RegisterAddress);
  }

  fetchAssetContract(assetId) {
    return this.Contract.methods
      .contracts(`0x${assetId.replaceAll('-', '')}`)
      .call();
  }
}
