const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

module.exports = {
  module: {
    rules: [
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
