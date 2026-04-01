component displayname="JSONataFunctionWrapper" hint="Wraps a CFML closure with a method callable via Java reflection" {

	variables.closure = "";

	public JSONataFunctionWrapper function init(required any closure) {
		variables.closure = arguments.closure;
		return this;
	}

	/**
	 * Called by CFMLFunctionBridge via Java reflection.
	 * @input The current context value in the JSONata expression
	 * @args A Java List of arguments passed to the function
	 */
	public any function callClosure(any input, any args) {
		if (!isNull(arguments.args) && isArray(arguments.args)) {
			var argCount = arrayLen(arguments.args);
			if (argCount eq 0) {
				return variables.closure();
			} else if (argCount eq 1) {
				return variables.closure(arguments.args[1]);
			} else if (argCount eq 2) {
				return variables.closure(arguments.args[1], arguments.args[2]);
			} else if (argCount eq 3) {
				return variables.closure(arguments.args[1], arguments.args[2], arguments.args[3]);
			} else {
				var argStruct = {};
				for (var i = 1; i <= argCount; i++) {
					argStruct[i] = arguments.args[i];
				}
				return variables.closure(argumentCollection = argStruct);
			}
		}
		return variables.closure();
	}

}
