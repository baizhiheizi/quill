const path = require('path');

module.exports = {
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '..', '..', 'app/javascript/src'),
      '@admin': path.resolve(
        __dirname,
        '..',
        '..',
        'app/javascript/src/apps/admin',
      ),
      '@application': path.resolve(
        __dirname,
        '..',
        '..',
        'app/javascript/src/apps/application',
      ),
      '@shared': path.resolve(
        __dirname,
        '..',
        '..',
        'app/javascript/src/shared',
      ),
      '@graphql': path.resolve(
        __dirname,
        '..',
        '..',
        'app/javascript/src/graphql',
      ),
    },
  },
};
