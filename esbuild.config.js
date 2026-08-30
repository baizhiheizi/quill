// https://github.com/rails/jsbundling-rails/issues/8#issuecomment-1403699565

const path = require("path");
const esbuild = require("esbuild");
const polyfillNode = require("esbuild-plugin-polyfill-node").polyfillNode;

const minify = process.argv.includes("--minify");
const watch = process.argv.includes("--watch");
const outdir = path.join(process.cwd(), "app/assets/builds");

const jsConfig = {
  entryPoints: ["application.js", "editor.js", "reader.js"],
  bundle: true,
  sourcemap: true,
  publicPath: "assets",
  outdir,
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  minify,
  plugins: [polyfillNode({ polyfills: { inherits: false, fs: true } })],
};

// Separate IIFE CSS bundles (not ESM code-splitting) so Propshaft can
// fingerprint each file. ESM chunks would request un-digested paths.
const cssConfig = {
  entryPoints: [
    path.join(process.cwd(), "app/javascript/styles/editor.css"),
    path.join(process.cwd(), "app/javascript/styles/reader.css"),
  ],
  bundle: true,
  outdir,
  minify,
};

async function run(config) {
  const context = await esbuild.context(config);
  if (watch) {
    await context.watch();
    return;
  }
  await context.rebuild();
  context.dispose();
}

Promise.all([run(jsConfig), run(cssConfig)]).catch(() => process.exit(1));
