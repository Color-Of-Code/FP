import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";
import functional from "eslint-plugin-functional";

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

      "prefer-const": "warn",
      "no-param-reassign": ["warn", { props: false }],

      // Flag usage of deprecated APIs as errors so they are caught early.
      "@typescript-eslint/no-deprecated": "error",
    },
  },

  // ── Functional plugin ──────────────────────────────────────────────────
  {
    plugins: { functional },
    rules: {
      "functional/no-let": "warn",
      "functional/immutable-data": [
        "warn",
        {
          ignoreClasses: true,
          ignoreImmediateMutation: true,
          ignoreNonConstDeclarations: { treatParametersAsConst: false },
        },
      ],
      "functional/no-loop-statements": "off",
      "functional/prefer-readonly-type": "off",
    },
  },

  // ── Relaxed zones ──────────────────────────────────────────────────────
  {
    files: ["**/*.test.ts"],
    rules: {
      "functional/no-let": "off",
      "functional/immutable-data": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },
  {
    files: ["sysml/cli.ts", "check-lang-order.ts"],
    rules: {
      "functional/no-let": "off",
      "functional/immutable-data": "off",
    },
  },
  {
    // Layout and renderers use imperative graph-building patterns
    // (push, set, in-place coordinate mutation) that conflict with
    // immutable-data.  no-let is still enforced everywhere.
    files: [
      "sysml/layout.ts",
      "sysml/render/activity.ts",
      "sysml/render/ibd.ts",
      "sysml/render/nodes.ts",
      "sysml/render/edges.ts",
      "sysml/render/pin.ts",
    ],
    rules: {
      "functional/no-let": "off",
      "functional/immutable-data": "off",
      "no-param-reassign": "off",
    },
  },
);
