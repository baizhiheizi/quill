const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

module.exports = {
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'esbuild-loader',
        options: {
          loader: 'tsx', // Or 'ts' if you don't need tsx
          target: 'es2015',
        },
      },
      {
        test: /\.(less)$/i,
        use: [
          {
            loader: 'less-loader', // compiles Less to CSS
            options: {
              lessOptions: {
                modifyVars: {},
                javascriptEnabled: true,
              },
            },
          },
        ],
      },
      {
        test: /\.ya?ml$/,
        use: 'yaml-loader',
        type: 'json',
      },
      {
        test: /\.(graphql|gql)$/,
        exclude: /node_modules/,
        loader: 'graphql-tag/loader',
      },
    ],
  },
  resolve: {
    extensions: ['.css'],
  },
  plugins: [new NodePolyfillPlugin()],
};
