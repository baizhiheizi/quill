const theme = {};

module.exports = {
  test: /\.(less)$/i,
  use: [
    {
      loader: 'style-loader',
    },
    {
      loader: 'css-loader', // translates CSS into CommonJS
    },
    {
      loader: 'less-loader', // compiles Less to CSS
      options: {
        lessOptions: {
          modifyVars: theme,
          javascriptEnabled: true,
        },
      },
    },
  ],
};
