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

  async providerValueChanged() {
    if (!this.providerValue) return;

    await this.initWallet();
    if (!window.Wallet) return;

    const provider = Wallet.web3.currentProvider;

    // Bind handlers once and keep a reference so disconnect() can remove
    // them. Stimulus reconnects this controller on every Turbo navigation;
    // without cleanup the singleton wallet provider accumulates stale
    // listeners that all fire on each chain/disconnect event.
    if (!this.boundChainChanged) {
      this.boundChainChanged = (chainId) => {
        console.warn(`Chain changed to ${parseInt(chainId)}`);
        notify(`Network changed to ${parseInt(chainId)}`);
      };
      provider.on("chainChanged", this.boundChainChanged);
    }

    if (!this.boundDisconnect) {
      this.boundDisconnect = () => {
        if (Wallet.provider === "MetaMask") return;

        console.warn("Disconnect");
        Turbo.visit("/logout");
      };
      provider.on("disconnect", this.boundDisconnect);
    }
  }

  async addressValueChanged() {
    if (!this.addressValue) return;

    await this.initWallet();
    if (!window.Wallet?.web3?.currentProvider) return;

    const provider = Wallet.web3.currentProvider;

    if (!this.boundAccountsChanged) {
      this.boundAccountsChanged = (accounts) => {
        notify("Account changed");

        if (accounts[0].toLowerCase() !== this.addressValue.toLowerCase()) {
          this.destroy();
          Turbo.visit("/logout");
        }
      };
      provider.on("accountsChanged", this.boundAccountsChanged);
    }
  }

  disconnect() {
    const provider = window.Wallet?.web3?.currentProvider;
    if (!provider?.removeListener) return;

    if (this.boundChainChanged) {
      provider.removeListener("chainChanged", this.boundChainChanged);
    }
    if (this.boundDisconnect) {
      provider.removeListener("disconnect", this.boundDisconnect);
    }
    if (this.boundAccountsChanged) {
      provider.removeListener("accountsChanged", this.boundAccountsChanged);
    }
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
