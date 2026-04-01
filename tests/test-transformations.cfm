<cfscript>
data = { "firstName": "John", "lastName": "Smith" };

// String concatenation
assert(
	actual = jsonata.evaluate('firstName & " " & lastName', data),
	expected = "John Smith",
	message = "String concatenation with &"
);

// Build new structure
assert(
	actual = jsonata.evaluate('{ "fullName": firstName & " " & lastName }', data),
	expected = { "fullName": "John Smith" },
	message = "Build new structure from expression"
);

// Uppercase
assert(
	actual = jsonata.evaluate("$uppercase(firstName)", data),
	expected = "JOHN",
	message = "$uppercase function"
);

// Lowercase
assert(
	actual = jsonata.evaluate("$lowercase(lastName)", data),
	expected = "smith",
	message = "$lowercase function"
);
</cfscript>
