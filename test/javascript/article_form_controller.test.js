import { test, expect, describe, beforeAll } from "bun:test";
import ArticleFormController from "../../app/javascript/controllers/article_form_controller";
import { debounce } from "underscore";

// Spy on debounce so we can assert the controller calls `.cancel()` on it
// during disconnect. We don't want a real setTimeout to fire during the test
// — the spy is a no-op function we can introspect.
function makeDebounceSpy() {
  const spy = () => {};
  spy.cancel = () => {
    spy.canceled = true;
  };
  spy.canceled = false;
  return spy;
}

// `disconnect()` references the global `document` and `window` directly,
// matching browser behavior. Bun's test runner doesn't expose these by
// default, so install minimal no-op stand-ins.
beforeAll(() => {
  globalThis.document = {
    addEventListener: () => {},
    removeEventListener: () => {},
  };
  globalThis.window = {
    addEventListener: () => {},
    removeEventListener: () => {},
  };
});

// Build a controller-like object that shares the prototype so we can invoke
// `disconnect()` without booting Stimulus or a real DOM. `element` is a
// getter on Stimulus's Controller, so we override it via Object.defineProperty.
function makeController() {
  const controller = Object.create(ArticleFormController.prototype);
  const debounceSpy = makeDebounceSpy();

  Object.defineProperty(controller, "element", {
    value: { addEventListener: () => {}, removeEventListener: () => {} },
    configurable: true,
    writable: true,
  });

  controller.debouncedAutosave = debounceSpy;
  controller.autosave = { cancelPendingRetry: () => {} };

  return { controller, debounceSpy };
}

describe("ArticleFormController — disconnect lifecycle", () => {
  test("cancels the debounced autosave on disconnect", () => {
    const { controller, debounceSpy } = makeController();

    controller.disconnect();

    expect(debounceSpy.canceled).toBe(true);
  });

  test("underscore debounce() returns a function with a .cancel() method", () => {
    // Regression guard for the underlying assumption the disconnect fix
    // relies on. If Underscore's API ever changes, we want this to fail
    // loudly rather than silently leak timers.
    const debounced = debounce(() => {}, 1000);
    expect(typeof debounced.cancel).toBe("function");
    expect(() => debounced.cancel()).not.toThrow();
  });
});
