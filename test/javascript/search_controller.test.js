import { test, expect, describe, mock } from "bun:test";

// Capture the URLs the controller hands to @rails/request.js without
// booting Stimulus or a real DOM, the same way article_revenue.test.js
// exercises its controller through the bare prototype.
const requests = [];
mock.module("@rails/request.js", () => ({
  get: (url, options) => {
    requests.push({ url, options });
  },
}));

const SearchController = (
  await import("../../app/javascript/controllers/search_controller")
).default;

function makeSearchController(input = "") {
  const c = Object.create(SearchController.prototype);

  c.inputTarget = { value: input };
  c.clearButtonTarget = {
    classList: {
      add: (klass) => c.clearButtonTarget.classListValue.add(klass),
      remove: (klass) => c.clearButtonTarget.classListValue.delete(klass),
    },
    classListValue: new Set(),
  };

  return c;
}

describe("SearchController — search", () => {
  test("encodes & and = so they reach the server as part of the query value", () => {
    const c = makeSearchController();
    c.search("a&b=c");

    expect(requests.pop().url).toBe("/search?query=a%26b%3Dc");
  });

  test("percent-encodes spaces and non-ASCII input", () => {
    const c = makeSearchController();
    c.search("你好 world");

    expect(requests.pop().url).toBe("/search?query=%E4%BD%A0%E5%A5%BD%20world");
  });

  test("leaves plain queries readable", () => {
    const c = makeSearchController();
    c.search("quill");

    expect(requests.pop().url).toBe("/search?query=quill");
  });

  test("an empty query clears the button and issues no request", () => {
    const c = makeSearchController();
    c.search("");

    expect(requests).toHaveLength(0);
    expect(c.clearButtonTarget.classListValue.has("hidden")).toBe(true);
  });
});
