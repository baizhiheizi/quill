import { RegistryABI } from './abis';
import { RegisterAddress } from './constants';
import { Buffer } from 'buffer';

export class RegistryContract {
  private web3: any;
  public Contract: any;

  constructor(web3: any) {
    this.web3 = web3;
    this.Contract = new web3.eth.Contract(RegistryABI, RegisterAddress);
  }

  fetchAssetContract(assetId: string) {
    return this.Contract.methods
      .contracts(`0x${assetId.replaceAll('-', '')}`)
      .call();
  }

  fetchUsersContract(userIds: string[], threshold = 1) {
    const bufLen = Buffer.alloc(2);
    bufLen.writeUInt16BE(userIds.length);
    const bufThres = Buffer.alloc(2);
    bufThres.writeUInt16BE(threshold);
    const ids = userIds.join('').replaceAll('-', '');
    const identity = `0x${bufLen.toString('hex')}${ids}${bufThres.toString(
      'hex',
    )}`;
    return this.Contract.methods
      .contracts(this.web3.utils.keccak256(identity))
      .call();
  }
}
