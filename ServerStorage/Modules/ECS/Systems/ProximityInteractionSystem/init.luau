local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ProximityConfig = require(script.Config)
local ProximitySignals = require(script.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local InteractionHandlers = require(script.InteractionHandlers)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local ProximitySystem = {}

local queryTargets = {
	T_Keycard = {"T_KeycardReader"},
	T_Terminal = {"T_Player"},
	T_SafeZone = {"T_Player"}
}


local onQueriedHandlers = {
	T_KeycardReader = InteractionHandlers.HandleKeycardReaderQueried,
}

local function PerformProximityQuery(origin: BasePart,
	queryType: string,
	overlapParams: OverlapParams,
	presetKey: string,
	interactionRadius: number?
): {Instance?}?
	local originIsValid = AssertHelper.InvalidArgAssert(
		typeof(origin) == "Instance"
		and origin:IsA("BasePart"),
		origin,
		"origin",
		"PerformProximityQuery",
		"BasePart"
	)
	if(not originIsValid) then
		return
	end
	
	local interactionRadiusIsValid = AssertHelper.InvalidArgAssert(
		type(interactionRadius) == "number"
		or type(interactionRadius) == "nil",
		interactionRadius,
		"interactionRadius",
		"PerformProximityQuery",
		"number?"
	)
	if(not interactionRadiusIsValid) then
		return
	end
	local queryTypeIsValid = AssertHelper.InvalidArgAssert(
		type(queryType) == "string"
			and SpatialQueryConfig.queryTypes[queryType].Name ~= nil,
		queryType,
		"queryType",
		"PerformProximityQuery",
		"string"
	)
	if(not queryTypeIsValid) then return end
	
	local overlapParamsIsValid = AssertHelper.InvalidArgAssert(
		typeof(overlapParams) == "OverlapParams",
		overlapParams,
		"overlapParams",
		"PerformProximityQuery",
		"OverlapParams"
	)
	if(not overlapParamsIsValid) then
		return
	end
	
	local presetKeyIsValid = AssertHelper.InvalidArgAssert(
		type(presetKey) == "string",
		presetKey,
		"presetKey",
		"PerformProximityQuery",
		"string"
	)
	if(not presetKeyIsValid) then
		return
	end
	local parts: {Part?}? = nil
	if(queryType == SpatialQueryConfig.queryTypes.Radius.Name) then
		parts = workspace:GetPartBoundsInRadius(origin.Position,
			interactionRadius,
			overlapParams
		)
	elseif(queryType == SpatialQueryConfig.queryTypes.Box.Name) then
		local boxSize = Vector3.new(
			origin.Size.X,
			origin.Size.Y,
			origin.Size.Z
		)
		
		parts = workspace:GetPartBoundsInBox(origin.CFrame,
			boxSize,
			overlapParams
		)
	elseif(queryType == SpatialQueryConfig.queryTypes.Part.Name) then
		parts = workspace:GetPartsInPart(
			origin,
			overlapParams
		)
	end
	local targetParents = {}
	local parentTagName = ProximityConfig.parentTagNames[presetKey]
	for _, part in parts do
		local targetParent = DataModelHelper.GetRootParentWithTag(part, parentTagName)
		if(not targetParent) then continue end
		local targetParentIndex = table.find(targetParents, targetParent)
		if(typeof(targetParentIndex) == "number") then
			continue
		end
		table.insert(targetParents, targetParent)
	end
	
	return targetParents
end

function ProximitySystem.Update(timeSinceLastUpdate: number)
	local taggedInstances = CollectionService:GetTagged(ProximityConfig.SYSTEM_TAG_NAME)
	local proximityObjectsFound: {[string]: {[Instance]: {Instance}}?} = {}
	for _, taggedInstance in taggedInstances do
		if(not taggedInstance:IsDescendantOf(workspace)) then
			continue
		end
		
		local queryType = taggedInstance:GetAttribute(SpatialQueryConfig.QUERY_TYPE_ATTR_NAME)
		local queryTypeIsValid = AssertHelper.ExpectedValAssert(
			type(queryType) == "string"
				and SpatialQueryConfig.queryTypes[queryType].Name ~= nil,
			queryType,
			"queryType",
			"string"
		)
		if(not queryTypeIsValid) then continue end
		local interactionRadius: number? = nil
		
		local presetKey: string? = nil
		for overlapParamTagName, _ in SpatialQueryConfig.overlapParams do
			if(not CollectionService:HasTag(taggedInstance, overlapParamTagName)) then
				continue
			end
			presetKey = overlapParamTagName
			break
		end

		local presetKeyIsValid = AssertHelper.ExpectedValAssert(
			typeof(presetKey) == "string",
			presetKey,
			"presetKey",
			"string"
		)
		if(not presetKeyIsValid) then
			continue
		end
		
		
		if(queryType == SpatialQueryConfig.queryTypes.Radius.Name) then
			interactionRadius = taggedInstance:GetAttribute(ProximityConfig.INTERACTION_RADIUS_ATTR_NAME)
			local interactionRadiusIsValid = AssertHelper.ExpectedValAssert(
				type(interactionRadius) == "number",
				interactionRadius,
				"interactionRadius",
				"number"
			)
			if(not interactionRadiusIsValid) then
				continue
			end
		end
		
		
		
		local overlapParamsFn = SpatialQueryConfig.overlapParams[presetKey]
		local overlapParamsIsValid = AssertHelper.ExpectedValAssert(
			type(overlapParamsFn) == "function",
			overlapParamsFn,
			"overlapParams",
			"OverlapParams"
		)
		if(not overlapParamsIsValid) then
			continue
		end
		local configKeys = SpatialQueryConfig.GetConfigKeys(presetKey)
		local config: {[string]: any?} = {}
		for _, configKey in configKeys do
			if(configKey == "Player") then
				local playerModel: any = taggedInstance.Parent
				local playerObtained: Player? = Players:GetPlayerFromCharacter(playerModel)
				local playerObtainedIsValid: boolean = typeof(playerObtained) == "Instance"
					and playerObtained:IsA("Player")
				if(not playerObtainedIsValid) then
					continue
				end
				config["Player"] = playerModel
				
			elseif(configKey == "Self") then
				config["Self"] = taggedInstance
			end
		end
		
		local overlapParams: OverlapParams? = overlapParamsFn(presetKey, config)
		local overlapParamsIsValid = AssertHelper.ExpectedValAssert(
			typeof(overlapParams) == "OverlapParams",
			overlapParams,
			"overlapParams",
			"OverlapParams"
		)
		if(not overlapParamsIsValid) then continue end
		local origin: BasePart? = taggedInstance:FindFirstChild("Origin")
		local originIsValid = AssertHelper.ExpectedValAssert(
			typeof(origin) == "Instance"
				and origin:IsA("BasePart"),
			origin,
			"origin",
			"BasePart"	
		)
		if(not originIsValid) then
			continue
		end
		local instancesFound = PerformProximityQuery(origin, queryType, overlapParams, presetKey, interactionRadius)
		if(not instancesFound) then return end
		
		if(not proximityObjectsFound[presetKey]) then
			proximityObjectsFound[presetKey] = {}
		end
		proximityObjectsFound[presetKey][taggedInstance] = instancesFound
	end
	
	for presetKey, proximityObjects in proximityObjectsFound do
		ProximitySignals.ProximityObjectsFound:Fire(presetKey, proximityObjects)
	end
end

function ProximitySystem.Initialize()
	
end

return ProximitySystem
