local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local DictionaryHelper = {}

--[[
	Gets the number of key/value pairs in a dictionary.
	If none or invalid arguments are passed, the function will return nil.
	
	@param dictionary {[TKey]: TValue?}? The dictionary for which to count the number of key/value pairs.
	@returns number? The number of key/value pairs.
]]
function DictionaryHelper.GetLengthOfDictionary<TKey, TValue>(dictionary: {[TKey]: TValue?}?): number?
	local dictionaryIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to DictionaryHelper.GetLengthOfDictionary. table? expected for dictionary, got {dictionary}`,
		type(dictionary) == "table"
		or type(dictionary) == "nil"
	)
	if(not dictionaryIsValid) then
		return nil
	end
	local counter = 0
	for _, dictItem in pairs(dictionary) do
		counter += 1
	end
	return counter
end

--[[
	Checks whether a table is a dictionary or a table.
	
	@param tableToCheck {[TKey]: TValue} | {} The table to check.
	@returns boolean Whether the table is a dictionary. If the checked table is a dictionary, the function will return true, false if not.
]]
function DictionaryHelper.IsTableDictionary<TKey, TValue>(tableToCheck: {[TKey]: TValue} | {}): boolean
	if(typeof(tableToCheck) ~= "table") then
		return false
	end
	
	--[[
		Keep track of a current index 
		because we want to make sure that the keys go up incrementally 
		and find out whether the table is a table or dictionary
	]]
	local currentIndex: number = 1
	for key, _ in pairs(tableToCheck) do
		if(key ~= currentIndex) then
			return true
		end
		currentIndex += 1
	end
	return false
end

--[[
	Gets keys from a dictionary as a table.
	
	@returns {TKey?} A table of keys.
]]
function DictionaryHelper.GetKeys<TKey, TValue>(tableToGetKeysFrom: {[TKey]: TValue?}): {TKey?}
	local keys = {}
	for key, _ in pairs(tableToGetKeysFrom) do
		table.insert(keys, key)
	end
	return keys
end

--[[
	Gets values from a dictionary as a table.
	
	@returns {TValue?} A table of values.
]]
function DictionaryHelper.GetValues<TKey, TValue>(tableToGetValuesFrom: {[TKey]: TValue?}): {TValue?}
	local values = {}
	for _, value in pairs(tableToGetValuesFrom) do
		table.insert(values, value)
	end
	return values
end

function DictionaryHelper.GetRandomValueFromDict(dictionary: {[string]: any?}): any?
	local dictionaryIsValid = AssertHelper.InvalidArgAssert(
		type(dictionary) == "table",
		dictionary,
		"dictionary",
		"DictionaryHelper.GetRandomValueFromDict",
		"table"
	)
	if(not dictionaryIsValid) then return nil end
	
	local keys: {string?}? = DictionaryHelper.GetKeys(dictionary)
	if(not keys) then return nil end
	
	
	local random: Random = Random.new()
	local nextRandomInt: number = random:NextInteger(1, #keys)
	
	
	return dictionary[keys[nextRandomInt]]
end

--[[
	Gets a random key from a dictionary.
	If none or invalid arguments are passed, the function will return nil.
	
	@param dictionary {[TKey]: TValue?}? The dictionary from which to get a random key.
	@returns TKey? A random key from the dictionary.
]]
function DictionaryHelper.GetRandomKeyFromDict<TKey, TValue>(dictionary: {[TKey]: TValue?}?): TKey?
	local dictionaryIsValid = AssertHelper.InvalidArgAssert(
		type(dictionary) == "table",
		dictionary,
		"dictionary",
		"DictionaryHelper.GetRandomKeyFromDict",
		"table"
	)
	if(not dictionaryIsValid) then return nil end
	
	local keys: {TKey?}? = DictionaryHelper.GetKeys(dictionary)
	if(not keys or #keys == 0) then return nil end
	
	local random: Random = Random.new()
	local nextRandomInt: number = random:NextInteger(1, #keys)
	
	return keys[nextRandomInt]
end

return DictionaryHelper
