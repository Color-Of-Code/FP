import tseslint from "typescript-eslint";
import functional from "eslint-plugin-functional";

// Phase-0 baseline — warning count will be tracked and ratcheted down.
// After each refactoring phase, tighten rules and reduce --max-warnings.

export default tseslint.config(
  // ── Global ignores ──────────────────────────────────────────────────────
  {
    ignores: [
      "node_modules/**",
      "sysml/generated/**",
      "vscode-sysml/**",
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
      // Relax rules that conflict with the current codebase style.
      // These will be tightened in later phases.
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      // Allow `any` in a few existing patterns (Langium, ELK types).
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-unsafe-return": "off",

      // Prefer const, no param reassign (props will be tightened later).
      "prefer-const": "warn",
      "no-param-reassign": ["warn", { props: false }],
    },
  },

  // ── Functional plugin (mild guardrails) ─────────────────────────────────
  {
    plugins: { functional },
    rules: {
      // Phase 0: warn only — these become errors after refactoring.
      "functional/no-let": "warn",
      "functional/immutable-data": [
        "warn",
        {
          ignoreClasses: true,
          ignoreImmediateMutation: true,
          ignoreNonConstDeclarations: { treatParametersAsConst: false },
        },
      ],
      // no-loop-statements OFF until phase 5.
      "functional/no-loop-statements": "off",
      "functional/prefer-readonly-type": "off",
    },
  },

  // ── Relaxed zones: tests, CLI, layout (until phase 3) ──────────────────
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
    files: ["sysml/layout.ts"],
    rules: {
      // Layout is heavily imperative; relaxed until phase 3 decomposition.
      "functional/no-let": "off",
      "functional/immutable-data": "off",
      "no-param-reassign": "off",
    },
  },
  {
    files: ["sysml/render/activity.ts", "sysml/render/ibd.ts"],
    rules: {
      // Renderers mutate nodes/edges during construction; relaxed until phase 4.
      "functional/no-let": "off",
      "functional/immutable-data": "off",
    },
  },
  {
    files: ["sysml/render/nodes.ts", "sysml/render/edges.ts", "sysml/render/pin.ts"],
    rules: {
      // Node/edge renderers have imperative pin/path logic; relaxed until phase 5.
      "functional/no-let": "off",
      "functional/immutable-data": "off",
    },
  },
);
