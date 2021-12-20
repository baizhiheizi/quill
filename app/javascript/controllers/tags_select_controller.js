import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';
import TomSelect from 'tom-select';

export default class extends Controller {
  static values = {
    items: Array,
  };

  connect() {
    this.select = new TomSelect(this.element, {
      create: true,
      creatFilter: function (input) {
        return input.length >= 2;
      },
      items: this.itemsValue,
      load: (query, callback) => this.loadTagOptions(query, callback),
      maxItems: 4,
    });
  }

  loadTagOptions(query, callback) {
    fetch('/tags?query=' + encodeURIComponent(query), {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': (
          document.querySelector("meta[name='csrf-token']") || {}
        ).content,
        'Content-Type': 'application/json',
      },
    })
      .then((response) => response.json())
      .then((options) =>
        callback(
          options.map((option) => {
            return { text: option, value: option };
          }),
        ),
      )
      .catch(() => callback());
  }
}
