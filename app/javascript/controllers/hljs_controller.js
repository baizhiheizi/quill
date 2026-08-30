import { Controller } from "@hotwired/stimulus";
import hljs from "highlight.js/lib/core";

import bash from "highlight.js/lib/languages/bash";
import c from "highlight.js/lib/languages/c";
import cpp from "highlight.js/lib/languages/cpp";
import css from "highlight.js/lib/languages/css";
import diff from "highlight.js/lib/languages/diff";
import go from "highlight.js/lib/languages/go";
import graphql from "highlight.js/lib/languages/graphql";
import ini from "highlight.js/lib/languages/ini";
import java from "highlight.js/lib/languages/java";
import javascript from "highlight.js/lib/languages/javascript";
import json from "highlight.js/lib/languages/json";
import kotlin from "highlight.js/lib/languages/kotlin";
import markdown from "highlight.js/lib/languages/markdown";
import objectivec from "highlight.js/lib/languages/objectivec";
import php from "highlight.js/lib/languages/php";
import plaintext from "highlight.js/lib/languages/plaintext";
import python from "highlight.js/lib/languages/python";
import ruby from "highlight.js/lib/languages/ruby";
import rust from "highlight.js/lib/languages/rust";
import scss from "highlight.js/lib/languages/scss";
import shell from "highlight.js/lib/languages/shell";
import sql from "highlight.js/lib/languages/sql";
import swift from "highlight.js/lib/languages/swift";
import typescript from "highlight.js/lib/languages/typescript";
import xml from "highlight.js/lib/languages/xml";
import yaml from "highlight.js/lib/languages/yaml";

// Curated set of languages likely to appear in technical articles on Quill.
// Importing from `highlight.js` (the package entry) registers all 196 languages
// and ships ~2.4 MB minified. Static imports (not `require(\`...\`)`) are
// required — esbuild cannot bundle dynamic require of language modules.
const LANGUAGES = {
  bash,
  c,
  cpp,
  css,
  diff,
  go,
  graphql,
  html: xml,
  ini,
  java,
  javascript,
  json,
  kotlin,
  markdown,
  objectivec,
  php,
  plaintext,
  python,
  ruby,
  rust,
  scss,
  shell,
  sql,
  swift,
  typescript,
  xml,
  yaml,
};

Object.entries(LANGUAGES).forEach(([name, language]) => {
  hljs.registerLanguage(name, language);
});

export default class extends Controller {
  connect() {
    this.element.querySelectorAll("pre code").forEach((el) => {
      hljs.highlightElement(el);
    });
  }
}
