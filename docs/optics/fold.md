# Fold

A **Fold** is a read-only optic that focuses on **zero or more targets** and lets you _collect_ or
_aggregate_ them, but provides no way to set or modify them. It is the weakest optic that still lets
you observe multiple values — a strict generalisation of `Getter` (one value) and a weaker version
of `Traversal` (which also allows writes).

![fold](diagrams/fold.svg)

## Type

```text
Fold s a
-- s = the container ("source")
-- a = the type of each focused element (read-only)

toListOf :: Fold s a -> s -> [a]          -- collect all focused values
preview  :: Fold s a -> s -> Maybe a       -- first focused value, if any
lengthOf :: Fold s a -> s -> Int           -- count focused values
anyOf    :: Fold s a -> (a -> Bool) -> s -> Bool
allOf    :: Fold s a -> (a -> Bool) -> s -> Bool
sumOf    :: Num a => Fold s a -> s -> a

-- van Laarhoven encoding (Haskell):
type Fold s a = forall f. (Contravariant f, Applicative f) => (a -> f a) -> s -> f s
-- The Contravariant + Applicative constraint rules out any write capability.
-- Every Traversal is a valid Fold.
-- Every Getter is a valid Fold.
```

## Key use cases

- Reading all elements from a data structure without needing to put them back
- Aggregating values (sum, count, any, all) without modifying the structure
- Exposing an external data source (file lines, DB rows) as an optic
- Composing with other optics to project a field from every element of a collection

## Motivation

Without a Fold, extracting and aggregating values from nested structures requires writing a bespoke
traversal for each combination of container and field. There is no reusable abstraction.

```text
-- Without fold: separate function per combination
totalPrice  cart = sum (map (.price) (orders cart))
allExpensive cart = all ((> 100) . .price) (orders cart)
-- Cannot reuse the "reach into every order's price" path.
-- Every new aggregation writes its own traversal.
```

```text
-- With fold: compose once; use any aggregator
pricesF :: Fold Cart Double    -- = orders . each . price

totalPrice   = sumOf    pricesF cart
allExpensive = allOf    pricesF (> 100) cart
count        = lengthOf pricesF cart
firstPrice   = preview  pricesF cart
-- The path is a value; any fold function works with it.
```

![fold motivation](diagrams/fold-motivation.svg)

## Examples

### C\#

```csharp
using System.Collections.Generic;
using System.Linq;

// In C# without higher-kinded types, a Fold is expressed as a projection function.
// The key insight: a Fold<S,A> is just Func<S, IEnumerable<A>>.

record Order(string Item, double Price);
record Cart(IReadOnlyList<Order> Orders);

// "pricesFold": a function from Cart to IEnumerable<double>
IEnumerable<double> PricesFold(Cart cart) => cart.Orders.Select(o => o.Price);

var cart = new Cart(new[] {
    new Order("Book",  12.0),
    new Order("Pen",    2.5),
    new Order("Ruler",  3.0),
});

double total       = PricesFold(cart).Sum();                   // 17.5
bool allCheap      = PricesFold(cart).All(p => p < 20);        // true
double? firstPrice = PricesFold(cart).FirstOrDefault();        // 12.0
int count          = PricesFold(cart).Count();                 // 3
```

### F\#

```fsharp
type Order = { Item: string; Price: double }
type Cart  = { Orders: Order list }

// Fold as a function: Cart -> double seq
let pricesFold (cart: Cart) = cart.Orders |> Seq.map (fun o -> o.Price)

let cart = { Orders = [ { Item = "Book"; Price = 12.0 }
                         { Item = "Pen";  Price =  2.5 }
                         { Item = "Ruler";Price =  3.0 } ] }

let total      = pricesFold cart |> Seq.sum          // 17.5
let allCheap   = pricesFold cart |> Seq.forall (fun p -> p < 20.0)  // true
let firstPrice = pricesFold cart |> Seq.tryHead      // Some 12.0
let count      = pricesFold cart |> Seq.length       // 3

// Using FSharpPlus / Aether, a Fold is fully composable with other optics.
```

### Ruby

```ruby
Order = Struct.new(:item, :price)
Cart  = Struct.new(:orders)

# Fold as a lambda: Cart -> Enumerator of prices
prices_fold = ->(cart) { cart.orders.map(&:price) }

cart = Cart.new([Order.new('Book', 12.0), Order.new('Pen', 2.5), Order.new('Ruler', 3.0)])

total      = prices_fold.call(cart).sum              # 17.5
all_cheap  = prices_fold.call(cart).all? { |p| p < 20 }  # true
first_price = prices_fold.call(cart).first           # 12.0
count      = prices_fold.call(cart).size             # 3
```

### C++

