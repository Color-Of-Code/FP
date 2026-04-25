# Reader Monad

The **Reader monad** (`Environment` monad) models computations that depend on a **shared read-only
environment** — configuration, dependency injection, or any context that all steps need but none
should modify.

![reader monad](diagrams/reader.svg)

## Type

```text
Reader r a  =  r -> a
```

A reader computation is simply a **function** from an environment `r` to a result `a`. The monad
machinery threads the same `r` value implicitly through every step, removing the need to pass it as
an explicit argument everywhere.

## How bind works

```text
bind ra f  =  \r ->
    let a = ra(r)    -- run first computation with env r
    in  f(a)(r)      -- pass result to f, run with the same env r
```

The environment is **never modified** — every step sees the identical `r`.

## Primitive operations

| Operation   | Type                                | Description                                       |
| ----------- | ----------------------------------- | ------------------------------------------------- |
| `ask`       | `Reader r r`                        | retrieve the whole environment as the result      |
| `asks f`    | `(r ⟶ a) ⟶ Reader r a`              | project a single field out of the environment     |
| `local f`   | `(r ⟶ r) ⟶ Reader r a ⟶ Reader r a` | run a sub-computation with a modified environment |
| `runReader` | `Reader r a ⟶ r ⟶ a`                | supply the environment and execute                |

## Key use cases

- Application configuration (database URL, feature flags, timeout values)
- Dependency injection without a DI framework
- Compiler / interpreter passes that need a read-only symbol table
- Any function that currently takes a `Config` or `Context` as its last argument

## Motivation

Without the Reader monad, a shared environment (config, logger, database handle) must be passed as
an explicit argument to every function — even helpers that only use one field. Extending the
environment or adding a new helper means touching every signature in the call chain.

```text
-- Without Reader monad: config threaded explicitly into every helper
function build_url(config):
    return get_scheme(config) + "://"
         + get_host(config) + ":"
         + get_port(config)

function get_scheme(config): return config.scheme  -- needs all of config
function get_host(config):   return config.host    --   just for one field
function get_port(config):   return config.port    --   just for one field
-- Adding a new helper that needs config means adding a parameter everywhere.
```

```text
-- With Reader monad: environment threaded implicitly; helpers ask only for what they need
build_url = do
    scheme <- asks .scheme
    host   <- asks .host
    port   <- asks .port
    pure (scheme + "://" + host + ":" + port)
-- No config parameter in sight; runReader supplies it once at the top.
```

![reader motivation](diagrams/reader-motivation.svg)

## Examples

### C\#

```csharp
// Reader as a plain function — C# has no built-in Reader monad
// but the pattern is just: Func<TEnv, TResult>
record Config(string Host, int Port);

Func<Config, string> getHost = cfg => cfg.Host;
Func<Config, int>    getPort = cfg => cfg.Port;
Func<Config, string> buildUrl = cfg =>
    $"http://{getHost(cfg)}:{getPort(cfg)}";

var url = buildUrl(new Config("example.com", 8080));
// "http://example.com:8080"
```

### F\#

F# functions are already curried, so the Reader pattern is just passing a record as the last
argument and using partial application. No special type is needed.

```fsharp
type Config = { Host: string; Port: int }

let getHost (cfg: Config) = cfg.Host
let getPort (cfg: Config) = cfg.Port

let buildUrl cfg =
    $"http://{getHost cfg}:{getPort cfg}"

let url = buildUrl { Host = "example.com"; Port = 8080 }
// "http://example.com:8080"

// With an explicit Reader CE (e.g. from FSharpPlus):
// let buildUrl = reader {
//     let! h = asks (fun cfg -> cfg.Host)
//     let! p = asks (fun cfg -> cfg.Port)
//     return $"http://{h}:{p}"
// }
```

### Ruby

```ruby
# Reader as a plain lambda taking a config hash
asks       = ->(f)       { ->(env) { f.call(env) } }
run_reader = ->(ra, env) { ra.call(env) }

get_host = asks[->(cfg) { cfg[:host] }]
get_port = asks[->(cfg) { cfg[:port] }]
build_url = ->(env) { "http://#{get_host.call(env)}:#{get_port.call(env)}" }

run_reader.call(build_url, { host: "example.com", port: 8080 })
# "http://example.com:8080"
```

