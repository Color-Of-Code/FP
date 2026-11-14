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
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    linterOptions: { reportUnusedDisableDirectives: "error" },
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
      // Companions to `verbatimModuleSyntax`: Node type stripping keeps every
      // import that is not explicitly marked as type-only.
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { fixStyle: "inline-type-imports" },
      ],
      "@typescript-eslint/no-import-type-side-effects": "error",
      "@typescript-eslint/restrict-template-expressions": [
        "error",
        { allowNumber: true },
      ],
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
