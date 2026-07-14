local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local DictionaryHelper = require(ReplicatedStorage.Modules.Helpers.Table.DictionaryHelper)

local ITERATION_MAX_DEPTH = 32

--Performs DataModel operations
local DataModelHelper = {}

--[[
	Gets all of the instances of a particular type in the data model in a specified location.
	
	@param descendantsLocation T The location of the descendants.
	@param instanceType string The type of instance to find.
	@returns {T?} A table containing all the descendants of the specified type.
]]
function DataModelHelper.GetInstanceDescendants<T>(descendantsLocation: T, instanceType: string)
	local descendantsTable = {}
	
	local descendants: {T?} = descendantsLocation:GetDescendants()
	
	for _, descendant in ipairs(descendants) do
		if(descendant:IsA(instanceType)) then
			table.insert(descendantsTable, descendant)
		end
	end
	return descendantsTable
end

--[[
	Gets the root parent of an instance.
	The root instance is the instance whose parent is a service.
	The function returns nil if the instance passed is invalid.
	
	
	@param instance Instance The instance to get the root parent of.
	@param stopBeforeInstance Instance? The instance before which to stop searching for a root parent. Defaults to workspace.
		For example:
		Having X folder as the stopBeforeInstance means that the function will return an instance that is a direct child of this X folder.
	@returns Instance? The instance (root parent).
]]
function DataModelHelper.GetRootParent(instance: Instance, stopBeforeInstance: Instance?): Instance?
	local instanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParent. Instance expected for instance, got {instance}`,
		typeof(instance) == "Instance"
	)
	if(not instanceIsValid) then
		return
	end
	
	local stopAtInstanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParent. Instance? expected for stopBeforeInstance, got {stopBeforeInstance}`,
		typeof(stopBeforeInstance) == "Instance"
		or type(stopBeforeInstance) == "nil"
	)
	if(not stopAtInstanceIsValid) then
		return
	end
	
	
	local currentInstance: Instance = instance
	
	while(currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game 
		and stopBeforeInstance ~= currentInstance.Parent) do
		currentInstance = currentInstance.Parent
	end
	return currentInstance
end


--[[
	Gets the root parent instance which has an attribute of a specific name. 
	If the current root parent is a direct child of the workspace, the function will return that instance.
	If the parent is nil, the function will return the current iterated instance.
	
	@param Instance instance The instance to get the parent of.
	@returns Instance? The root parent instance with an attribute of a specific name.
]]
function DataModelHelper.GetRootParentWithAttribute(instance: Instance, attributeName: string): Instance?
	local instanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttribute. Instance expected for instance, got {instance}`,
		typeof(instance) == "Instance"
	)
	if(not instanceIsValid) then
		return
	end
	local attributeNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttribute. string expected for attributeName, got {attributeName}`,
		type(attributeName) == "string"
	)
	if(not attributeNameIsValid) then
		return
	end

	local currentInstance: Instance = instance
	local attributeWithName: any? = currentInstance:GetAttribute(attributeName)
	
	while(currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game 
		and (not(attributeWithName))) do
		
		currentInstance = currentInstance.Parent
		attributeWithName = currentInstance:GetAttribute(attributeName)
	end
	return currentInstance
end

