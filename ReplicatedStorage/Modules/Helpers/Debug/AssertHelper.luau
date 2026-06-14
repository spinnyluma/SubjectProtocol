local LogService = game:GetService("LogService")

local AssertHelper = {}

--[[
	Asserts a condition.
	The function warns using the message passsed to the function.
	If one of the parameters passed was invalid in the sense that parameter and argument types do not match,
	the function will warn and return nil.
	
	@param message string The message to warn with when the condition is false.
	@param condition boolean? The condition.
	@returns boolean? The condition that was passed to the function.
]]
function AssertHelper.Assert(message: string, condition: boolean?): boolean?
	if(type(message) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.Assert. string expected for message, got {message}`, 2))
		return	
	end
	
	
	if(type(condition) ~= "boolean"
		and type(condition) ~= "nil") then
		warn(debug.traceback(`Invalid argument to AssertHelper.Assert. boolean? expected for condition, got {condition}`, 2))
		return	
	end
	
	if(not condition) then
		warn(debug.traceback(message, 2))
		return
	end
	
	return condition
end

--[[
	Returns a debug traceback to the caller of the function 
	indicating that the arguments to a function are invalid (if they are invalid).
	
	@param boolean condition The condition.
	@param T value The value to assert.
	@param string valueName The name of the value.
	@param string functionName The name of the function.
	@param string expectedType The expected type of the value.
	@returns string? The condition that was passed to the function. If the condition is false, the function will return a traceback. 
		If it was true or the arguments to this function were invalid, it will return nil.
]]
function AssertHelper.GetInvalidArgAssertMsg<T>(
	condition: boolean,
	value: T?,
	valueName: string,
	functionName: string,
	expectedType: string
): string?
	if(type(condition) ~= "boolean") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. boolean expected for condition, got {condition}`, 2))
		return nil
	end


	if(type(valueName) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for valueName, got {valueName}`, 2))
		return nil
	end

	if(type(functionName) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for functionName, got {functionName}`, 2))
		return nil
	end

	if(type(expectedType) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for expectedType, got {expectedType}`, 2))
		return nil
	end
	
	if(not condition) then
		return debug.traceback(`Invalid argument to {functionName}. {expectedType} expected for {valueName}, got {value}`, 2)
	end
	return nil
end

--[[
	Asserts invalid arguments to a function.
	
	@param boolean condition The condition.
	@param T value The value to assert.
	@param string valueName The name of the value.
	@param string functionName The name of the function.
	@param string expectedType The expected type of the value.
	@returns boolean? The condition that was passed to the function if it was a boolean.
]]
function AssertHelper.InvalidArgAssert<T>(condition: boolean,
	value: T?,
	valueName: string,
	functionName: string,
	expectedType: string): boolean?
	if(type(condition) ~= "boolean") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. boolean expected for condition, got {condition}`, 2))
		return nil
	end

	
	if(type(valueName) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for valueName, got {valueName}`, 2))
		return condition
	end
	
	if(type(functionName) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for functionName, got {functionName}`, 2))
		return condition
	end
	
	if(type(expectedType) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.InvalidArgAssert. string expected for expectedType, got {expectedType}`, 2))
		return condition
	end
	
	if(not condition) then
		LogService:Warn("Invalid argument was passed to a function", {
			nameOfFunction = functionName,
			nameOfValue = valueName,
			rawValue = tostring(value),
			expectedType = expectedType,
			traceback = debug.traceback(nil, 2)
		})
		return condition
	end
	
	return condition
end

--[[
	Asserts that a value is expected to be a certain type.
	
	@param boolean condition The condition.
	@param T? value The value to assert.
	@param string valueName The name of the value.
	@param string expectedType The expected type of the value.
	@returns boolean? The condition that was passed to the function.
]]
function AssertHelper.ExpectedValAssert<T>(condition: boolean,
	value: T?,
	valueName: string,
	expectedType: string
): boolean?
	if(type(condition) ~= "boolean") then
		warn(debug.traceback(`Invalid argument to AssertHelper.ExpectedValAssert. boolean expected for condition, got {condition}`, 2))
		return nil
	end
	
	

	if(type(valueName) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.ExpectedValAssert. string expected for valueName, got {valueName}`, 2))
		return condition
	end
	
	if(type(expectedType) ~= "string") then
		warn(debug.traceback(`Invalid argument to AssertHelper.ExpectedValAssert. string expected for expectedType, got {expectedType}`, 2))
		return condition
	end
	
	if(not condition) then
		LogService:Warn("Unexpected value was obtained in a variable", {
			nameOfValue = valueName,
			rawValue = tostring(value),
			expectedType = expectedType,
			traceback = debug.traceback(nil, 2)
		})
		warn(debug.traceback(`{expectedType} expected for {valueName}, got {value}`, 2))
		return condition
	end
	return condition
end
--[[
	Warns with the message passed to the function.
	
	@param message string The message to warn with.
]]
function AssertHelper.Warn(message: string)
	local messageIsValid: boolean? = AssertHelper.Assert(
		`Invalid arguemnt to AssertHelper.Warn. string expected for message, got {message}`,
		type(message) == "string"
	)
	if(not messageIsValid) then
		return
	end
	warn(debug.traceback(message, 2))
end

return AssertHelper
