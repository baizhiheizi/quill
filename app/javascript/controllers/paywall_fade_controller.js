import { Controller } from "@hotwired/stimulus";

// Positions the inline unlock card at the fade boundary of a locked
// article's content. Server-side `article.authorized?(current_user)`
// remains the sole source of truth for *whether* content is locked — this
// controller only affects the presentation/position of the fade and unlock
// card, so it degrades gracefully (unlock card still visible, just
// unpositioned) with JavaScript disabled.
export default class extends Controller {
  static targets = ["fade", "unlock"];

  connect() {
    this.position();
    this.onResize = this.position.bind(this);
    window.addEventListener("resize", this.onResize);
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize);
  }

  position() {
    if (!this.hasFadeTarget || !this.hasUnlockTarget) return;

    const fadeHeight = this.fadeTarget.offsetHeight;
    this.unlockTarget.style.marginTop = `-${Math.round(fadeHeight * 0.55)}px`;
  }
}
