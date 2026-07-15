local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local SpatialQueryConfig = {}

SpatialQueryConfig.STATIC_GEOMETRY_SELECTOR = `BasePart:not(.T_Character >> Instance, #{workspace.DynamicGeometry.Name} >> Instance)`

local overlapParamsPresets = {
	T_Keycard = {
		ExcludeInstances = {"Player"}
	},
	T_Terminal = {
		ExcludeInstances = {"Self"}
	},
	T_Experiment = {
		ExcludeInstances = {"Self"}
	}
}

local raycastParamsPresets = {
	T_Turret = {
		ExcludeInstances = {"Self"}
	},
	T_RaycastWeapon = {
		ExcludeInstances = {"Self", "AdditionalInstances"}
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
				elseif(instanceName == "AdditionalInstances") then
					local additionalInstances = config["AdditionalInstances"]
					local additionalInstancesIsValid: boolean? = AssertHelper.ExpectedValAssert(
						type(additionalInstances) == "table",
						additionalInstances,
						"additionalInstances",
						"table"
					)
					if(not additionalInstancesIsValid) then return end
					for _, instance in additionalInstances do
						table.insert(excludeInstances, instance)
					end
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
					if(not playerIsValid) then continue end
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
					if(not selfIsValid) then continue end
					table.insert(excludeInstances, selfInstance)
				elseif(instanceName == "AdditionalInstances") then
					local additionalInstances: {Model?}? = config["AdditionalInstances"]
					local additionalInstancesIsValid: boolean? = AssertHelper.ExpectedValAssert(
						type(additionalInstances) == "table",
						additionalInstances,
						"additionalInstances",
						"table"
					)
					if(not additionalInstancesIsValid) then continue end
					
					for _, instance in additionalInstances do
						table.insert(excludeInstances, instance)
					end
				end
			end
		else
			raycastParams[propertyName] = propertyValue
		end
	end
	raycastParams.ExcludeInstances = excludeInstances 

	return raycastParams
end

function SpatialQueryConfig.GetRaycastParams(presetKey: string, config: {[string]: any})
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"presetKey",
		"SpatialQueryConfig.GetRaycastParams",
		"string"
	)
	if(not presetKeyIsValid) then return end
	
	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(config) == "table",
		config,
		"config",
		"SpatialQueryConfig.GetRaycastParams",
		"table"
	)
	if(not configIsValid) then return end
	
	local raycastParams = GetRaycastParams(presetKey, config)
	return raycastParams
end

function SpatialQueryConfig.GetOverlapParams(presetKey: string, config: {[string]: any})
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"presetKey",
		"SpatialQueryConfig.GetOverlapParams",
		"string"
	)
	if(not presetKeyIsValid) then return end
	
	local configIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(config) == "table",
		config,
		"config",
		"SpatialQueryConfig.GetOverlapParams",
		"table"
	)
	if(not configIsValid) then return end
	
	local overlapParams = GetOverlapParams(presetKey, config)
	return overlapParams
end

function SpatialQueryConfig.GetConfigKeys(presetKey: string): {string?}?
	local presetKeyIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"presetKey",
		"GetConfig",
		"string"
	)
	if(not presetKeyIsValid) then return end
	
	
	local overlapParamsConfig: {[string]: any?}? = overlapParamsPresets[presetKey]
	if(not overlapParamsConfig) then
		local raycastParamsConfig: {[string]: any?}? = raycastParamsPresets[presetKey]
		local raycastParamsConfigIsValid = AssertHelper.ExpectedValAssert(
			type(raycastParamsConfig) == "table",
			raycastParamsConfig,
			"raycastParamsConfig",
			"table"
		)
		if(not raycastParamsConfigIsValid) then return end
		local keys = raycastParamsConfig.ExcludeInstances
		return keys
	else
		local keys = overlapParamsConfig.ExcludeInstances
		return keys
	end
end


SpatialQueryConfig.overlapParams = {
	T_Keycard = GetKeycardOverlapParams,
	T_Terminal = GetOverlapParams
}

SpatialQueryConfig.raycastParams = {
	T_Turret = SpatialQueryConfig.GetRaycastParams
}

SpatialQueryConfig.queryTypes = {
	Radius = {
		Name = "Radius",
		Value = 0
	},
	Box = {
		Name = "Box",
		Value = 1
	}
}



SpatialQueryConfig.QUERY_TYPE_ATTR_NAME = "A_QueryType"
return SpatialQueryConfig
