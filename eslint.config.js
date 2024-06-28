import path from 'path'
import process from 'process'
import { fileURLToPath } from 'url'

import tsEslint from '@typescript-eslint/eslint-plugin'
import tsParser from '@typescript-eslint/parser'
import importPlugin from 'eslint-plugin-import' // Eklendi
import prettierPlugin from 'eslint-plugin-prettier'
import pluginVue from 'eslint-plugin-vue'
import globals from 'globals'
import vueEslintParser from 'vue-eslint-parser'

const fileName = fileURLToPath(import.meta.url)

export default [
  {
    files: [
      'src/**/*.js',
      'src/**/*.ts',
      'src/**/**/*.ts',
      'src/**/*.vue',
      'src/**/**/*.vue',
      'src/*.vue',
      '*.config.ts',
      '*.vue',
      'eslint.config.js',
      '*.ts'
    ],
    languageOptions: {
      parser: vueEslintParser, // Vue dosyalarını doğru şekilde parse etmek için Vue ESLint parser'ı kullanıyoruz
      parserOptions: {
        parser: tsParser, // TypeScript desteği için TypeScript parser'ı kullanıyoruz
        tsconfigRootDir: path.dirname(fileName), // tsconfig.json dosyasının kök dizini
        project: ['./tsconfig.json'], // TypeScript projesinin tsconfig dosyası
        ecmaVersion: 'latest', // ECMAScript 2020 desteği
        sourceType: 'module', // ES6 modüllerini kullanmak için module type
        extraFileExtensions: ['.vue'], // .vue dosyaları için ek dosya uzantısı
        // Vue SFC (Single File Components) için gerekli ayarlar
        ecmaFeatures: {
          jsx: true // JSX desteği
        }
      },
      globals: globals.browser // Tarayıcı ortamı için global değişkenler
    },
    plugins: {
      '@typescript-eslint': tsEslint, // TypeScript desteği için ESLint plugin'i
      vue: pluginVue, // Vue desteği için ESLint plugin'i
      prettier: prettierPlugin, // Prettier entegrasyonu için ESLint plugin'i
      import: importPlugin // Eklendi
    },
    rules: {
      'prettier/prettier': 'error', // Prettier kurallarını ESLint kuralları olarak belirler
      'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off', // Üretim ortamında console.log kullanımı yasak, geliştirme ortamında serbest
      'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off', // Üretim ortamında debugger kullanımı yasak, geliştirme ortamında serbest
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'inline-type-imports' } // TypeScript'te type import'larını tutarlı hale getirme
      ],
      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal'],
          pathGroups: [
            {
              pattern: '@/**',
              group: 'internal'
            }
          ],
          pathGroupsExcludedImportTypes: ['builtin'],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true
          }
        }
      ],
      '@typescript-eslint/naming-convention': [
        'error',
        {
          selector: 'variable',
          format: ['camelCase']
        },
        {
          selector: 'parameter',
          format: ['camelCase'],
          leadingUnderscore: 'allow' // Parametreler camelCase formatında olmalı, önünde underscore olabilir
        },
        {
          selector: 'memberLike',
          modifiers: ['private'],
          format: ['camelCase'],
          leadingUnderscore: 'require' // Özel üyeler camelCase formatında olmalı, önünde underscore olmalı
        },
        {
          selector: 'typeLike',
          format: ['PascalCase'] // Tipler PascalCase formatında olmalı
        }
      ],
      'vue/singleline-html-element-content-newline': 'off', // Tek satırlık HTML ögelerin de yeni satır zorunlu değil
      'vue/multiline-html-element-content-newline': 'off', // Çok satırlık HTML ögelerin de yeni satır zorunlu değil
      'vue/no-multiple-template-root': 'off', // Birden fazla kök template ögesi izni
      '@typescript-eslint/explicit-function-return-type': 'off', // Fonksiyonların dönüş türlerini belirtmek zorunda olmamak
      eqeqeq: ['error', 'always'], // Her zaman strict equality kullanımı (===)
      curly: ['error', 'all'], // Tüm koşul ifadelerinde süslü parantez kullanımı zorunlu
      quotes: ['error', 'single'], // Tek tırnak kullanımı zorunlu
      '@typescript-eslint/no-shadow': 'error' // TypeScript projesinde gölgeleme (shadowing) kuralı
    },
    ignores: [
      'build',
      'dist',
      'coverage',
      'node_modules',
      'public',
      'README.md',
      'CHANGELOG.md',
      'components.d.ts',
      'typed-router.d.ts',
      'auto-imports.d.ts',
      'vite.config.ts'
    ]
  }
]
