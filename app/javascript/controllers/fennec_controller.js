import { Controller } from '@hotwired/stimulus';

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

    Turbo.visit(
      `/auth/fennec/callback?token=${token}&return_to=${encodeURIComponent(
        location.href,
      )}`,
    );
  }

  async pay(event) {
    if (!this.ext) {
      return;
    }
    event.preventDefault();
    const { assetId, amount, opponentId, memo, traceId, codeId } = event.params;

    await this.initFennec();

    if (codeId) {
      this.fennec.wallet.multisigsPayment({ code: codeId });
    } else {
      this.fennec.wallet.transfer({
        asset_id: assetId,
        amount: amount.toFixed(8),
        opponent_id: opponentId,
        memo: memo,
        trace_id: traceId,
      });
    }
  }
}
