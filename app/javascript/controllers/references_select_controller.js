import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';
import TomSelect from 'tom-select';

export default class extends Controller {
  static values = {
    options: Array,
    items: Array,
  };

  connect () {
    this.select = new TomSelect(
      this.element, 
      {
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
              <img src="${option.author.avatar}" class="h-6 w-6 rounded-full my-0" />
              <span>${option.title}</span>
            </div>
            `
          },
          item: (item, escape) => {
            return `<div class="flex items-center space-x-2">
              <img src="${item.author.avatar}" class="h-6 w-6 rounded-full my-0" />
              <span>${item.title}</span>
            </div>
            `
          }
        }
      }
    );
  }

  loadReferenceOptions(query, callback) {
    fetch(
      '/article_references?query=' + encodeURIComponent(query),
      {
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': (document.querySelector("meta[name='csrf-token']") || {}).content,
          'Content-Type': 'application/json',
        },
      }).then(
        response => response.json()
      ).then(
        options => callback(options)
      ).catch(
        () => callback()
      )
  }
}