```cpp
#include <vector>
#include <numeric>
#include <algorithm>

struct Order { std::string item; double price; };
struct Cart  { std::vector<Order> orders; };

// Fold as a function: Cart -> vector<double>
auto pricesFold = [](const Cart& cart) {
    std::vector<double> prices;
    for (const auto& o : cart.orders) prices.push_back(o.price);
    return prices;
};

Cart cart{ { {"Book", 12.0}, {"Pen", 2.5}, {"Ruler", 3.0} } };
auto prices = pricesFold(cart);

double total   = std::accumulate(prices.begin(), prices.end(), 0.0);   // 17.5
bool allCheap  = std::all_of(prices.begin(), prices.end(), [](double p){ return p < 20; });
double first   = prices.empty() ? 0.0 : prices.front();                // 12.0
int count      = static_cast<int>(prices.size());                      // 3
```

### JavaScript

```js
// Fold as a function from S to an array of A values.
const pricesFold = (cart) => cart.orders.map((o) => o.price);

const cart = {
  orders: [
    { item: "Book", price: 12.0 },
    { item: "Pen", price: 2.5 },
    { item: "Ruler", price: 3.0 },
  ],
};

const prices = pricesFold(cart); // [12.0, 2.5, 3.0]
const total = prices.reduce((a, b) => a + b, 0); // 17.5
const allCheap = prices.every((p) => p < 20); // true
const firstPrice = prices[0] ?? null; // 12.0
const count = prices.length; // 3

// With monocle-ts, a Fold composes with Lens/Traversal:
// import * as Fold from 'monocle-ts/Fold'
```

### Python

```python
from dataclasses import dataclass
from typing import List, Optional

@dataclass(frozen=True)
class Order: item: str;  price: float
@dataclass(frozen=True)
class Cart:  orders: tuple

# Fold as a generator / list function
def prices_fold(cart: Cart) -> List[float]:
    return [o.price for o in cart.orders]

cart   = Cart(orders=(Order("Book", 12.0), Order("Pen", 2.5), Order("Ruler", 3.0)))
prices = prices_fold(cart)                                     # [12.0, 2.5, 3.0]

total      = sum(prices)                                       # 17.5
all_cheap  = all(p < 20 for p in prices)                      # True
first_price: Optional[float] = prices[0] if prices else None  # 12.0
count      = len(prices)                                       # 3

# With the `lenses` package:
# from lenses import lens
# total = sum(lens(cart).orders.each().price.collect())
```

### Haskell

```hs
import Control.Lens

data Order = Order { _item :: String, _price :: Double } deriving Show
data Cart  = Cart  { _orders :: [Order] }                deriving Show

makeLenses ''Order
makeLenses ''Cart

cart :: Cart
cart = Cart [ Order "Book" 12.0, Order "Pen" 2.5, Order "Ruler" 3.0 ]

-- orders . each . price :: Traversal' Cart Double
-- A Traversal is also a valid Fold.
pricesF :: Fold Cart Double
pricesF = orders . each . price

total      :: Double
total      = sumOf    pricesF cart          -- 17.5

allCheap   :: Bool
allCheap   = allOf    pricesF (< 20) cart   -- True

firstPrice :: Maybe Double
firstPrice = preview  pricesF cart          -- Just 12.0

count      :: Int
count      = lengthOf pricesF cart          -- 3

-- Fold from a function (folding :: (s -> [a]) -> Fold s a):
linesF :: Fold String String
linesF = folding lines

wordCount :: Int
wordCount = lengthOf (linesF . folding words) "hello world\nfoo bar"
-- 4
```

### Rust

```rust
// Rust: Fold as an iterator-producing method or a function returning a Vec.
// There is no optic trait for Fold in std; the pattern is expressible with iterators.

#[derive(Debug, Clone)]
struct Order { item: String, price: f64 }
#[derive(Debug, Clone)]
struct Cart  { orders: Vec<Order> }

impl Cart {
    fn prices(&self) -> Vec<f64> {
        self.orders.iter().map(|o| o.price).collect()
    }
}

let cart = Cart { orders: vec![
    Order { item: "Book".into(),  price: 12.0 },
    Order { item: "Pen".into(),   price:  2.5 },
    Order { item: "Ruler".into(), price:  3.0 },
]};

let prices: Vec<f64> = cart.prices();
let total:  f64      = prices.iter().sum();                    // 17.5
let all_cheap: bool  = prices.iter().all(|&p| p < 20.0);      // true
let first:     Option<f64> = prices.first().copied();          // Some(12.0)
let count:     usize = prices.len();                           // 3
```

### Go

```go
import "fmt"

type Order struct{ Item string; Price float64 }
type Cart  struct{ Orders []Order }

// Fold as a function returning a slice (read-only projection)
func PricesFold(cart Cart) []float64 {
	prices := make([]float64, len(cart.Orders))
	for i, o := range cart.Orders {
		prices[i] = o.Price
	}
	return prices
}

cart := Cart{Orders: []Order{
	{"Book", 12.0}, {"Pen", 2.5}, {"Ruler", 3.0},
}}
prices := PricesFold(cart)                                     // [12 2.5 3]

var total float64
for _, p := range prices { total += p }                        // 17.5
fmt.Println(total)

allCheap := true
for _, p := range prices {
	if p >= 20 { allCheap = false; break }
}
// allCheap == true

var firstPrice *float64
if len(prices) > 0 { firstPrice = &prices[0] }                // &12.0
count := len(prices)                                           // 3
```
