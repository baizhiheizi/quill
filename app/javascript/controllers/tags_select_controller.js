import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';
import { get } from '@rails/request.js';
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
      maxItems: 10,
    });
  }

  loadTagOptions(query, callback) {
    get('/tags?query=' + encodeURIComponent(query), {
      contentType: 'application/json',
      responseKind: 'json',
    })
      .then((req) => req.response.json())
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
