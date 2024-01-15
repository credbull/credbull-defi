const prettierConfig = require('./.prettierrc.cjs');

module.exports = {
    root: true,
    env: {
        node: true,
    },
    parserOptions: {
        ecmaVersion: "latest"
    },
    ignorePatterns: ["**/*.ts"],
    extends: ['prettier'],
    plugins: ['prettier'],
    rules: {
        'prettier/prettier': ['error', prettierConfig],
    },
};
