import { Controller } from '@hotwired/stimulus';
import { reloadTheme } from 'mixin-messenger-utils';

export default class extends Controller {
  static targets = ['lightButton', 'darkButton'];

  connect() {
    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      this.defaultMode = 'dark';
    } else {
      this.defaultMode = 'light';
    }

    this.loadDefaultMode();
  }

  loadDefaultMode() {
    if (
      localStorage.theme === 'dark' ||
      (!('theme' in localStorage) && this.defaultMode === 'dark')
    ) {
      this.dark();
    } else {
      this.light();
    }
  }

  toggle() {
    if (
      localStorage.theme === 'dark' ||
      (!('theme' in localStorage) && this.defaultMode === 'dark')
    ) {
      localStorage.theme = 'light';
      this.light();
    } else {
      localStorage.theme = 'dark';
      this.dark();
    }
  }

  light() {
    if (this.hasLightButtonTarget) {
      this.lightButtonTarget.classList.remove('hidden');
    }
    if (this.hasDarkButtonTarget) {
      this.darkButtonTarget.classList.add('hidden');
    }
    document.documentElement.classList.remove('dark');
    const themeColor = document.querySelector('meta[name="theme-color"]');
    themeColor && themeColor.setAttribute('content', '#fff');
    reloadTheme();
  }

  dark() {
    if (this.hasLightButtonTarget) {
      this.lightButtonTarget.classList.add('hidden');
    }
    if (this.hasDarkButtonTarget) {
      this.darkButtonTarget.classList.remove('hidden');
    }
    document.documentElement.classList.add('dark');
    const themeColor = document.querySelector('meta[name="theme-color"]');
    themeColor && themeColor.setAttribute('content', '#1D1E2B');
    reloadTheme();
  }
}
