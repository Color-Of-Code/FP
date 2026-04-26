# Lambda Calculus

The **lambda calculus** (λ-calculus) is a formal system for expressing computation through function
abstraction and application; it is the mathematical foundation of every functional programming
language.

## Definition

The untyped λ-calculus has exactly three syntactic forms:

$$
e \;::=\; x \mid \lambda x.\, e \mid e_1\; e_2
$$

- **Variable** $x$ — a name standing for a value
- **Abstraction** $\lambda x.\, e$ — a function with parameter $x$ and body $e$
- **Application** $e_1\; e_2$ — apply function $e_1$ to argument $e_2$

Application is left-associative: $f\,g\,h = (f\,g)\,h$.  
Abstraction extends as far right as possible:
$\lambda x.\,\lambda y.\,e = \lambda x.(\lambda y.\,e)$.

### Free and bound variables

$x$ is **bound** in $\lambda x.\,e$; occurrences of $x$ inside $e$ are captured by the
abstraction.  
A variable not under any enclosing $\lambda$ for it is **free**.  
$\alpha$-equivalence: $\lambda x.\,e \equiv_\alpha \lambda y.\,e[y/x]$ — renaming bound variables
does not change meaning.

### β-reduction

The core computation rule — substitute the argument for the parameter:

$$(\lambda x.\, e_1)\; e_2 \;\longrightarrow_\beta\; e_1[e_2 / x]$$

A term with no β-redex is in **β-normal form**.

### η-equivalence

If $x \notin \mathrm{FV}(f)$ then $\lambda x.\, f\,x \equiv_\eta f$.  
η-equivalence captures the idea that a function is determined entirely by its behaviour on inputs.

## Laws

### Church-Rosser theorem (confluence)

If $e \twoheadrightarrow_\beta e_1$ and $e \twoheadrightarrow_\beta e_2$ then there exists $e_3$
such that $e_1 \twoheadrightarrow_\beta e_3$ and $e_2 \twoheadrightarrow_\beta e_3$.

**Consequence**: if a term has a normal form, that normal form is unique (up to α-equivalence).
Reduction order does not affect the _result_, only whether it terminates.

### Evaluation strategies

| Strategy              | When to reduce                    | FP examples            |
| --------------------- | --------------------------------- | ---------------------- |
| **Normal order**      | Outermost redex first             | Haskell (lazy)         |
| **Applicative order** | Innermost redex first             | OCaml, Racket (strict) |
| **Call-by-name**      | Substitute without evaluating arg | Haskell thunks         |
| **Call-by-value**     | Evaluate arg before substituting  | Most languages         |
| **Call-by-need**      | Call-by-name + memoise            | Haskell default        |

Normal order is complete (finds a normal form if one exists); applicative order may diverge even
when a normal form exists (e.g. `(λx.y)((λx.xx)(λx.xx))` — the argument diverges but is never
needed).

### Fixed-point combinators

The **Y combinator** is the canonical fixed-point combinator:

$$Y \;=\; \lambda f.\,(\lambda x.\,f\,(x\,x))\,(\lambda x.\,f\,(x\,x))$$

It satisfies $Y\,f =_\beta f\,(Y\,f)$, encoding recursion without a name-binding mechanism.  
For call-by-value (applicative order) evaluation use the **Z combinator** (also called the
call-by-value Y):

$$Z \;=\; \lambda f.\,(\lambda x.\,f\,(\lambda v.\,x\,x\,v))\,(\lambda x.\,f\,(\lambda v.\,x\,x\,v))$$

### Church numerals

Natural numbers encoded as higher-order functions ($n$ applies its first argument $n$ times):

