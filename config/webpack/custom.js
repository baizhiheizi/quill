module.exports = {
  resolve: {
    alias: {
      '@': 'src',
      '@admin': 'src/apps/admin',
      '@application': 'src/apps/application',
      '@dashboard': 'src/apps/dashboard',
      '@shared': 'src/shared',
      '@graphql': 'src/graphql',
    },
    extensions: ['.less', '.yaml', '.yml'],
  },
};
