# Self-hosted fonts

Latin WOFF2 subsets of Inter and Newsreader, vendored so first paint never
waits on `fonts.googleapis.com` (often slow or unreachable). CJK glyphs use
system fallbacks declared on `--font-sans` / `--font-serif`.

Both families are SIL Open Font License 1.1:

- Inter — https://github.com/rsms/inter
- Newsreader — https://github.com/productiontype/Newsreader

Files were fetched from Fontsource (`@5.2.8` latin subsets).
