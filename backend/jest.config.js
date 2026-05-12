module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'lambda/**/*.js',
    '!lambda/**/node_modules/**',
  ],
  coveragePathIgnorePatterns: ['/node_modules/'],
};
