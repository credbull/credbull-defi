module.exports = {
  plugins: ['@trivago/prettier-plugin-sort-imports'],
  singleQuote: true,
  trailingComma: 'all',
  printWidth: 120,
  importOrderSeparation: true,
  importOrderSortSpecifiers: true,
  importOrder: ['<THIRD_PARTY_MODULES>', '^@/', '^../(.*)$', '^[./]'],
  importOrderParserPlugins: ['typescript', 'decorators-legacy'],
};
