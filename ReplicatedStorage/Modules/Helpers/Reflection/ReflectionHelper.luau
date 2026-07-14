local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReflectionService = game:GetService("ReflectionService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ReflectionHelper = {}

--[[
	Checks if a property exists in a class

	@param class string The class for which to check if a property exists.
	@param propertyName string The name of the property to check for.
	@returns boolean Whether the property exists.
]]
function ReflectionHelper.DoesClassHaveProperty(class: string, propertyName: string): boolean
	local classIsValid = AssertHelper.InvalidArgAssert(
		type(class) == "string",
		class,
		"class",
		"ReflectionHelper.DoesClassHaveProperty",
		"string"
	)
	if(not classIsValid) then return false end
	local propertyNameIsValid = AssertHelper.InvalidArgAssert(
		type(propertyName) == "string",
		propertyName,
		"propertyName",
		"ReflectionHelper.DoesClassHaveProperty",
		"string"
	)
	if(not propertyNameIsValid) then return false end
	
	local classProperties = ReflectionService:GetPropertiesOfClass(class)
	if(#classProperties == 0) then return false end
	
	
	for _, propertyTable in classProperties do
		if(propertyTable.Name == propertyName) then
			return true
		end
	end
	
	return false
end

return ReflectionHelper
