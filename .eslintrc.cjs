module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'prettier'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
  ],
  ignorePatterns: ['dist/', '**/*.test.ts'],
  rules: {
    // 项目基线：允许必要场景下的 any
    '@typescript-eslint/no-explicit-any': 'off',
  },
  overrides: [
    {
      files: ['supabase/functions/**/*.ts'],
      env: { es2022: true },
      rules: {
        // Deno 边缘函数以 URL 导入为主，类型多为 any，放宽严格规则
        '@typescript-eslint/no-unsafe-assignment': 'off',
        '@typescript-eslint/no-unsafe-call': 'off',
        '@typescript-eslint/no-unsafe-member-access': 'off',
        '@typescript-eslint/no-unsafe-argument': 'off',
        '@typescript-eslint/no-redundant-type-constituents': 'off',
        '@typescript-eslint/restrict-template-expressions': 'off',
        '@typescript-eslint/prefer-nullish-coalescing': 'off',
        'no-console': 'off',
      },
    },
  ],
};


