<cfscript>
data = {
	"products": [
		{ "name": "apple", "price": 1.50 },
		{ "name": "banana", "price": 0.75 },
		{ "name": "cherry", "price": 3.00 }
	]
};

// Filter by condition - returns array of matching names
assert(
	actual = jsonata.evaluate("products[price > 1].name", data),
	expected = ["apple", "cherry"],
	message = "Filter products by price > 1"
);

// Filter returning single object
assert(
	actual = jsonata.evaluate("products[price < 1]", data),
	expected = { "name": "banana", "price": 0.75 },
	message = "Filter returning single matching object"
);

// Filter with equality
orders = {
	"orders": [
		{ "id": 1, "status": "shipped" },
		{ "id": 2, "status": "pending" },
		{ "id": 3, "status": "shipped" }
	]
};

assert(
	actual = jsonata.evaluate('orders[status = "shipped"].id', orders),
	expected = [1, 3],
	message = "Filter orders by status equality"
);
</cfscript>
