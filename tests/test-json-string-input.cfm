<cfscript>
// Test: Simple path from JSON string
assert(
	actual = jsonata.evaluate("name", '{"name":"John","age":42}'),
	expected = "John",
	message = "Simple path from JSON string"
);

// Test: Nested path from JSON string
assert(
	actual = jsonata.evaluate("user.profile.city", '{"user":{"profile":{"city":"Atlanta"}}}'),
	expected = "Atlanta",
	message = "Nested path from JSON string"
);

// Test: Array aggregation from JSON string
assert(
	actual = jsonata.evaluate("$sum(values)", '{"values":[1,2,3,4,5]}'),
	expected = 15,
	message = "Aggregation from JSON string"
);

// Test: Filtering from JSON string
assert(
	actual = jsonata.evaluate("products[price > 1].name", '{"products":[{"name":"apple","price":1.50},{"name":"banana","price":0.75},{"name":"cherry","price":3.00}]}'),
	expected = ["apple","cherry"],
	message = "Filtering from JSON string"
);

// Test: Transformation from JSON string
assert(
	actual = jsonata.evaluate('firstName & " " & lastName', '{"firstName":"John","lastName":"Smith"}'),
	expected = "John Smith",
	message = "Transformation from JSON string"
);

// Test: JSON string with bindings
assert(
	actual = jsonata.evaluate("value * $multiplier", '{"value":10}', { "multiplier": 5 }),
	expected = 50,
	message = "JSON string input with bindings"
);

// Test: JSON array as top-level input
assert(
	actual = jsonata.evaluate("$sum($)", '[1,2,3,4,5]'),
	expected = 15,
	message = "JSON array string as top-level input"
);

// Test: Complex nested JSON string
complexJson = '{
	"store": {
		"name": "TechMart",
		"departments": [
			{"name": "Electronics", "items": 150},
			{"name": "Books", "items": 500},
			{"name": "Clothing", "items": 300}
		]
	}
}';
assert(
	actual = jsonata.evaluate("store.departments[items > 200].name", complexJson),
	expected = ["Books", "Clothing"],
	message = "Complex nested JSON string query"
);

assert(
	actual = jsonata.evaluate("$sum(store.departments.items)", complexJson),
	expected = 950,
	message = "Aggregation on complex JSON string"
);

// Test: JSON string preserves case (no CFML uppercasing)
assert(
	actual = jsonata.evaluate("camelCase", '{"camelCase":"works","CamelCase":"also works"}'),
	expected = "works",
	message = "JSON string preserves case-sensitive keys"
);
</cfscript>
