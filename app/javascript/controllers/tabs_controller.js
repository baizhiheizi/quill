import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    activeTab: String,
    activeClass: String,
  };

  static targets = ['tab', 'content'];

  connect() {}

  active(event) {
    event.preventDefault();
    const { tabname } = event.params;
    this.activeTabValue = tabname;
  }

  activeTabValueChanged() {
    this.tabTargets.forEach((tab) => {
      if (this.activeTabValue === tab.dataset.tabsTabnameParam) {
        tab.classList.add(...this.activeClassValue.split(' '));
      } else {
        tab.classList.remove(...this.activeClassValue.split(' '));
      }
    });

    this.contentTargets.forEach((content) => {
      if (this.activeTabValue === content.dataset.tabsContentParam) {
        content.classList.remove('hidden');
      } else {
        content.classList.add('hidden');
      }
    });
  }
}
