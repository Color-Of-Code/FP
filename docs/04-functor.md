# 4. Functor

A **functor** `F` is a type constructor that wraps values and supports **`fmap`**, which lifts a
plain function `f :: a ⟶ b` to work inside the wrapper: `fmap f :: Fa ⟶ Fb`.

![functor](../basics/functor.svg)

This means you can reuse any ordinary function over any functor without rewriting it — the functor
handles the "opening and closing" of the wrapper.

## Laws

A lawful functor must satisfy:

- **Identity**: `fmap id = id`
- **Composition**: `fmap (g∘f) = fmap g ∘ fmap f`

## Common functors

| Functor       | What `fmap f` does                                              |
| ------------- | --------------------------------------------------------------- |
| `List<a>`     | applies `f` to every element                                    |
| `Maybe<a>`    | applies `f` if `Just a`, passes `Nothing` through               |
| `(a, String)` | applies `f` to the first element, leaves the `String` unchanged |

## Examples

### C\#

```csharp
// List functor — Select is fmap
new[] { 1, 2, 3 }.Select(x => x * 2); // [2, 4, 6]

// Maybe functor — nullable
int? value = 5;
int? result = value.HasValue ? value * 2 : null; // 10
```

### Ruby

```ruby
# List functor
[1, 2, 3].map { |x| x * 2 }  # [2, 4, 6]
```

### JavaScript

```js
// List functor
[1, 2, 3].map((x) => x * 2); // [2, 4, 6]
```

### Python

```py
# List functor
list(map(lambda x: x * 2, [1, 2, 3]))  # [2, 4, 6]
```

### Haskell

```hs
-- List functor
fmap (*2) [1, 2, 3]        -- [2, 4, 6]

-- Maybe functor
fmap (*2) (Just 5)         -- Just 10
fmap (*2) Nothing          -- Nothing
```