$$
\begin{aligned}
\mathbf{0} &= \lambda f.\,\lambda x.\,x \\
\mathbf{1} &= \lambda f.\,\lambda x.\,f\,x \\
\mathbf{n} &= \lambda f.\,\lambda x.\,\underbrace{f\,(f\,(\cdots(f}_{n}\,x)\cdots)) \\
\mathrm{succ} &= \lambda n.\,\lambda f.\,\lambda x.\,f\,(n\,f\,x) \\
\mathrm{add} &= \lambda m.\,\lambda n.\,\lambda f.\,\lambda x.\,m\,f\,(n\,f\,x) \\
\mathrm{mul} &= \lambda m.\,\lambda n.\,\lambda f.\,m\,(n\,f)
\end{aligned}
$$

### SKI combinators

Every λ-term (with no free variables) can be translated into a **combinatorially complete** basis of
three constants, with no variable binding:

$$
S \;=\; \lambda x.\,\lambda y.\,\lambda z.\,(x\,z)\,(y\,z)
\qquad
K \;=\; \lambda x.\,\lambda y.\,x
\qquad
I \;=\; \lambda x.\,x
$$

Note $I = S\,K\,K$. The SK basis alone is Turing-complete. Combinatory logic is the formal
underpinning of **point-free** (tacit) style in FP.

### Church-Turing thesis

The class of functions computable by the λ-calculus equals the class computable by a Turing machine,
and both equal the class of **general recursive (μ-recursive) functions**. This is an empirical
thesis — no counterexample has been found, and every proposed model of computation turns out to be
equivalent.

## FP Analog

| λ-calculus concept          | FP language construct                                 |
| --------------------------- | ----------------------------------------------------- |
| $\lambda x.\, e$            | Anonymous function / lambda literal                   |
| Application $f\,a$          | Function call `f(a)` or `f a`                         |
| β-reduction                 | Evaluation of a call (substitution step)              |
| η-equivalence               | Point-free definition: `f = g` when `f x = g x`       |
| Church numeral $\mathbf{n}$ | An `n`-fold `fmap` / iterator                         |
| Y combinator                | `fix :: (a -> a) -> a` in Haskell; `letrec` in Scheme |
| Z combinator                | Anonymous recursion in strict languages               |
| SKI translation             | Point-free combinators (`(.)`, `const`, `id`)         |
| Normal order                | Lazy evaluation (call-by-need)                        |
| Applicative order           | Strict evaluation (call-by-value)                     |
| Simply typed λ-calculus     | Hindley-Milner type inference                         |
| System F (polymorphic λ)    | `forall`-quantified types; `Rank2Types` in Haskell    |

Every functional language is — at some level — a typed variant of the λ-calculus with syntactic
sugar. Haskell's core language (GHC Core / System FC) is a typed λ-calculus.

→ FP track: [31. Computation Models and λ-Calculus](../docs/31-computation-models.md) |
[1. Function](../docs/01-function.md) |
[3. Equational Reasoning](../docs/03-equational-reasoning.md) |
[4. Composition](../docs/04-composition.md)

## CTFP Reference

| Resource                        | Link                                                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Types and Functions | [Part 1 Ch 2](https://bartoszmilewski.com/2014/11/24/types-and-functions/)                     |
| CTFP blog — Function Types      | [Part 1 Ch 9](https://bartoszmilewski.com/2015/03/13/function-types/)                          |
| CTFP LaTeX source Ch 1.2        | [`src/content/1.2/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.2) |
| CTFP LaTeX source Ch 1.9        | [`src/content/1.9/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.9) |

## See Also

- [Category](./category.md) — the category **Hask** where types are objects and λ-abstractions are
  morphisms
- [Types & Functions](./types-functions.md) — the FP interpretation of the typed λ-calculus
- [Adjunction](./adjunction.md) — currying ($A \times B \to C \;\cong\; A \to (B \to C)$) is the
  canonical adjunction; it _is_ the λ-calculus abstraction/application duality
- [F-Algebra](./f-algebra.md) — the fixed-point interpretation of the Y combinator;
  $Y f = \mu
  (\lambda x. f\,x)$
