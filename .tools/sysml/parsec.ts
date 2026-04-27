/**
 * Minimal token-stream parser combinator library (Parsec-style).
 *
 * A Parser<A> is a pure function
 *   (tokens: readonly string[], pos: number) → { value: A, pos: newPos } | null
 *
 * Combinators compose parsers without ever mutating state, so backtracking
 * is free: a failing parser always returns null at the original position.
 *
 * Core vocabulary
 *   tok / satisfy / anyTok   — primitive matchers
 *   .map / .flatMap          — transform / monadic bind
 *   .thenR / .thenL          — sequence, keep right ( *> ) or left ( <* )
 *   .then                    — sequence, keep both as a tuple
 *   .or                      — ordered choice
 *   .opt                     — optional (Parser<A | undefined>)
 *   .many / .many1           — repetition
 *   alt / lookahead / lazy   — multi-choice, zero-width peek, forward-ref
 */

export type PR<A> = { value: A; pos: number } | null;

export class Parser<A> {
  readonly _run: (ts: readonly string[], pos: number) => PR<A>;

  constructor(run: (ts: readonly string[], pos: number) => PR<A>) {
    this._run = run;
  }

  /** Transform the result value without consuming extra input. */
  map<B>(f: (a: A) => B): Parser<B> {
    return new Parser((ts, pos) => {
      const r = this._run(ts, pos);
      return r ? { value: f(r.value), pos: r.pos } : null;
    });
  }

  /** Monadic bind: run this, feed the result to f, run the returned parser. */
  flatMap<B>(f: (a: A) => Parser<B>): Parser<B> {
    return new Parser((ts, pos) => {
      const r = this._run(ts, pos);
      if (!r) return null;
      return f(r.value)._run(ts, r.pos);
    });
  }

  /** Sequence: run this then pb, keep both results as a tuple. */
  then<B>(pb: Parser<B>): Parser<[A, B]> {
    return this.flatMap(a => pb.map(b => [a, b] as [A, B]));
  }

  /** Sequence: run this then pb, discard this result — keep right.  ( *> ) */
  thenR<B>(pb: Parser<B>): Parser<B> {
    return this.flatMap(() => pb);
  }

  /** Sequence: run this then pb, discard pb's result — keep left.  ( <* ) */
  thenL<B>(pb: Parser<B>): Parser<A> {
    return this.flatMap(a => pb.map(() => a));
  }

  /** Ordered choice: try this; if it fails (without consuming) try pb. */
  or(pb: Parser<A>): Parser<A> {
    return new Parser((ts, pos) => this._run(ts, pos) ?? pb._run(ts, pos));
  }

  /** Optional: succeed with undefined when this parser fails. */
  opt(): Parser<A | undefined> {
    return new Parser<A | undefined>(
      (ts, pos) => this._run(ts, pos) ?? { value: undefined, pos },
    );
  }

  /** Zero or more: greedily collect results until the parser fails. */
  many(): Parser<A[]> {
    return new Parser((ts, pos) => {
      const values: A[] = [];
      let cur = pos;
      while (true) {
        const r = this._run(ts, cur);
        if (!r || r.pos === cur) break; // no match or zero-width guard
        values.push(r.value);
        cur = r.pos;
      }
      return { value: values, pos: cur };
    });
  }

  /** One or more: fail if this parser doesn't match at least once. */
  many1(): Parser<A[]> {
    return this.flatMap(head => this.many().map(tail => [head, ...tail]));
  }

  /**
   * Run the parser on the given token array and return the parsed value.
   * Throws an Error with a context message on failure.
   */
  run(ts: readonly string[]): A {
    const r = this._run(ts, 0);
    if (!r) throw new Error(`Parse failed at start (first token: '${ts[0] ?? "<eof>"}')`);
    return r.value;
  }
}

// ── Primitive parsers ───────────────────────────────────────────────────────

/** Match exactly the given token string. */
export const tok = (t: string): Parser<string> =>
  new Parser((ts, pos) => ts[pos] === t ? { value: t, pos: pos + 1 } : null);

/** Match any single token satisfying the predicate. */
export const satisfy = (pred: (t: string) => boolean): Parser<string> =>
  new Parser((ts, pos) =>
    pos < ts.length && pred(ts[pos]) ? { value: ts[pos], pos: pos + 1 } : null
  );

/** Match any single token. */
export const anyTok: Parser<string> =
  new Parser((ts, pos) => pos < ts.length ? { value: ts[pos], pos: pos + 1 } : null);

/** Succeed with a constant value without consuming any input. */
export const succeed = <A>(a: A): Parser<A> =>
  new Parser((_ts, pos) => ({ value: a, pos }));

/** Always fail. */
export const fail_ = <A = never>(): Parser<A> =>
  new Parser(() => null);

/** Defer parser construction to break forward references. */
export const lazy = <A>(f: () => Parser<A>): Parser<A> =>
  new Parser((ts, pos) => f()._run(ts, pos));

/**
 * Zero-width lookahead: succeed (without consuming input) when p would match.
 * Useful for conditional branches that must not consume the trigger token.
 */
export const lookahead = <A>(p: Parser<A>): Parser<A> =>
  new Parser((ts, pos) => {
    const r = p._run(ts, pos);
    return r ? { value: r.value, pos } : null;
  });

/** Ordered choice over an array of same-typed parsers. */
export const alt = <A>(...ps: Parser<A>[]): Parser<A> =>
  new Parser((ts, pos) => {
    for (const p of ps) {
      const r = p._run(ts, pos);
      if (r) return r;
    }
    return null;
  });
