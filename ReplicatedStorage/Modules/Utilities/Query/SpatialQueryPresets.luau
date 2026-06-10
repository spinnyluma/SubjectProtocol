local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssertModule = require(ReplicatedStorage.Modules.Utilities.Debug.AssertModule)

local SpatialQueryPresets = {}

local overlapParamsPresets = {
	T_Keycard = {
		ExcludeInstances = {"Player"}
	}
}

local function GetOverlapParams(objectName: string, player: Model): OverlapParams
	local objectNameIsValid: boolean? = AssertModule.InvalidArgAssert(
		type(objectName) == "string",
		objectName,
		"objectName",
		"GetOverlapParams",
		"string"
	)
	if(not objectNameIsValid) then
		return
	end
	
	local playerIsValid: boolean? = AssertModule.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Model"),
		player,
		"player",
		"GetOverlapParams",
		"Player"
	)
	if(not playerIsValid) then
		return
	end
	
	local overlapParams: OverlapParams = OverlapParams.new()
	local paramsPresets: {[string]: any} = overlapParamsPresets[objectName]
	local paramsPresetsIsValid: boolean? = AssertModule.ExpectedValAssert(
		typeof(paramsPresets) == "table",
		paramsPresets,
		"paramsPresets",
		"table"
	)	
	if(not paramsPresetsIsValid) then
		return
	end
	local excludeInstances = {}
	for propertyName, propertyValue in paramsPresets do
		if(propertyName == "ExcludeInstances") then
			for _, instanceName in propertyValue do
				if(instanceName == "Player") then
					table.insert(excludeInstances , player)

				end
			end
		else
			overlapParams[propertyName] = propertyValue
		end
	end
	overlapParams.ExcludeInstances = excludeInstances 
	
	return overlapParams
end

local function GetKeycardOverlapParams(objectName: string, player: Model): OverlapParams
	local objectNameIsValid: boolean? = AssertModule.InvalidArgAssert(
		type(objectName) == "string",
		objectName,
		"objectName",
		"GetKeycardOverlapParams",
		"string"
	)
	if(not objectNameIsValid) then
		return
	end
	
	local playerIsValid: boolean? = AssertModule.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Model"),
		player,
		"player",
		"GetKeycardOverlapParams",
		"Player"
	)
	if(not playerIsValid) then
		return
	end
	
	local overlapParams = GetOverlapParams(objectName, player)
	return overlapParams
end

SpatialQueryPresets.overlapParams = {
	T_Keycard = GetKeycardOverlapParams
}
return SpatialQueryPresets
