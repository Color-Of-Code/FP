import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["sysml/**/*.test.ts"],
    // Allow native ESM .ts imports without a build step.
    pool: "threads",
  },
});
