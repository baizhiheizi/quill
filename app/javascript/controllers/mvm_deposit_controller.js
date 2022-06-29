import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';
import { RegistryContract, notify, showLoading, hideLoading } from 'utils';

export default class extends Controller {
  static values = {
    assetId: String,
    assetSymbol: String,
    assetIconUrl: String,
    identifier: String,
  };

  static targets = [
    'qrcode',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
  ];

  connect() {
    document
      .querySelector('#modal-slot')
      .addEventListener('modal:ok', (event) => {
        const identifier = event.detail.identifier;

        if (identifier === this.identifierValue) {
          this.assetIdValue = event.detail.assetId;
          this.assetSymbolValue = event.detail.symbol;
          this.assetIconUrlValue = event.detail.iconUrl;

          this.currencyIconTargets.forEach((icon) => {
            icon.src = event.detail.iconUrl;
          });
          this.currencyChainIconTarget.src = event.detail.chainIconUrl;
          this.currencySymbolTarget.innerText = event.detail.symbol;
        }
      });
  }

  async addToken() {
    if (!this.assetIdValue) return;

    showLoading();
    try {
      const registry = new RegistryContract();
      const assetContractAddress = await registry.fetchAssetContract(
        this.assetIdValue,
      );

      console.log(assetContractAddress);

      if (!assetContractAddress || !parseInt(assetContractAddress)) {
        notify(`Desposit some ${this.assetSymbolValue} first`, 'warning');
        return;
      }

      await ethereum
        .request({
          method: 'wallet_watchAsset',
          params: {
            type: 'ERC20',
            options: {
              address: assetContractAddress,
              symbol: this.assetSymbolValue,
              decimals: 8,
              image: this.assetIconUrlValue,
            },
          },
        })
        .then((success) => {
          if (success) {
            notify(`Successfully add ${this.assetSymbolValue}`, 'success');
          } else {
            notify(`Failed to add ${this.assetSymbolValue}`, 'warning');
          }
        });
    } catch (error) {
      notify(error, 'danger');
    }

    hideLoading();
  }

  selectCurrency(event) {
    const asset_id = event.target.value;
    get(`/dashboard/destination?asset_id=${asset_id}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }

  assetIdValueChanged() {
    if (!this.assetIdValue) return;

    this.fetchDesination();
  }

  fetchDesination() {
    get(`/dashboard/destination?asset_id=${this.assetIdValue}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
