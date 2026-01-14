module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/integration/**/*.test.js'],
  testTimeout: 30000, // 30 seconds for integration tests
  setupFilesAfterEnv: ['<rootDir>/tests/integration/setup.js'],
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  verbose: true,
  runInBand: true, // Run tests serially to avoid Azure resource conflicts
  detectOpenHandles: true,
  forceExit: true
};