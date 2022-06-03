import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';
import TomSelect from 'tom-select';

export default class extends Controller {
  static values = {
    options: Array,
    items: Array,
  };

  connect() {
    this.select = new TomSelect(this.element, {
      items: this.itemsValue,
      options: this.optionsValue,
      valueField: 'id',
      labelField: 'title',
      searchField: 'title',
      load: (query, callback) => this.loadReferenceOptions(query, callback),
      maxItems: 1,
      render: {
        option: (option, escape) => {
          return `<div class="flex items-center space-x-2">
              <img src="${option.author.avatar}" class="h-6 w-6 rounded-full my-0" style="margin: 0" />
              <span>${option.title}</span>
            </div>
            `;
        },
        item: (item, escape) => {
          return `<div class="flex items-center space-x-2 w-full">
              <img src="${item.author.avatar}" class="inline-block h-6 w-6 rounded-full my-0" style="margin: 0" />
              <span class="inline-block">${item.title}</span>
            </div>
            `;
        },
      },
    });
  }

  loadReferenceOptions(query, callback) {
    get('/article_references?query=' + encodeURIComponent(query), {
      contentType: 'application/json',
      responseKind: 'json',
    })
      .then((req) => req.response.json())
      .then((options) => callback(options))
      .catch(() => callback());
  }
}
