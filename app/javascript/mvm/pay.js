import { post } from '@rails/request.js';
import { BridgeABI, ERC20ABI } from './abis';
import { BridgeAddress, XIN_ASSET_ID } from './constants';
import { RegistryContract } from './registry';
import BigNumber from 'bignumber.js';

export async function payWithMVM(params, success, fail) {
  if (!w3) {
    throw new Error('Web3 provider not ready');
  }

  const { assetId, symbol, amount, opponentId, memo, mixinUuid } = params;

  const registry = new RegistryContract();
  const contract = await registry.fetchUsersContract([mixinUuid], 1);
  if (!contract || !parseInt(contract)) {
    throw new Error('User contract empty, please deposit some asset first.');
  }
  const accounts = await w3.eth.getAccounts();
  const { extra } = await fetchExtra(opponentId, memo);

  if (assetId === XIN_ASSET_ID) {
    await payXIN(
      {
        symbol,
        amount,
        contract,
        extra,
        account: accounts[0],
      },
      success,
      fail,
    );
  } else {
    const assetContractAddress = await registry.fetchAssetContract(assetId);
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      throw new Error('Desposit some asset first');
    }

    await payERC20(
      {
        assetId,
        symbol,
        amount,
        contract,
        extra,
        account: accounts[0],
        assetContractAddress,
      },
      success,
      fail,
    );
  }
}

export async function payERC20(params, success, fail) {
  const { assetContractAddress, amount, contract, extra, account } = params;

  let IERC20 = new w3.eth.Contract(ERC20ABI, assetContractAddress);

  let payAmount = BigNumber(amount).multipliedBy(BigNumber(1e8));

  const balance = await IERC20.methods.balanceOf(account).call();
  if (BigNumber(balance).isLessThan(payAmount)) {
    throw new Error('Insufficient balance');
  }

  IERC20.methods
    .transferWithExtra(contract, payAmount.toString(), `0x${extra}`)
    .send({ from: account })
    .on('transactionHash', success)
    .on('error', fail);
}

export async function payXIN(params, success, fail) {
  const { amount, contract, extra, account } = params;
  const BridgeContract = new w3.eth.Contract(BridgeABI, BridgeAddress);

  const payAmount = BigNumber(amount).multipliedBy(BigNumber(1e18));
  BridgeContract.methods
    .release(contract, `0x${extra}`)
    .send({ from: account, value: payAmount.toString() })
    .on('transactionHash', success)
    .on('error', fail);
}

export async function fetchExtra(opponentId, memo) {
  const res = await post('/mvm/extras', {
    body: {
      receivers: [opponentId],
      threshold: 1,
      extra: memo,
    },
  });
  return await res.json;
}
