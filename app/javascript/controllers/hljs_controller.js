import { Controller } from "@hotwired/stimulus";
import hljs from "highlight.js/lib/core";

// Curated set of languages likely to appear in technical articles on Quill.
// Importing from `highlight.js` (the package entry) registers all 196 languages
// and ships ~2.4 MB minified; the article-content use case only needs a small
// subset. Adding a language here is a one-line change and costs roughly the
// size of that single grammar module.
const LANGUAGES = [
  "bash",
  "c",
  "cpp",
  "css",
  "diff",
  "go",
  "graphql",
  "html",
  "ini",
  "java",
  "javascript",
  "json",
  "kotlin",
  "markdown",
  "objectivec",
  "php",
  "plaintext",
  "python",
  "ruby",
  "rust",
  "scss",
  "shell",
  "sql",
  "swift",
  "typescript",
  "xml",
  "yaml",
];

LANGUAGES.forEach((name) => {
  hljs.registerLanguage(name, require(`highlight.js/lib/languages/${name}`));
});

export default class extends Controller {
  connect() {
    this.element.querySelectorAll("pre code").forEach((el) => {
      hljs.highlightElement(el);
    });
  }
}
