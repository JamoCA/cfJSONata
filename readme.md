# JSONata for ColdFusion

A CFML wrapper for the [jsonata-java](https://github.com/dashjoin/jsonata-java) library that brings [JSONata](https://jsonata.org) expression evaluation to Adobe ColdFusion 2016+ and Lucee 5-7... no platform-specific extensions required.

JSONata is a lightweight query and transformation language for JSON data, similar to XPath/XQuery but designed specifically for JSON.

## Tested On

- Adobe ColdFusion 2016, 2021, 2023, 2025
- Lucee 5, 6, 7

## Requirements

- Java 11 or later
- Adobe ColdFusion 2016+ or Lucee 5+
- jsonata-java JAR file (v0.9.9 or later)
- jsonata-cfml-bridge JAR (included, required for custom function support)

## Getting the JARs

Download the jsonata-java JAR from Maven Central:

**https://mvnrepository.com/artifact/com.dashjoin/jsonata**

Select the version you want (e.g., 0.9.9), then click the "jar" link under "Files" to download.

The `jsonata-cfml-bridge.jar` is included in this project's `JARs/` folder. It provides the bridge between CFML closures and the Java library's custom function interface.

Place the JARs either:
- On your ColdFusion server's classpath (restart required), OR
- In a directory of your choice and pass the paths via `init(jarPaths)`

## Quick Start

```cfml
// Load with explicit JAR paths (recommended)
jsonata = new JSONata(jarPaths = [
	"/path/to/jsonata-0.9.9.jar",
	"/path/to/jsonata-cfml-bridge.jar"
]);

// Or auto-detect from JARs/ folder alongside the CFC
jsonata = new JSONata();

// Evaluate an expression
result = jsonata.evaluate("name", { "name": "John", "age": 42 });
// result: "John"
```

## Important: Struct Key Case Sensitivity

JSONata expressions are case-sensitive. CFML structs uppercase their keys by default, which means `{ name: "John" }` stores the key as `NAME` - and `jsonata.evaluate("name", data)` won't find it.

**Always quote your struct keys** to preserve case:

```cfml
// WRONG - keys become uppercase, JSONata can't find them
data = { name: "John", age: 42 };

// RIGHT - keys preserve their case
data = { "name": "John", "age": 42 };
```

This applies to data, bindings, and options structs.

## API Reference

### Constructor

```cfml
jsonata = new JSONata([jarPaths])
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `jarPaths` | string or array | no | A single JAR path (string) or array of JAR paths. Must include both `jsonata-*.jar` and `jsonata-cfml-bridge.jar` for custom function support. If omitted, tries the classpath first, then falls back to JavaLoader with the default `JARs/` folder. |

### evaluate()

```cfml
result = jsonata.evaluate(expression, data [, bindings [, options]])
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `expression` | string | yes | JSONata query/transform expression |
| `data` | any | yes | CFML struct/array or JSON string |
| `bindings` | struct | no | Variables accessible as `$varName` in expressions |
| `options` | struct | no | `timeout` (ms), `maxDepth` (int), `functions` (struct of closures) |

## Examples

### Basic Queries

```cfml
data = { "user": { "profile": { "city": "Atlanta" } } };

jsonata.evaluate("user.profile.city", data);
// "Atlanta"
```

### JSON String Input

You can pass a JSON string directly as the `data` argument instead of a CFML struct or array. The JSON string is parsed by the Java library's own parser, which is faster than converting CFML data types to Java and automatically preserves key case (no need to worry about CFML uppercasing struct keys).

```cfml
// Pass JSON string directly - no struct key quoting needed
jsonata.evaluate("name", '{"name":"John","age":42}');
// "John"

// Works with nested structures
jsonata.evaluate("user.profile.city", '{"user":{"profile":{"city":"Atlanta"}}}');
// "Atlanta"

// Works with arrays
jsonata.evaluate("$sum($)", '[1,2,3,4,5]');
// 15

// Filtering on JSON string input
jsonata.evaluate("products[price > 1].name",
    '{"products":[{"name":"apple","price":1.50},{"name":"banana","price":0.75}]}');
// ["apple"]

// Combine with bindings
jsonata.evaluate("value * $multiplier", '{"value":10}', { "multiplier": 5 });
// 50
```

**Tip:** When your data comes from an API response, file read, or `serializeJSON()` output, pass the JSON string directly to `evaluate()` rather than deserializing it first. This avoids CFML's key uppercasing issue entirely and skips the overhead of CFML-to-Java type conversion.

### Aggregations

```cfml
data = { "values": [1, 2, 3, 4, 5] };

jsonata.evaluate("$sum(values)", data);      // 15
jsonata.evaluate("$average(values)", data);  // 3
jsonata.evaluate("$count(values)", data);    // 5
```

### Filtering

```cfml
data = {
	"products": [
		{ "name": "apple", "price": 1.50 },
		{ "name": "banana", "price": 0.75 },
		{ "name": "cherry", "price": 3.00 }
	]
};

jsonata.evaluate("products[price > 1].name", data);
// ["apple", "cherry"]
```

### Transformations

```cfml
data = { "firstName": "John", "lastName": "Smith" };

jsonata.evaluate('firstName & " " & lastName', data);
// "John Smith"

jsonata.evaluate("$uppercase(firstName)", data);
// "JOHN"
```

### Variable Bindings

```cfml
data = { "name": "World" };
jsonata.evaluate("$greeting & ' ' & name", data, { "greeting": "Hello" });
// "Hello World"

data = { "value": 10 };
jsonata.evaluate("value * $multiplier + $offset", data, { "multiplier": 5, "offset": 3 });
// 53
```

### Timeout and Safety Options

```cfml
jsonata.evaluate(expression, data, {}, { "timeout": 5000, "maxDepth": 50 });
```

| Option | Default | Description |
|--------|---------|-------------|
| `timeout` | 5000ms | Maximum evaluation time in milliseconds |
| `maxDepth` | 100 | Maximum recursion depth |

### Custom Functions

Register CFML closures as custom JSONata functions:

```cfml
jsonata.evaluate(
	"$double(value)",
	{ "value": 21 },
	{},
	{
		"functions": {
			"double": function(val) { return val * 2; }
		}
	}
);
// 42

// Multi-arg function
jsonata.evaluate(
	"$makeuser(name, age)",
	{ "name": "John", "age": 42 },
	{},
	{
		"functions": {
			"makeuser": function(n, a) { return { "username": n, "years": a }; }
		}
	}
);
// { username: "John", years: 42 }

// Combined with bindings and timeout
jsonata.evaluate(
	"$calc(value) + $offset",
	{ "value": 100 },
	{ "offset": 5 },
	{
		"timeout": 5000,
		"functions": {
			"calc": function(v) { return v * 2; }
		}
	}
);
// 205
```

**Note:** Custom functions require the `jsonata-cfml-bridge.jar` to be loaded alongside the main jsonata JAR.

## JAR Loading Behavior

The component uses this priority chain to find the Java libraries:

1. **Explicit paths** - If `jarPaths` is passed to `init()`, uses JavaLoader to load those specific JARs
2. **Native classpath** - If no paths given, tries `createObject("java", ...)` (works if JARs are on the CF classpath)
3. **JavaLoader fallback** - If native fails and `*.jar` files exist in the `JARs/` folder alongside the CFC, loads them via the bundled JavaLoader
4. **Error** - If none of the above work, throws `JSONata.Initialization` with download instructions

## Error Handling

The component wraps known Java exceptions as typed CFML exceptions:

| Exception Type | Scenario |
|----------------|----------|
| `JSONata.Initialization` | JAR could not be loaded |
| `JSONata.InvalidExpression` | Malformed JSONata expression |
| `JSONata.Timeout` | Expression exceeded timeout |
| `JSONata.RecursionLimit` | Expression exceeded max recursion depth |

Unknown exceptions from the Java library bubble up as-is.

```cfml
try {
	result = jsonata.evaluate("}{invalid", data);
} catch (JSONata.InvalidExpression e) {
	writeOutput("Bad expression: " & e.message);
}
```

## Running the Tests

Open `tests/runner.cfm` in your browser through your ColdFusion server. The test runner discovers and executes all test files, displaying a color-coded pass/fail report.

## Links

- [JSONata expression syntax](https://docs.jsonata.org)
- [jsonata-java library](https://github.com/dashjoin/jsonata-java)
- [Lucee JSONata Extension](https://github.com/lucee/extension-jsonata)
- [Download JAR from Maven Central](https://mvnrepository.com/artifact/com.dashjoin/jsonata)

## Changelog

### 2026-04-02
- Added documentation and tests for JSON string input support — pass a JSON string directly as the `data` argument to bypass CFML-to-Java type conversion and avoid struct key case sensitivity issues

### 2026-04-01
- Initial release
- JSONata expression evaluation via jsonata-java library wrapper
- Support for Adobe ColdFusion 2016, 2021, 2023, 2025 and Lucee 5, 6, 7
- Variable bindings (`$varName` in expressions)
- Custom CFML function registration via compiled Java bridge
- Timeout and recursion depth limits
- Flexible JAR loading (classpath, explicit paths, JavaLoader fallback)
- Typed exception handling (`JSONata.InvalidExpression`, `JSONata.Timeout`, `JSONata.RecursionLimit`)

## License

MIT - see [LICENSE](LICENSE) for details.
