<cfscript>
// Test: JSONata initializes successfully
assert(
	actual = isObject(jsonata),
	expected = true,
	message = "JSONata component initializes successfully"
);

// Test: Simple path expression
assert(
	actual = jsonata.evaluate("name", { "name": "John", "age": 42 }),
	expected = "John",
	message = "Simple path expression returns correct value"
);

// Test: JSON string input
assert(
	actual = jsonata.evaluate("name", '{"name":"John","age":42}'),
	expected = "John",
	message = "JSON string input works"
);

// Test: Nested path expression
assert(
	actual = jsonata.evaluate("user.profile.city", { "user": { "profile": { "city": "Atlanta" } } }),
	expected = "Atlanta",
	message = "Nested path expression returns correct value"
);

// Test: Numeric result
assert(
	actual = jsonata.evaluate("age", { "name": "John", "age": 42 }),
	expected = 42,
	message = "Numeric value returned correctly"
);
</cfscript>
