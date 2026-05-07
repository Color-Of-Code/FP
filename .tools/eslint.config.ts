import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";
import functional from "eslint-plugin-functional";
import lodash from "eslint-plugin-lodash";

export default defineConfig(
  // ── Global ignores ──────────────────────────────────────────────────────
  {
    ignores: [
      "node_modules/**",
      "sysml/generated/**",
      "vscode-sysml/**",
      "coverage/**",
    ],
  },

  // ── TypeScript recommended + stylistic ──────────────────────────────────
  ...tseslint.configs.recommendedTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // ── Base rule overrides (all TS files) ──────────────────────────────────
  {
    rules: {
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      // Langium and ELK types use `any` extensively.
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-unsafe-return": "off",

      "prefer-const": "error",
      "no-param-reassign": ["error", { props: true }],

      "@typescript-eslint/no-deprecated": "error",
    },
  },

  // ── Functional plugin ──────────────────────────────────────────────────
  {
    plugins: { functional },
    rules: {
      "functional/no-let": "error",
      "functional/immutable-data": [
        "error",
        {
          ignoreClasses: true,
          ignoreImmediateMutation: true,
          ignoreNonConstDeclarations: { treatParametersAsConst: false },
        },
      ],
      "functional/no-loop-statements": "warn",
      "functional/prefer-tacit": "warn",
      "functional/prefer-readonly-type": "off",
    },
  },

  // ── Lodash plugin ─────────────────────────────────────────────────────
  {
    plugins: { lodash },
    settings: { lodash: { pragma: "_", version: 4 } },
    rules: {
      "lodash/import-scope": ["error", "member"],
      "lodash/prefer-immutable-method": "warn",
      "lodash/prefer-noop": "warn",
      "lodash/prefer-constant": "warn",
      "lodash/prefer-is-nil": "warn",
    },
  },
);