--[[
	Gets the root parent instance which has an attribute of a specific value. 
	If the current root parent is a direct child of the workspace, the function will return that instance.
	If the parent is nil, the function will return the current iterated instance.
	
	@param Instance instance The instance to get the parent of.
	@param attributeName string The name of the attribute to search for.
	@param attributeValue T The value of the attribute to search for.
	@returns Instance? The root parent instance with an attribute of a specific value.
]]
function DataModelHelper.GetRootParentWithAttributeValue<T>(instance: Instance, attributeName: string, attributeValue: T): Instance?
	local instanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeValue. Instance expected for instance, got {instance}`,
		typeof(instance) == "Instance"
	)
	if(not instanceIsValid) then
		return
	end
	local attributeNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeValue. string expected for attributeName, got {attributeName}`,
		type(attributeName) == "string"
	)
	if(not attributeNameIsValid) then
		return
	end
	local attributeValueIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeValue. any expected for attributeValue, got {attributeValue}`,
		type(attributeValue) ~= nil
	)
	if(not attributeValueIsValid) then
		return
	end
	
	local currentInstance: Instance = instance
	local instanceHasAttributeValue: boolean = currentInstance:GetAttribute(attributeName) == attributeValue

	while(currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game 
		and (not(instanceHasAttributeValue))) do

		currentInstance = currentInstance.Parent
		instanceHasAttributeValue = currentInstance:GetAttribute(attributeName) == attributeValue
	end
	return currentInstance
end

--[[
	Gets the root parent instance which has an attribute of a specific value from a dictionary. 
	If the current root parent is a direct child of the workspace, the function will return that instance.
	If the parent is nil, the function will return the current iterated instance.
	
	@param Instance instance The instance to get the parent of.
	@param string attributeName The name of the attribute to search for.
	@param T attributeValue The value of the attribute to search for.
	@param {[any]: any?} dictionary The dictionary to search in.
	@returns Instance? The root parent instance with an attribute of a specific value.
]]
function DataModelHelper.GetRootParentWithAttributeDictValue<T>(instance: Instance,
	attributeName: string,
	attributeValue: T,
	dictionary: {[any]: any?})
	local instanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. Instance expected for instance, got {instance}`,
		typeof(instance) == "Instance"
	)
	if(not instanceIsValid) then
		return
	end
	local attributeNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. string expected for attributeName, got {attributeName}`,
		type(attributeName) == "string"
	)
	if(not attributeNameIsValid) then
		return
	end
	local attributeValueIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. any expected for attributeValue, got {attributeValue}`,
		type(attributeValue) ~= nil
	)
	if(not attributeValueIsValid) then
		return
	end
	local dictionaryIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. dictionary expected for attributeValue, got {dictionary}`,
		DictionaryHelper.IsTableDictionary(dictionary)
	)
	if(not dictionaryIsValid) then
		return
	end
	
	local currentInstance: Instance = instance
	local instanceHasAttributeDictValue: boolean = dictionary[currentInstance:GetAttribute(attributeName)] ~= nil

	while(currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game 
		and (not(instanceHasAttributeDictValue))) do

		currentInstance = currentInstance.Parent
		instanceHasAttributeDictValue = dictionary[currentInstance:GetAttribute(attributeName)] ~= nil
	end
	return currentInstance
end

--[[
	Returns the first parent with a tag name.
	If a parent of an instance is nil while the function works up the tree, the function will return that instance.
	If the parent of the parent of the instance is the "game" object, the function will return that instance.
	The function will go up the DataModel tree with a maximum of 32 iterations to avoid infinite loops.
	
	@param Instance instance The instance to get the parent of.
	@param string tagName The name of the tag to search for.
	@returns Instance? The parent with a tag name.
]]
function DataModelHelper.GetRootParentWithTag(instance: Instance,
	tagName: string
): Instance?
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"DataModelHelper.GetRootParentWithTag",
		"Instance"
	)
	if(not instanceIsValid) then return end
	
	local tagNameIsValid = AssertHelper.InvalidArgAssert(
		type(tagName) == "string",
		tagName,
		"tagName",
		"DataModelHelper.GetRootParentWithTag",
		"string"
	)
	if(not tagNameIsValid) then return end
	
	local instanceWithTag: Instance = nil
	local currentInstance = instance

	local currentDepth: number = 0
	
	if(CollectionService:HasTag(currentInstance, tagName)) then
		return currentInstance
	end

	while currentDepth < ITERATION_MAX_DEPTH
		and currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game do
		if(CollectionService:HasTag(currentInstance.Parent, tagName)) then
			instanceWithTag = currentInstance.Parent
			break	
		else
			currentInstance = currentInstance.Parent
			currentDepth += 1
		end
	end
	return instanceWithTag
end

--[[
	Checks whether an attribute with a specific name appears as a key in a dictionary.
	
	@param Instance instance The instance to get the parent of.
	@param string attributeName The name of the attribute to search for.
	@param {[any]: any?} dictionary The dictionary to search in.
]]
function DataModelHelper.GetRootParentFromAttributeNameAsDictKey(instance: Instance,
	attributeName: string,
	dictionary: {[any]: any?})
	local instanceIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. Instance expected for instance, got {instance}`,
		typeof(instance) == "Instance"
	)
	if(not instanceIsValid) then
		return
	end
	local attributeNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. string expected for attributeName, got {attributeName}`,
		type(attributeName) == "string"
	)
	if(not attributeNameIsValid) then
		return
	end
	
	local dictionaryIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DataModelHelper.GetRootParentWithAttributeDictValue. dictionary expected for attributeValue, got {dictionary}`,
		DictionaryHelper.IsTableDictionary(dictionary)
	)
	if(not dictionaryIsValid) then
		return
	end

	local currentInstance: Instance = instance
	local instanceHasAttributeDictValue: boolean = dictionary[currentInstance:GetAttribute(attributeName)] ~= nil

	while(currentInstance.Parent ~= nil
		and currentInstance.Parent.Parent ~= game 
		and (not(instanceHasAttributeDictValue))) do

		currentInstance = currentInstance.Parent
		instanceHasAttributeDictValue = dictionary[currentInstance:GetAttribute(attributeName)] ~= nil
	end
	--TODO: finish this
	return currentInstance
