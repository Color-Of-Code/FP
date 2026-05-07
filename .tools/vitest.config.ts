import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["sysml/**/*.test.ts", "check-lang-order.test.ts"],
    // Allow native ESM .ts imports without a build step.
    pool: "threads",
    coverage: {
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      include: ["sysml/**/*.ts", "check-lang-order.ts"],
      exclude: [
        "sysml/generated/**",
        "sysml/**/*.test.ts",
        "sysml/test-utils/**",
      ],
      // Thresholds will be enforced starting in phase 5.
    },
  },
});
