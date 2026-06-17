import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";
import TomSelect from "tom-select";
import { renderAvatarHtml } from "../utils/avatar";

export default class extends Controller {
  static values = {
    options: Array,
    items: Array,
  };

  connect() {
    this.select = new TomSelect(this.element, {
      items: this.itemsValue,
      options: this.optionsValue,
      valueField: "id",
      labelField: "title",
      searchField: "title",
      load: (query, callback) => this.loadReferenceOptions(query, callback),
      maxItems: 1,
      render: {
        option: (option, escape) => {
          return `<div class="flex items-center space-x-2">
              ${this.authorAvatarMarkup(option.author)}
              <span>${escape(option.title)}</span>
            </div>
            `;
        },
        item: (item, escape) => {
          return `<div class="flex items-center space-x-2 w-full">
              ${this.authorAvatarMarkup(item.author)}
              <span class="inline-block">${escape(item.title)}</span>
            </div>
            `;
        },
      },
    });
  }

  authorAvatarMarkup(author) {
    const className = "h-6 w-6 rounded-full my-0";

    if (author.avatar) {
      return `<img src="${author.avatar}" class="${className}" style="margin: 0" />`;
    }

    return renderAvatarHtml({
      seed: author.avatar_seed,
      name: author.name,
      className,
    });
  }

  loadReferenceOptions(query, callback) {
    get("/article_references?query=" + encodeURIComponent(query), {
      contentType: "application/json",
      responseKind: "json",
    })
      .then((req) => req.response.json())
      .then((options) => callback(options))
      .catch(() => callback());
  }
}
