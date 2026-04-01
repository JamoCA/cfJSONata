<cfscript>
// Simple variable binding
assert(
	actual = jsonata.evaluate("$greeting & ' ' & name", { "name": "World" }, { "greeting": "Hello" }),
	expected = "Hello World",
	message = "Simple variable binding"
);

// Multiple variables
assert(
	actual = jsonata.evaluate("value * $multiplier + $offset", { "value": 10 }, { "multiplier": 5, "offset": 3 }),
	expected = 53,
	message = "Multiple variable bindings"
);

// Array as variable
assert(
	actual = jsonata.evaluate("$sum($values) * multiplier", { "multiplier": 2 }, { "values": [1, 2, 3] }),
	expected = 12,
	message = "Array variable binding"
);

// Struct as variable
assert(
	actual = jsonata.evaluate('$config.prefix & $string($sum(items))', { "items": [1, 2, 3] }, { "config": { "prefix": "Total: " } }),
	expected = "Total: 6",
	message = "Struct variable binding"
);
</cfscript>
