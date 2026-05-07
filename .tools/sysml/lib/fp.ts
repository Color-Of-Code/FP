/**
 * Thin FP utility wrappers.
 *
 * Re-exports from `lodash-es` for consistency, plus Map-oriented helpers
 * that the layout and renderer code uses instead of plain-object maps.
 */

export { forEach, fromPairs, groupBy, keyBy, mapValues, maxBy, partition, sortBy, times } from "lodash-es";

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
