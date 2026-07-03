import { Controller } from "@hotwired/stimulus";

// Purely presentational: mobile menu open/close and a scroll-shadow toggle
// on the sticky masthead. Never gates navigation — every link in the
// masthead must keep working with JavaScript disabled.
export default class extends Controller {
  static targets = ["menu"];
  static classes = ["scrolled"];

  connect() {
    this.onScroll = this.onScroll.bind(this);
    window.addEventListener("scroll", this.onScroll, { passive: true });
    this.onScroll();
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll);
  }

  onScroll() {
    if (!this.hasScrolledClass) return;

    if (window.scrollY > 4) {
      this.element.classList.add(this.scrolledClass);
    } else {
      this.element.classList.remove(this.scrolledClass);
    }
  }

  toggleMenu() {
    if (!this.hasMenuTarget) return;

    this.menuTarget.classList.toggle("hidden");
  }

  closeMenu() {
    if (!this.hasMenuTarget) return;

    this.menuTarget.classList.add("hidden");
  }
}
