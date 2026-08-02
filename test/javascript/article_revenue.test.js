import { test, expect, describe } from "bun:test";
import ArticleRevenueController from "../../app/javascript/controllers/article_revenue_controller";

// Create a controller-like object that shares the prototype methods so we can
// exercise the revenue-split math without booting Stimulus or a real DOM.
// Each `has*Target` gate and `*Target.value` mirrors the form fields the
// production template binds.
function makeRevenueController(ratios) {
  const c = Object.create(ArticleRevenueController.prototype);

  const targets = {
    readersRevenueRatio: { value: String(ratios.readers ?? 0.4) },
    authorRevenueRatio: { value: String(ratios.author ?? 0.5) },
    collectionRevenueRatio: { value: String(ratios.collection ?? 0) },
    referenceRevenueRatio: { value: String(ratios.references ?? 0) },
    revenueSummary: { innerHTML: "", classList: { toggle: () => {} } },
  };

  for (const [name, target] of Object.entries(targets)) {
    c[`has${name[0].toUpperCase()}${name.slice(1)}Target`] = true;
    c[`${name}Target`] = target;
  }

  return c;
}

describe("ArticleRevenueController — validateRevenueSplit", () => {
  test("passes for the default 40/10/50 split (readers 40%, platform 10%, author 50%)", () => {
    const c = makeRevenueController({ readers: 0.4, author: 0.5 });
    expect(c.validateRevenueSplit()).toBe(true);
  });

  test("passes when references and collection are included and all ratios sum to 100%", () => {
    const c = makeRevenueController({
      readers: 0.3,
      author: 0.4,
      collection: 0.1,
      references: 0.1,
    });
    // platform 0.1 + readers 0.3 + author 0.4 + collection 0.1 + references 0.1 = 1.0
    expect(c.validateRevenueSplit()).toBe(true);
  });

  test("fails when ratios do not sum to 100%", () => {
    const c = makeRevenueController({
      readers: 0.4,
      author: 0.3, // platform 0.1 + 0.4 + 0.3 = 0.8, missing 0.2
    });
    expect(c.validateRevenueSplit()).toBe(false);
  });

  test("passes within the 0.01 tolerance boundary", () => {
    const c = makeRevenueController({
      readers: 0.4,
      author: 0.499, // 0.1 + 0.4 + 0.499 = 0.999, within 0.01 of 1.0
    });
    expect(c.validateRevenueSplit()).toBe(true);
  });

  test("fails just outside the 0.01 tolerance boundary", () => {
    const c = makeRevenueController({
      readers: 0.4,
      author: 0.489, // 0.1 + 0.4 + 0.489 = 0.989, diff = 0.011 > 0.01
    });
    expect(c.validateRevenueSplit()).toBe(false);
  });
});

describe("ArticleRevenueController — calAuthorRevenueRatio", () => {
  test("author = 0.9 − readers − references − collection (default split)", () => {
    const c = makeRevenueController({
      readers: 0.4,
      author: 0,
      collection: 0,
      references: 0,
    });
    c.calAuthorRevenueRatio();

    expect(parseFloat(c.authorRevenueRatioTarget.value)).toBe(0.5);
  });

  test("author decreases as readers increases", () => {
    const c = makeRevenueController({
      readers: 0.6,
      author: 0,
      collection: 0,
      references: 0,
    });
    c.calAuthorRevenueRatio();

    expect(parseFloat(c.authorRevenueRatioTarget.value)).toBe(0.3);
  });

  test("author accounts for collection and reference cuts", () => {
    const c = makeRevenueController({
      readers: 0.3,
      author: 0,
      collection: 0.05,
      references: 0.05,
    });
    c.calAuthorRevenueRatio();

    // 0.9 - 0.3 - 0.05 - 0.05 = 0.5
    expect(parseFloat(c.authorRevenueRatioTarget.value)).toBe(0.5);
  });
});

describe("ArticleRevenueController — revenueSummaryTemplate", () => {
  test("renders the default split as percentages with 'you', 'early readers', 'platform'", () => {
    const c = makeRevenueController({});
    const html = c.revenueSummaryTemplate(0.5, 0.4, 0.1, 0, 0);

    expect(html).toContain("50%");
    expect(html).toContain("you");
    expect(html).toContain("40%");
    expect(html).toContain("early readers");
    expect(html).toContain("10%");
    expect(html).toContain("platform");
    // No collection or references at zero
    expect(html).not.toContain("collection");
    expect(html).not.toContain("references");
  });

  test("includes collection and references when non-zero", () => {
    const c = makeRevenueController({});
    const html = c.revenueSummaryTemplate(0.4, 0.3, 0.1, 0.1, 0.1);

    expect(html).toContain("10%");
    expect(html).toContain("collection");
    expect(html).toContain("references");
  });
});
