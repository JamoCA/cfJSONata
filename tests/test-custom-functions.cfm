<cfscript>
// Single-arg custom function
assert(
	actual = jsonata.evaluate(
		"$double(value)",
		{ "value": 21 },
		{},
		{
			"functions": {
				"double": function(val) { return val * 2; }
			}
		}
	),
	expected = 42,
	message = "Single-arg custom function"
);

// Multi-arg custom function
assert(
	actual = jsonata.evaluate(
		"$mymod(a, b)",
		{ "a": 10, "b": 3 },
		{},
		{
			"functions": {
				"mymod": function(a, b) { return a % b; }
			}
		}
	),
	expected = 1,
	message = "Multi-arg custom function"
);

// Custom function returning struct
assert(
	actual = jsonata.evaluate(
		"$makeuser(name, age)",
		{ "name": "John", "age": 42 },
		{},
		{
			"functions": {
				"makeuser": function(n, a) { return { "username": n, "years": a }; }
			}
		}
	),
	expected = { "username": "John", "years": 42 },
	message = "Custom function returning struct"
);

// Custom function combined with bindings
assert(
	actual = jsonata.evaluate(
		"$calc(value) + $offset",
		{ "value": 100 },
		{ "offset": 5 },
		{
			"functions": {
				"calc": function(v) { return v * 2; }
			}
		}
	),
	expected = 205,
	message = "Custom function combined with variable binding"
);

// Custom function with timeout option
assert(
	actual = jsonata.evaluate(
		"$double(value)",
		{ "value": 10 },
		{},
		{
			"timeout": 5000,
			"functions": {
				"double": function(val) { return val * 2; }
			}
		}
	),
	expected = 20,
	message = "Custom function with timeout option"
);
</cfscript>
