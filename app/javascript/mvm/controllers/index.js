import { Application } from '@hotwired/stimulus';

if (!window.Stimulus) {
  const application = Application.start();
  window.Stimulus = application;
}

import CoinbaseController from './coinbase_controller.js';
Stimulus.register('coinbase', CoinbaseController);

import MetamaskController from './metamask_controller.js';
Stimulus.register('metamask', MetamaskController);

import MvmDepositController from './mvm_deposit_controller.js';
Stimulus.register('mvm-deposit', MvmDepositController);

import MvmPayController from './mvm_pay_controller.js';
Stimulus.register('mvm-pay', MvmPayController);

import SwapController from './swap_controller.js';
Stimulus.register('swap', SwapController);

import WalletConnectController from './wallet_connect_controller.js';
Stimulus.register('wallet-connect', WalletConnectController);
