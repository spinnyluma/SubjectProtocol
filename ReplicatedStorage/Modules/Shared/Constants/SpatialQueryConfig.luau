local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local SpatialQueryConfig = {}

local overlapParamsPresets = {
	T_Keycard = {
		ExcludeInstances = {"Player"}
	}
}

local raycastParamsPresets = {
	T_Turret = {
		ExcludeInstances = {"Self"}
	}
}


local function GetOverlapParams(presetKey: string, config: {[string]: any}): OverlapParams
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"objectName",
		"GetOverlapParams",
		"string"
	)
	if(not presetKeyIsValid) then
		return
	end
	
	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(config) == "table",
		config,
		"config",
		"GetOverlapParams",
		"table"
	)

	if(not configIsValid) then
		return
	end
	
	local overlapParams: OverlapParams = OverlapParams.new()
	local paramsPresets: {[string]: any} = overlapParamsPresets[presetKey]
	local paramsPresetsIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(paramsPresets) == "table",
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
					local player: Player? = config["Player"]
					local playerIsValid: boolean? = AssertHelper.ExpectedValAssert(
						typeof(player) == "Instance"
							and player:IsA("Model"),
						player,
						"player",
						"Model"
					)
					if(not playerIsValid) then return end
					table.insert(excludeInstances , player)
				elseif(instanceName == "Self") then
					local selfInstance: Model? = config["Self"]
					local selfIsValid: boolean? = AssertHelper.ExpectedValAssert(
						typeof(selfInstance) == "Instance"
							and selfInstance:IsA("Model"),
						selfInstance,
						"self",
						"Model"
					)
					if(not selfIsValid) then return end
					table.insert(excludeInstances, selfInstance)
				end
			end
		else
			overlapParams[propertyName] = propertyValue
		end
	end
	overlapParams.ExcludeInstances = excludeInstances 
	
	return overlapParams
end

local function GetKeycardOverlapParams(objectName: string, config: {[string]: any}): OverlapParams
	local objectNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(objectName) == "string",
		objectName,
		"objectName",
		"GetKeycardOverlapParams",
		"string"
	)
	if(not objectNameIsValid) then
		return
	end
	
	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(config) == "table",
		config,
		"config",
		"GetKeycardOverlapParams",
		"table"
	)
	
	if(not configIsValid) then
		return
	end
	
	local overlapParams = GetOverlapParams(objectName, config)
	return overlapParams
end

local function GetRaycastParams(presetKey: string, config: {[string]: any})
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"objectName",
		"GetOverlapParams",
		"string"
	)
	if(not presetKeyIsValid) then
		return
	end

	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(config) == "table",
		config,
		"config",
		"GetRaycastParams",
		"table"
	)

	if(not configIsValid) then
		return
	end

	local raycastParams = RaycastParams.new()
	local paramsPresets: {[string]: any} = raycastParamsPresets[presetKey]
	local paramsPresetsIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(paramsPresets) == "table",
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
					local player: Player? = config["Player"]
					local playerIsValid: boolean? = AssertHelper.ExpectedValAssert(
						typeof(player) == "Instance"
							and player:IsA("Model"),
						player,
						"player",
						"Model"
					)
					if(not playerIsValid) then return end
					table.insert(excludeInstances , player)
				elseif(instanceName == "Self") then
					local selfInstance: Model? = config["Self"]
					local selfIsValid: boolean? = AssertHelper.ExpectedValAssert(
						typeof(selfInstance) == "Instance"
							and selfInstance:IsA("Model"),
						selfInstance,
						"self",
						"Model"
					)
					if(not selfIsValid) then return end
					table.insert(excludeInstances, selfInstance)
				end
			end
		else
			raycastParams[propertyName] = propertyValue
		end
	end
	raycastParams.ExcludeInstances = excludeInstances 

	return raycastParams
end

local function GetTurretRaycastParams(presetKey: string, config: {[string]: any})
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"presetKey",
		"GetTurretRaycastParams",
		"string"
	)
	if(not presetKeyIsValid) then return end
	
	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(config) == "table",
		config,
		"config",
		"GetTurretRaycastParams",
		"table"
	)
	if(not configIsValid) then return end
	
	local raycastParams = GetRaycastParams(presetKey, config)
	return raycastParams
end

SpatialQueryConfig.overlapParams = {
	T_Keycard = GetKeycardOverlapParams
}

SpatialQueryConfig.raycastParams = {
	T_Turret = GetTurretRaycastParams
}
return SpatialQueryConfig