### C++

```cpp
#include <string>

struct Config { std::string host; int port; };

// Reader r a = just a function taking Config
auto get_host = [](const Config& cfg) { return cfg.host; };
auto get_port = [](const Config& cfg) { return cfg.port; };
auto build_url = [](const Config& cfg) {
    return "http://" + cfg.host + ":" + std::to_string(cfg.port);
};

Config env{"example.com", 8080};
auto url = build_url(env);
// "http://example.com:8080"
```

### JavaScript

```js
// Reader as a plain function
const ask = (r) => r;
const asks = (f) => (r) => f(r);
const bind = (ra, f) => (r) => f(ra(r))(r);
const runReader = (ra, env) => ra(env);

const getHost = asks((cfg) => cfg.host);
const getPort = asks((cfg) => cfg.port);
const buildUrl = bind(getHost, (host) => bind(getPort, (port) => (_) => `http://${host}:${port}`));

runReader(buildUrl, { host: "example.com", port: 8080 });
// "http://example.com:8080"
```

### Python

```py
# Reader as a plain function (manual threading)
def asks(f):
    return lambda env: f(env)

def bind(ra, f):
    return lambda env: f(ra(env))(env)

def run_reader(ra, env):
    return ra(env)

get_host = asks(lambda cfg: cfg["host"])
get_port = asks(lambda cfg: cfg["port"])
build_url = bind(get_host, lambda host:
              bind(get_port, lambda port:
                lambda _: f"http://{host}:{port}"))

run_reader(build_url, {"host": "example.com", "port": 8080})
# "http://example.com:8080"
```

### Haskell

```hs
import Control.Monad.Reader

data Config = Config { host :: String, port :: Int }

buildUrl :: Reader Config String
buildUrl = do
    h <- asks host   -- project host field
    p <- asks port   -- project port field
    return ("http://" ++ h ++ ":" ++ show p)

result :: String
result = runReader buildUrl (Config "example.com" 8080)
-- "http://example.com:8080"

-- local: run with a modified environment
resultDev :: String
resultDev = runReader (local (\cfg -> cfg { host = "localhost" }) buildUrl)
                      (Config "example.com" 8080)
-- "http://localhost:8080"
```

### Rust

```rust
// Rust: the Reader pattern is expressed by passing a shared config reference.
// No monad machinery is needed; closures capture what they need.

#[derive(Clone)]
struct Config {
    host: String,
    port: u16,
}

// Pure functions that depend on config take a &Config parameter.
fn build_url(cfg: &Config) -> String {
    format!("http://{}:{}", cfg.host, cfg.port)
}

fn build_api_url(cfg: &Config, path: &str) -> String {
    format!("{}/{}", build_url(cfg), path)
}

let cfg = Config { host: "example.com".to_string(), port: 8080 };
println!("{}", build_url(&cfg));              // http://example.com:8080
println!("{}", build_api_url(&cfg, "users")); // http://example.com:8080/users

// "local": run with a modified config
let dev_cfg = Config { host: "localhost".to_string(), ..cfg.clone() };
println!("{}", build_url(&dev_cfg)); // http://localhost:8080
```

### Go

```go
import "fmt"

// Go: the Reader pattern is expressed by passing a Config struct to functions.

type Config struct {
	Host string
	Port int
}

func buildURL(cfg Config) string {
	return fmt.Sprintf("http://%s:%d", cfg.Host, cfg.Port)
}

func buildAPIURL(cfg Config, path string) string {
	return buildURL(cfg) + "/" + path
}

cfg := Config{Host: "example.com", Port: 8080}
fmt.Println(buildURL(cfg))                   // http://example.com:8080
fmt.Println(buildAPIURL(cfg, "users"))        // http://example.com:8080/users

// "local": run with a modified config
devCfg := cfg
devCfg.Host = "localhost"
fmt.Println(buildURL(devCfg)) // http://localhost:8080
```
