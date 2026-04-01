component displayname="JSONataFunctionBridge" hint="Bridges CFML closures to jsonata-java custom functions" {

	variables.bridgeClass = javacast("null", "");

	/**
	 * Register CFML closures as custom JSONata functions on a frame
	 * @frame The Java Frame object from expression.createFrame()
	 * @functions Struct of { functionName: cfmlClosure }
	 * @javaLoader Optional JavaLoader instance. If null, uses native createObject.
	 */
	public void function registerFunctions(required any frame, required struct functions, any javaLoader) {
		if (isNull(variables.bridgeClass)) {
			if (!isNull(arguments.javaLoader)) {
				variables.bridgeClass = arguments.javaLoader.create("jsonata.bridge.CFMLFunctionBridge");
			} else {
				variables.bridgeClass = createObject("java", "jsonata.bridge.CFMLFunctionBridge");
			}
		}

		var pc = getPageContext();

		for (var funcName in arguments.functions) {
			var closure = arguments.functions[funcName];
			var wrapper = new JSONataFunctionWrapper(closure);
			var jFunction = variables.bridgeClass.create(wrapper, pc);
			arguments.frame.bind(lCase(funcName), jFunction);
		}
	}

}
