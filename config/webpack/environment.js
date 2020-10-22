const { environment } = require('@rails/webpacker')
const customizedConfig = require('./customized_config');
const WebpackAssetsManifest = require('webpack-assets-manifest');

environment.config.merge(customizedConfig);

environment.splitChunks();
environment.plugins.insert(
  'Manifest',
  new WebpackAssetsManifest({
    entrypoints: true,
    writeToDisk: true,
    publicPath: true,
    done: function (manifest, _stats) {
      console.log(
        `The manifest has been written to ${manifest.getOutputPath()}`,
      );
      console.log(`${manifest}`);
    },
  }),
);

module.exports = environment
