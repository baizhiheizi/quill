import { Controller } from "@hotwired/stimulus";
import { EthWallet } from "../mvm/eth_wallet";
import { notify } from "../utils";
import { WALLET_CONNECT_PROJECT_ID } from "../mvm/constants";

export default class extends Controller {
  static values = {
    provider: String,
    address: String,
    session: String,
  };

  // Each entry maps a provider event name to the bound handler. Handlers are
  // registered once and removed in `disconnect()`; Stimulus reconnects this
  // controller on every Turbo navigation, so without cleanup the singleton
  // wallet provider accumulates stale listeners that all fire on each event.
  boundHandlers = new Map();

  async providerValueChanged() {
    if (!this.providerValue) return;

    await this.initWallet();
    if (!window.Wallet) return;

    const provider = Wallet.web3.currentProvider;

    this.bindWalletListener("chainChanged", provider, (chainId) => {
      console.warn(`Chain changed to ${parseInt(chainId)}`);
      notify(`Network changed to ${parseInt(chainId)}`);
    });

    this.bindWalletListener("disconnect", provider, () => {
      if (Wallet.provider === "MetaMask") return;

      console.warn("Disconnect");
      Turbo.visit("/logout");
    });
  }

  async addressValueChanged() {
    if (!this.addressValue) return;

    await this.initWallet();
    if (!window.Wallet?.web3?.currentProvider) return;

    const provider = Wallet.web3.currentProvider;

    this.bindWalletListener("accountsChanged", provider, (accounts) => {
      notify("Account changed");

      if (accounts[0].toLowerCase() !== this.addressValue.toLowerCase()) {
        this.destroy();
        Turbo.visit("/logout");
      }
    });
  }

  disconnect() {
    const provider = window.Wallet?.web3?.currentProvider;
    if (!provider?.removeListener) return;

    for (const [event, handler] of this.boundHandlers) {
      provider.removeListener(event, handler);
    }
    this.boundHandlers.clear();
  }

  bindWalletListener(event, provider, handler) {
    if (this.boundHandlers.has(event)) return;

    this.boundHandlers.set(event, handler);
    provider.on(event, handler);
  }

  async initWallet() {
    if (!this.providerValue) return;
    if (window.Wallet) return;

    window.Wallet = new EthWallet(this.providerValue, {
      name: "Quill",
      logoUrl: `${location.host}/logo.svg`,
      wcProjectId: WALLET_CONNECT_PROJECT_ID,
    });
    await Wallet.init();

    if (!window.Wallet) {
      console.warn("Failed to init wallet");
    }
  }

  destroy() {
    if (
      !window.Wallet ||
      !window.Wallet.web3 ||
      !window.Wallet.web3.currentProvider ||
      !window.Wallet.web3.currentProvider.disconnect
    )
      return;

    Wallet.web3.currentProvider.disconnect();
  }
}