end
--[[
	Waits for a child of a specific class to appear in the parent.
	This function yields. 
	@param parent Instance The parent to search in.
	@param className string The class of the child to wait for.
	@param timeOut number The time out for the wait.
	@returns Promise The promise containing the resolved child.
]]
function DataModelHelper.WaitForChildWhichIsA(parent: Instance, className: string, timeOut: number): Promise
	local parentIsValid: boolean = typeof(parent) == "Instance"
	if(not parentIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWhichIsA. Instance expected for parent, got {parent}`)
	end
	local classNameIsValid: boolean = type(className) == "string"
	if(not classNameIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWhichIsA. string expected for className, got {className}`)
	end
	local timeOutIsValid: boolean = type(timeOut) == "number"
	if(not timeOutIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWhichIsA. number expected for timeOut, got {timeOut}`)
	end
	
	local waitTime = 0
	local warned = false
	repeat
		local obj = parent:FindFirstChildOfClass(className)
		if obj then 
			return Promise.resolve(obj) 
		else
			waitTime = waitTime + wait()
			if timeOut then 
				if waitTime > timeOut then return nil end
			elseif not warned then
				if waitTime > 5 then 
					warn("Infinite yield possible waiting on",parent:GetFullName() .. ":FindFirstChildOfClass(\"".. className .. "\")")
					warned = true
				end
			end
		end
	until false
end

--[[
	Waits for a child with a name.
	This function yields.
	
	@param parent Instance The parent to search in.
	@param name string The name of the child to wait for.
	@param timeout number? The timeout for the wait. If not specified, the wait will never time out.
]]
function DataModelHelper.WaitForChildWithName(parent: Instance, name: string, timeout: number?): Promise
	local parentIsValid: boolean = typeof(parent) == "Instance"
	if(not parentIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWithName. Instance expected for parent, got {parent}`)
	end
	local nameIsValid: boolean = type(name) == "string"
	if(not nameIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWithName. string expected for name, got {name}`)
	end
	local timeoutIsValid: boolean = type(timeout) == "number" or type(timeout) == "nil"
	if(not timeoutIsValid) then
		return Promise.reject(`Invalid argument to DataModelHelper.WaitForChildWithName. number? expected for timeout, got {timeout}`)
	end
	
	local child: Instance? = nil
	if(not timeout) then
		child = parent:WaitForChild(name)
	else
		child = parent:WaitForChild(name, timeout)
	end
	
	return Promise.resolve(child)
end


--[[
	Gets the instances that are NOT a particular instance under the same level in the DataModel
	hierarchy.
	
	@param instance Instance The instance to invert the selection for.
	@returns {Instance?} The list of instances that are NOT the passed instance under the same DataModel hierarchy level.
]]
function DataModelHelper.InvertSelection(instance: Instance): {Instance?}?
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"DataModelHelper.InvertSelection",
		"Instance"
	)
	if not instanceIsValid then return end
	
	
	local parentInstance = instance.Parent
	local parentInstanceIsValid = AssertHelper.ExpectedValAssert(
		typeof(parentInstance) == "Instance",
		parentInstance,
		"parentInstance",
		"DataModelHelper.InvertSelection",
		"Instance"
	)
	if not parentInstanceIsValid then return end
	
	local children = parentInstance:GetChildren()
	local invertedSelection = {}
	for _, child in children do
		if child ~= instance then
			table.insert(invertedSelection, child)
		end
	end
	return invertedSelection
end

return DataModelHelper
