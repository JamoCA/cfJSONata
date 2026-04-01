<cfscript>
// ============================================================
// JSONata Test Runner
// ============================================================

// Instantiate JSONata component
// JARs are loaded via Application.cfc javaSettings, so no jarPaths needed
jsonata = new jsonata.JSONata();

serverData = [
	"productName": (isdefined("server.coldfusion.productname")) ? server.coldfusion.productname : ""
	,"productVersion": (isdefined("server.coldfusion.productVersion")) ? server.coldfusion.productVersion : ""
	,"commandBox": (isdefined("server.system.environment.COMMANDBOX_VERSION")) ? server.system.environment.COMMANDBOX_VERSION : ""
	,"computerName": (isdefined("server.system.environment.COMPUTERNAME")) ? server.system.environment.COMPUTERNAME : ""
	,"applicationName": (isdefined("application.applicationName")) ? application.applicationName : ""
];

// Track results
results = {
	files: [],
	totalPassed: 0,
	totalFailed: 0,
	totalErrors: 0
};

// Simple assertion function - all test files use this
function assert(any actual, any expected, required string message) {
	try {
		// Handle null comparisons
		if (isNull(arguments.actual) && isNull(arguments.expected)) {
			arrayAppend(currentFile.tests, { message: arguments.message, status: "PASS" });
			currentFile.passed++;
			return;
		}
		if (isNull(arguments.actual) || isNull(arguments.expected)) {
			arrayAppend(currentFile.tests, {
				message: arguments.message,
				status: "FAIL",
				detail: "Expected: " & (isNull(arguments.expected) ? "null" : serializeJSON(arguments.expected)) & " | Actual: " & (isNull(arguments.actual) ? "null" : serializeJSON(arguments.actual))
			});
			currentFile.failed++;
			return;
		}
		if (isSimpleValue(arguments.actual) && isSimpleValue(arguments.expected)) {
			if (toString(arguments.actual) eq toString(arguments.expected)) {
				arrayAppend(currentFile.tests, { message: arguments.message, status: "PASS" });
				currentFile.passed++;
				return;
			}
		} else if (isStruct(arguments.actual) && isStruct(arguments.expected)) {
			if (serializeJSON(arguments.actual) eq serializeJSON(arguments.expected)) {
				arrayAppend(currentFile.tests, { message: arguments.message, status: "PASS" });
				currentFile.passed++;
				return;
			}
		} else if (isArray(arguments.actual) && isArray(arguments.expected)) {
			if (serializeJSON(arguments.actual) eq serializeJSON(arguments.expected)) {
				arrayAppend(currentFile.tests, { message: arguments.message, status: "PASS" });
				currentFile.passed++;
				return;
			}
		}
		arrayAppend(currentFile.tests, {
			message: arguments.message,
			status: "FAIL",
			detail: "Expected: " & serializeJSON(arguments.expected) & " | Actual: " & serializeJSON(arguments.actual)
		});
		currentFile.failed++;
	} catch (any e) {
		arrayAppend(currentFile.tests, {
			message: arguments.message,
			status: "ERROR",
			detail: e.message
		});
		currentFile.errors++;
	}
}

// Assertion for expected exceptions
function assertThrows(required string type, required function fn, required string message) {
	try {
		arguments.fn();
		arrayAppend(currentFile.tests, {
			message: arguments.message,
			status: "FAIL",
			detail: "Expected exception of type [#arguments.type#] but none was thrown"
		});
		currentFile.failed++;
	} catch (any e) {
		if (findNoCase(arguments.type, e.type)) {
			arrayAppend(currentFile.tests, { message: arguments.message, status: "PASS" });
			currentFile.passed++;
		} else {
			arrayAppend(currentFile.tests, {
				message: arguments.message,
				status: "FAIL",
				detail: "Expected exception type [#arguments.type#] but got [#e.type#]: #e.message#"
			});
			currentFile.failed++;
		}
	}
}

// Discover test files
testDir = getDirectoryFromPath(getCurrentTemplatePath());
testFiles = directoryList(testDir, false, "name", "test-*.cfm");
arraySort(testFiles, "text");

// Run each test file
for (testFile in testFiles) {
	currentFile = {
		name: testFile,
		tests: [],
		passed: 0,
		failed: 0,
		errors: 0
	};
	try {
		include testFile;
	} catch (any e) {
		arrayAppend(currentFile.tests, {
			message: "File-level error",
			status: "ERROR",
			detail: e.message & " " & e.detail
		});
		currentFile.errors++;
	}
	results.totalPassed += currentFile.passed;
	results.totalFailed += currentFile.failed;
	results.totalErrors += currentFile.errors;
	arrayAppend(results.files, currentFile);
}
</cfscript>

<!--- HTML Report --->
<!DOCTYPE html>
<html>
<head>
	<title>JSONata Test Results</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; }
		.summary { font-size: 18px; margin-bottom: 20px; padding: 10px; border-radius: 4px; }
		.summary.pass { background: #d4edda; color: #155724; }
		.summary.fail { background: #f8d7da; color: #721c24; }
		.file { margin-bottom: 15px; }
		.file-header { font-weight: bold; padding: 5px; background: #e9ecef; }
		.test { padding: 3px 10px; }
		.PASS { color: green; }
		.FAIL { color: red; }
		.ERROR { color: orange; }
		.detail { color: #666; font-size: 12px; margin-left: 20px; }
	</style>
</head>
<body>
	<h1>JSONata Test Results</h1>
	<cfoutput>
	<p>
		<b>Test Date:</b> #datetimeformat(now(), "iso")#
		<cfloop collection="#serverData#" item="key">
			<br><b>#key#:</b> #encodeforhtml(serverData[key])#
		</cfloop></p>

	<div class="summary <cfif results.totalFailed eq 0 AND results.totalErrors eq 0>pass<cfelse>fail</cfif>">
		Passed: #results.totalPassed# |
		Failed: #results.totalFailed# |
		Errors: #results.totalErrors# |
		Total: #results.totalPassed + results.totalFailed + results.totalErrors#
	</div>
	<cfloop array="#results.files#" item="file">
		<div class="file">
			<div class="file-header">
				#file.name# - #file.passed# passed, #file.failed# failed, #file.errors# errors
			</div>
			<cfloop array="#file.tests#" item="test">
				<div class="test">
					<span class="#test.status#">[#test.status#]</span> #test.message#
					<cfif structKeyExists(test, "detail")>
						<div class="detail">#htmlEditFormat(test.detail)#</div>
					</cfif>
				</div>
			</cfloop>
		</div>
	</cfloop>
	</cfoutput>
</body>
</html>
