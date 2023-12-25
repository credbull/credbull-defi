const prettierConfig = require('./.prettierrc.cjs');

module.exports = {
  extends: ['next', 'prettier'],
  plugins: ['prettier'],
  rules: {
    'prettier/prettier': ['error', prettierConfig],
  },
};
