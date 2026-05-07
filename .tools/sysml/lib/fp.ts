/**
 * Thin FP utility wrappers.
 *
 * Re-exports from `lodash-es` (eager utilities) and the small slice of
 * `fp-ts` we use for pipelines and Option-typed lookups.  Centralising the
 * FP toolbox here means callers do not import directly from two libraries.
 */

// ── Eager utilities (lodash-es) ───────────────────────────────────────────
export { forEach, fromPairs, groupBy, keyBy, mapValues, maxBy, partition, sortBy, times } from "lodash-es";

// ── Pipelines + ADTs (fp-ts) ──────────────────────────────────────────────
export { pipe, flow, identity, constant } from "fp-ts/lib/function.js";
export * as A from "fp-ts/lib/Array.js";
export * as RA from "fp-ts/lib/ReadonlyArray.js";
export * as O from "fp-ts/lib/Option.js";
export * as R from "fp-ts/lib/Record.js";

import * as Opt from "fp-ts/lib/Option.js";

// ── Map-oriented helpers ──────────────────────────────────────────────────

/** Index items by a key into a `Map`.  Like `keyBy` but returns a `Map`. */
export function indexBy<T>(
  items: readonly T[],
  key: (t: T) => string,
): Map<string, T> {
  return new Map(items.map(item => [key(item), item]));
}

/** Collect values from items into a `Set`. */
export function collectIds<T>(
  items: readonly T[],
  key: (t: T) => string,
): Set<string> {
  return new Set(items.map(key));
}

/** Option-returning `Map.get` — composable in `pipe` / `flow`. */
export const lookup = <K, V>(m: ReadonlyMap<K, V>) =>
  (k: K): Opt.Option<V> => Opt.fromNullable(m.get(k));

/** Predicate: both ids present in the given node map. */
export const bothInMap = <V>(m: ReadonlyMap<string, V>) =>
  (ids: { from: string; to: string }): boolean =>
    m.has(ids.from) && m.has(ids.to);


