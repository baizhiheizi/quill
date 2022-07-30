import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  initialize() {}

  connect() {}

  clearWalletCache() {
    localStorage.clear('walletconnect');
    localStorage.clear('isCoinbaseWallet');
  }
}
