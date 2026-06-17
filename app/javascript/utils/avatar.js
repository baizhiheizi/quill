function fnv1aHash(str) {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function firstGrapheme(text) {
  if (!text) return "";
  const str = text.trim();
  if (!str) return "";

  if (typeof Intl !== "undefined" && Intl.Segmenter) {
    const segmenter = new Intl.Segmenter(undefined, {
      granularity: "grapheme",
    });
    const segments = [...segmenter.segment(str)];
    return segments[0]?.segment || str[0];
  }

  return [...str][0] || str[0];
}

export function initials(name) {
  if (!name) return "?";

  const tokens = name.trim().split(/\s+/).filter(Boolean);
  if (tokens.length === 0) return "?";

  return tokens
    .slice(0, 2)
    .map((token) => {
      const grapheme = firstGrapheme(token);
      return /^\p{Script=Latin}$/u.test(grapheme)
        ? grapheme.toUpperCase()
        : grapheme;
    })
    .join("");
}

export function colorFromSeed(seed) {
  const hue = fnv1aHash(String(seed || "")) % 360;
  return `hsl(${hue}, 65%, 45%)`;
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function renderAvatarHtml({ seed, name, className = "" }) {
  const bg = colorFromSeed(seed);
  const text = escapeHtml(initials(name));

  return `<div class="inline-flex items-center justify-center rounded-full text-white font-medium shrink-0 ${className}" style="background-color: ${bg}; margin: 0">${text}</div>`;
}
