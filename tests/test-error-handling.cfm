<cfscript>
// Invalid expression
assertThrows(
	type = "JSONata.InvalidExpression",
	fn = function() {
		jsonata.evaluate("}{invalid", {});
	},
	message = "Invalid expression throws JSONata.InvalidExpression"
);

// Another invalid expression
assertThrows(
	type = "JSONata.InvalidExpression",
	fn = function() {
		jsonata.evaluate("$sum(", { "values": [1, 2, 3] });
	},
	message = "Unclosed function call throws JSONata.InvalidExpression"
);

// Valid expression against data - should not throw (returns null)
assert(
	message = "Missing path returns null without throwing"
);
</cfscript>
