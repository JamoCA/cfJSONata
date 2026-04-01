<cfscript>
data = {
	"orders": [
		{ "product": "A", "quantity": 2, "price": 10 },
		{ "product": "B", "quantity": 1, "price": 25 },
		{ "product": "A", "quantity": 3, "price": 10 }
	]
};

// Sum of calculated values
assert(
	actual = jsonata.evaluate("$sum(orders.(quantity * price))", data),
	expected = 75,
	message = "Sum of calculated order totals"
);

// Count with filter
assert(
	actual = jsonata.evaluate('$count(orders[product = "A"])', data),
	expected = 2,
	message = "Count filtered results"
);
</cfscript>
