// https://github.com/rails/jsbundling-rails/issues/8#issuecomment-1403699565

const path = require("path");
const polyfillNode = require("esbuild-plugin-polyfill-node").polyfillNode;

require("esbuild")
  .context({
    entryPoints: ["application.js"],
    bundle: true,
    sourcemap: true,
    publicPath: "assets",
    outdir: path.join(process.cwd(), "app/assets/builds"),
    absWorkingDir: path.join(process.cwd(), "app/javascript"),
    minify: process.argv.includes("--minify"),
    plugins: [polyfillNode({ polyfills: { inherits: false, fs: true } })],
  })
  .then((context) => {
    if (process.argv.includes("--watch")) {
      // Enable watch mode
      context.watch();
    } else {
      // Build once and exit if not in watch mode
      context.rebuild().then((result) => {
        context.dispose();
      });
    }
  })
  .catch(() => process.exit(1));
