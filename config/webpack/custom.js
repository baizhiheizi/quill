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
    alias: {
      '@': 'src',
      '@admin': 'src/apps/admin',
      '@application': 'src/apps/application',
      '@dashboard': 'src/apps/dashboard',
      '@shared': 'src/shared',
      '@graphql': 'src/graphql',
    },
    extensions: ['.css'],
  },
};
