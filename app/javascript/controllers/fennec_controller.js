import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static targets = ['loginButton'];

  connect() {
    this.ext = window.__MIXIN__ && window.__MIXIN__.mixin_ext;
  }

  async initFennec() {
    if (!this.ext) {
      return;
    }

    if (!this.fennec) {
      this.fennec = await this.ext.enable(location.host);
    }
  }

  async login(event) {
    if (!this.ext) {
      return;
    }
    event.preventDefault();
    await this.initFennec();

    const token = await this.fennec.wallet.signToken({
      payload: { from: location.host },
    });
    post('/auth/fennec/callback', {
      contentType: 'application/json',
      body: {
        token: token,
        return_to: location.pathname,
      },
    }).then(() => {
      Turbo.visit(location.pathname);
    });
  }

  async pay(event) {
    if (!this.ext) {
      return;
    }
    event.preventDefault();
    const { assetId, amount, opponentId, memo, traceId } = event.params;
    console.log(event.params);

    await this.initFennec();
    this.fennec.wallet.transfer({
      asset_id: assetId,
      amount: amount.toFixed(8),
      opponent_id: opponentId,
      memo: memo,
      trace_id: traceId,
    });
  }
}
