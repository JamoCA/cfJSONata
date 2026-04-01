component displayname="JSONata" hint="CFML wrapper for the jsonata-java library" {

	variables.jJsonata = javacast("null", "");
	variables.jJsonParser = javacast("null", "");
	variables.javaLoaderInstance = javacast("null", "");

	/**
	 * Initialize the JSONata component
	 * @jarPaths Optional. A string path to a single JAR, or an array of JAR paths to load.
	 *           Must include both jsonata-java and jsonata-cfml-bridge JARs for custom function support.
	 *           If omitted, tries the native classpath first, then falls back to JavaLoader with default JARs/ folder.
	 */
	public JSONata function init(any jarPaths = "") {
		// Normalize jarPaths to an array
		var paths = [];
		if (isArray(arguments.jarPaths)) {
			paths = arguments.jarPaths;
		} else if (isSimpleValue(arguments.jarPaths) && len(arguments.jarPaths)) {
			paths = [arguments.jarPaths];
		}

		if (arrayLen(paths)) {
			// Priority 1: Explicit JAR paths — use JavaLoader
			loadViaJavaLoader(paths);
		} else {
			// Priority 2: Try native Java classpath
			try {
				variables.jJsonata = createObject("java", "com.dashjoin.jsonata.Jsonata");
				variables.jJsonParser = createObject("java", "com.dashjoin.jsonata.json.Json");
				return this;
			} catch (any e) {
				// Priority 3: Try JavaLoader with default JARs/ folder
				var defaultJarDir = getDirectoryFromPath(getCurrentTemplatePath()) & "JARs";
				if (directoryExists(defaultJarDir)) {
					var jarFiles = directoryList(defaultJarDir, false, "path", "*.jar");
				} else {
					var jarFiles = [];
				}
				if (arrayLen(jarFiles) > 0 && fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "javaloader/JavaLoader.cfc")) {
					loadViaJavaLoader(jarFiles);
				} else {
					throw(
						type = "JSONata.Initialization",
						message = "Unable to load the jsonata-java library.",
						detail = "The JAR is not on the classpath and could not be loaded via JavaLoader. "
							& "Download the JAR from https://mvnrepository.com/artifact/com.dashjoin/jsonata "
							& "and either place it in the ColdFusion classpath or pass the path via init(jarPaths)."
					);
				}
			}
		}
		return this;
	}

	/**
	 * Load JARs via JavaLoader
	 * @jarPaths Array of JAR file paths to load
	 */
	private void function loadViaJavaLoader(required array jarPaths) {
		// Validate all paths exist
		for (var path in arguments.jarPaths) {
			if (!fileExists(path)) {
				throw(
					type = "JSONata.Initialization",
					message = "JAR file not found: #path#",
					detail = "Download the JAR from https://mvnrepository.com/artifact/com.dashjoin/jsonata"
				);
			}
		}
		var javaLoaderPath = getDirectoryFromPath(getCurrentTemplatePath()) & "javaloader";
		if (!directoryExists(javaLoaderPath)) {
			throw(
				type = "JSONata.Initialization",
				message = "JavaLoader not found. The javaloader/ directory is required when loading a JAR by path.",
				detail = "Place the JavaLoader library in: #javaLoaderPath#"
			);
		}
		variables.javaLoaderInstance = createObject("component", "javaloader.JavaLoader").init(
			loadPaths = arguments.jarPaths
		);
		variables.jJsonata = variables.javaLoaderInstance.create("com.dashjoin.jsonata.Jsonata");
		variables.jJsonParser = variables.javaLoaderInstance.create("com.dashjoin.jsonata.json.Json");
	}

	/**
	 * Evaluate a JSONata expression against data
	 * @expression JSONata query/transform expression
	 * @data CFML struct/array or JSON string
	 * @bindings Struct of variables accessible as $varName
	 * @options Struct with timeout, maxDepth, functions
	 */
	public any function evaluate(
		required string expression,
		required any data,
		struct bindings = {},
		struct options = {}
	) {
		try {
			// Parse the expression
			var expr = variables.jJsonata.jsonata(arguments.expression);

			// Prepare the input data
			var jData = prepareData(arguments.data);

			// Create frame if bindings, options, or functions are provided
			var hasBindings = !structIsEmpty(arguments.bindings);
			var hasTimeout = structKeyExists(arguments.options, "timeout");
			var hasMaxDepth = structKeyExists(arguments.options, "maxDepth");
			var hasFunctions = structKeyExists(arguments.options, "functions") && !structIsEmpty(arguments.options.functions);
			var needsFrame = hasBindings || hasTimeout || hasMaxDepth || hasFunctions;

			var result = javacast("null", "");

			if (needsFrame) {
				var frame = expr.createFrame();

				// Bind variables
				if (hasBindings) {
					for (var key in arguments.bindings) {
						frame.bind(key, convertToJava(arguments.bindings[key]));
					}
				}

				// Set runtime bounds
				var timeout = structKeyExists(arguments.options, "timeout") ? arguments.options.timeout : 5000;
				var maxDepth = structKeyExists(arguments.options, "maxDepth") ? arguments.options.maxDepth : 100;
				if (hasTimeout || hasMaxDepth) {
					frame.setRuntimeBounds(javacast("long", timeout), javacast("int", maxDepth));
				}

				// Register custom functions
				if (hasFunctions) {
					if (isNull(variables.functionBridge)) {
						variables.functionBridge = new JSONataFunctionBridge();
					}
					if (!isNull(variables.javaLoaderInstance)) {
						variables.functionBridge.registerFunctions(frame, arguments.options.functions, variables.javaLoaderInstance);
					} else {
						variables.functionBridge.registerFunctions(frame, arguments.options.functions);
					}
				}

				result = expr.evaluate(jData, frame);
			} else {
				result = expr.evaluate(jData);
			}

			// Convert Java result back to CFML
			if (isNull(result)) {
				return javacast("null", "");
			}
			return convertToCFML(result);

		} catch (any e) {
			var msg = e.message;
			var dtl = structKeyExists(e, "detail") ? e.detail : "";
			var eType = e.type;

			if (findNoCase("timeout", msg) || findNoCase("timeout", dtl)) {
				throw(type = "JSONata.Timeout", message = msg, detail = dtl);
			}
			if (findNoCase("Stack overflow", msg) || findNoCase("non-terminating", msg) || findNoCase("recursion", msg)) {
				throw(type = "JSONata.RecursionLimit", message = msg, detail = dtl);
			}
			if (findNoCase("JException", eType)
				|| findNoCase("syntax", msg) || findNoCase("parse", msg)
				|| findNoCase("S0", msg) || findNoCase("unexpected", msg)
				|| findNoCase("Expected", msg) || findNoCase("cannot be used", msg)) {
				throw(type = "JSONata.InvalidExpression", message = msg, detail = dtl);
			}
			rethrow;
		}
	}

	/**
	 * Prepare input data for the Java library.
	 * JSON strings are parsed via the Java library's own parser.
	 * CFML structs/arrays are converted to standard Java collections.
	 */
	private any function prepareData(required any data) {
		if (isSimpleValue(arguments.data) && isJSON(arguments.data)) {
			return variables.jJsonParser.parseJson(arguments.data);
		}
		return convertToJava(arguments.data);
	}

	/**
	 * Convert CFML types to standard Java collections that jsonata-java expects.
	 * CFML arrays/structs may not be compatible with the Java library's type checks.
	 */
	private any function convertToJava(required any data) {
		if (isStruct(arguments.data)) {
			var map = createObject("java", "java.util.LinkedHashMap").init();
			for (var key in arguments.data) {
				map.put(javacast("string", key), convertToJava(arguments.data[key]));
			}
			return map;
		}
		if (isArray(arguments.data)) {
			var list = createObject("java", "java.util.ArrayList").init();
			for (var item in arguments.data) {
				list.add(convertToJava(item));
			}
			return list;
		}
		if (isNumeric(arguments.data)) {
			if (find(".", arguments.data)) {
				return javacast("double", arguments.data);
			}
			return javacast("long", arguments.data);
		}
		if (isBoolean(arguments.data) && !isNumeric(arguments.data)) {
			return javacast("boolean", arguments.data);
		}
		return arguments.data;
	}

	/**
	 * Convert Java result back to CFML types
	 */
	private any function convertToCFML(required any result) {
		if (isNull(arguments.result)) {
			return javacast("null", "");
		}
		if (isSimpleValue(arguments.result)) {
			return arguments.result;
		}
		if (isArray(arguments.result)) {
			var arr = [];
			for (var item in arguments.result) {
				arrayAppend(arr, convertToCFML(item));
			}
			return arr;
		}
		if (isStruct(arguments.result)) {
			var s = {};
			for (var key in arguments.result) {
				s[key] = convertToCFML(arguments.result[key]);
			}
			return s;
		}
		return arguments.result;
	}

}
