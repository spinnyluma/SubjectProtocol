local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ProximityConfig = require(script.Config)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local SpatialQueryPresets = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local InteractionHandlers = require(script.InteractionHandlers)

local ProximitySystem = {}

local queryTargets = {
	T_Keycard = {"T_KeycardReader"}
}


local onQueriedHandlers = {
	T_KeycardReader = InteractionHandlers.HandleKeycardReaderQueried,
}

local function PerformProximityQuery(origin: BasePart,
	interactionRadius: number,
	overlapParams: OverlapParams,
	presetKey: string
)
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
		type(interactionRadius) == "number",
		interactionRadius,
		"interactionRadius",
		"PerformProximityQuery",
		"number"
	)
	if(not interactionRadiusIsValid) then
		return
	end
	
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
	
	local parts = workspace:GetPartBoundsInRadius(origin.Position,
		interactionRadius,
		overlapParams
	)
	
	for _, part in parts do
		for _, target in queryTargets[presetKey] do			
			local isTargetInstance = CollectionService:HasTag(part, target)
			if(not isTargetInstance) then
				continue
			end
			local onQueriedHandler: (queriedTarget: Model) -> ()? = onQueriedHandlers[target]
			local onQueriedHandlerIsValid = AssertHelper.ExpectedValAssert(
				type(onQueriedHandler) == "function",
				onQueriedHandler,
				"onQueriedHandler",
				"function"
			)

			if(not onQueriedHandlerIsValid) then
				continue
			end
			onQueriedHandler(part)
		end
	end
end

function ProximitySystem.Update(timeSinceLastUpdate: number)
	local taggedInstances = CollectionService:GetTagged(ProximityConfig.SYSTEM_TAG_NAME)
	for _, taggedInstance in taggedInstances do
		local interactionRadius = taggedInstance:GetAttribute(ProximityConfig.INTERACTION_RADIUS_ATTR_NAME)
		local interactionRadiusIsValid = AssertHelper.ExpectedValAssert(
			typeof(interactionRadius) == "number",
			interactionRadius,
			"interactionRadius",
			"number"
		)
		if(not interactionRadiusIsValid) then
			continue
		end
		
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
		
		local presetKey: string? = nil
		for overlapParamTagName, _ in SpatialQueryPresets.overlapParams do
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
		local overlapParamsFn = SpatialQueryPresets.overlapParams[presetKey]
		local overlapParamsIsValid = AssertHelper.ExpectedValAssert(
			type(overlapParamsFn) == "function",
			overlapParamsFn,
			"overlapParams",
			"OverlapParams"
		)
		if(not overlapParamsIsValid) then
			continue
		end
		
		local playerModel: any = taggedInstance.Parent
		local playerObtained: Player? = Players:GetPlayerFromCharacter(playerModel)
		local playerObtainedIsValid: boolean = typeof(playerObtained) == "Instance"
			and playerObtained:IsA("Player")
		if(not playerObtainedIsValid) then
			continue
		end
		local overlapParams = overlapParamsFn(presetKey, {
			["Player"] = playerModel
		})
		local overlapParamsIsValid = AssertHelper.ExpectedValAssert(
			typeof(overlapParams) == "OverlapParams",
			overlapParams,
			"overlapParams",
			"OverlapParams"
		)
		if(not overlapParamsIsValid) then
			continue
		end
		
		PerformProximityQuery(origin, interactionRadius, overlapParams, presetKey)
		
	end
end

function ProximitySystem.Initialize()
	
end

return ProximitySystem
