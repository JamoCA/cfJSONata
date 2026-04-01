<cfscript>
data = { "values": [1, 2, 3, 4, 5] };

assert(
	actual = jsonata.evaluate("$sum(values)", data),
	expected = 15,
	message = "$sum aggregation"
);

assert(
	actual = jsonata.evaluate("$average(values)", data),
	expected = 3,
	message = "$average aggregation"
);

assert(
	actual = jsonata.evaluate("$count(values)", data),
	expected = 5,
	message = "$count aggregation"
);

assert(
	actual = jsonata.evaluate("$min(values)", data),
	expected = 1,
	message = "$min aggregation"
);

assert(
	actual = jsonata.evaluate("$max(values)", data),
	expected = 5,
	message = "$max aggregation"
);
</cfscript>
