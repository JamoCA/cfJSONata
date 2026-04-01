component
	hint="Application configuration"
	output="false"
{

	this.name = "JSONata-Demo";
	this.applicationTimeout = createTimeSpan(0, 0, 1, 0);

	variables.appDir = getDirectoryFromPath(getCurrentTemplatePath());
	variables.parentDir = variables.appDir & "../";

	// Map the parent directory so "new JSONata()" resolves from tests/
	this.mappings["/jsonata"] = variables.parentDir;

	// Custom tag path for CFC resolution (fallback for older CF)
	this.customTagPaths = [
		variables.parentDir
	];

	// Load JARs natively via CF's Java settings
	this.javaSettings = {
		loadPaths: [
			variables.parentDir & "JARs"
		],
		loadColdFusionClassPath: true,
		reloadOnChange: false
	};

}
