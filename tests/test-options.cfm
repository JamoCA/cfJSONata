<cfscript>
// Normal evaluation with timeout set (should succeed)
assert(
	actual = jsonata.evaluate("$sum(values)", { "values": [1, 2, 3] }, {}, { "timeout": 5000 }),
	expected = 6,
	message = "Evaluation with timeout option succeeds for fast expression"
);

// Normal evaluation with maxDepth set (should succeed)
assert(
	actual = jsonata.evaluate("name", { "name": "test" }, {}, { "maxDepth": 50 }),
	expected = "test",
	message = "Evaluation with maxDepth option succeeds for simple expression"
);

// Timeout exception - use a very short timeout with an expensive expression
assertThrows(
	type = "JSONata.Timeout",
	fn = function() {
		jsonata.evaluate(
			"($f := function($n){$n > 0 ? $f($n-1) + $n : 0}; $f(10000))",
			{},
			{},
			{ "timeout": 1, "maxDepth": 100000 }
		);
	},
	message = "Timeout exception thrown for long-running expression"
);

// MaxDepth exception
assertThrows(
	type = "JSONata.RecursionLimit",
	fn = function() {
		jsonata.evaluate(
			"($f := function($n){$n > 0 ? $f($n-1) + $n : 0}; $f(200))",
			{},
			{},
			{ "maxDepth": 5 }
		);
	},
	message = "RecursionLimit exception thrown for deep recursion"
);
</cfscript>
