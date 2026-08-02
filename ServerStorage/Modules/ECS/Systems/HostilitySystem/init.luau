local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")



local HostilityConfig = require(ReplicatedStorage.Modules.Shared.Constants.HostilityConfig)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local TableHelper = require(ReplicatedStorage.Modules.Helpers.Table.TableHelper)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local ProximityInteractionConfig = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Config)

local ProximityInteractionSignals = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Signals)

local subjectsTeam = Teams.Subjects

local hostilityIndicator = ServerStorage.Assets.UI.Templates.Billboards.Indicators.HostilityIndicator


local HostilitySystem = {}

local playersInSafeZones: {[Model]: {Player?}?} = {}

local subjectsInSafeZoneThreads: {[Model]: thread?} = {}


local function GetSubjectsOutOfSafeZone(proximityObjects: {[Instance]: {Instance?}?}): {Player?}?
	local proximityObjectsIsValid = AssertHelper.InvalidArgAssert(
		type(proximityObjects) == "table",
		proximityObjects,
		"proximityObjects",
		"GetSubjectsOutOfSafeZone",
		"table"
	)
	if(not proximityObjectsIsValid) then return end
	
	local packedTables = {}
	
	for _, objectsFound in proximityObjects do
		table.insert(packedTables, objectsFound)
	end
	local joinedPlayers = TableHelper.JoinTables({}, table.unpack(packedTables))
	local joinedPlayersIsValid = AssertHelper.ExpectedValAssert(
		type(joinedPlayers) == "table",
		joinedPlayers,
		"joinedTables",
		"table"
	)
	if(not joinedPlayersIsValid) then return end
	
	local subjectsOutOfSafezone = subjectsTeam:GetPlayers()
	
	for i = #subjectsOutOfSafezone, 1, -1 do
		local currentSubject = subjectsOutOfSafezone[i]
		local subjectCharacter = currentSubject.Character
		if(not subjectCharacter) then continue end
		
		local subjectIsInSafeZoneIndex = table.find(joinedPlayers, subjectCharacter)
		if(subjectIsInSafeZoneIndex ~= nil) then
			table.remove(subjectsOutOfSafezone, i)
		end		
	end
	return subjectsOutOfSafezone
end

local function SetHostilityIndicatorVisibility(character: Model, isVisible: boolean)
	local characterIsValid = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"AddHostilityTag",
		"Model"
	)
	if(not characterIsValid) then return end
	
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"AddHostilityTag",
		"boolean"
	)
	if(not isVisibleIsValid) then return end
	
	local head = character:FindFirstChild("Head")
	if(not head) then return end
	
	if(isVisible) then
		local clonedHostilityIndicator = hostilityIndicator:Clone()

		clonedHostilityIndicator.Parent = head
	else
		local currentHostilityIndicator = head:FindFirstChild(hostilityIndicator.Name)
		if(not currentHostilityIndicator) then return end
		
		currentHostilityIndicator:Destroy()
	end
		
end

local function MarkSubjectsAsHostile(subjectsOutOfSafezone: {Player?})
	local subjectsOutOfSafezoneIsValid = AssertHelper.InvalidArgAssert(
		type(subjectsOutOfSafezone) == "table",
		subjectsOutOfSafezone,
		"subjectsOutOfSafezone",
		"MarkSubjectsAsHostile",
		"table"
	)
	if(not subjectsOutOfSafezoneIsValid) then return end
	
	for _, subject in subjectsOutOfSafezone do
		local subjectCharacter = subject.Character
		if(not subjectCharacter) then continue end
		local hasHostileTag = CollectionService:HasTag(subjectCharacter, HostilityConfig.HOSTILE_TAG_NAME)
		if(hasHostileTag) then continue end
		
		SetHostilityIndicatorVisibility(subjectCharacter, true)
		
		local inSafeZoneExistentThread = subjectsInSafeZoneThreads[subjectCharacter]
		if(inSafeZoneExistentThread) then
			task.cancel(inSafeZoneExistentThread)
			subjectsInSafeZoneThreads[subjectCharacter] = nil
		end
		
		CollectionService:AddTag(subjectCharacter, HostilityConfig.HOSTILE_TAG_NAME)
	end
	
end

local function StartMarkingSubjectsInSafeZone(currentSubjectsOutOfSafeZone: {Player?})
	local currentSubjectsOutOfSafeZoneIsValid = AssertHelper.InvalidArgAssert(
		type(currentSubjectsOutOfSafeZone) == "table",
		currentSubjectsOutOfSafeZone,
		"currentSubjectsOutOfSafeZone",
		"MarkSubjectsInSafeZone",
		"table"
	)
	if(not currentSubjectsOutOfSafeZoneIsValid) then return end
	
	local subjectsToMarkAsSafe = {}
	
	if(#currentSubjectsOutOfSafeZone == 0) then
		subjectsToMarkAsSafe = subjectsTeam:GetPlayers()
	else
		subjectsToMarkAsSafe = DataModelHelper.InvertSelection(currentSubjectsOutOfSafeZone)
	end
	
	for _, subject in subjectsToMarkAsSafe do
		local subjectCharacter = subject.Character
		if(not subjectCharacter) then continue end
		
		local hasHostileTag = CollectionService:HasTag(subjectCharacter, HostilityConfig.HOSTILE_TAG_NAME)
		if(not hasHostileTag) then continue end
		
		local inSafeZoneThread: thread? = subjectsInSafeZoneThreads[subjectCharacter]
		if(not inSafeZoneThread) then
			local newInSafeZoneThread = task.delay(HostilityConfig.HOSTILE_DURATION, function()
				
				CollectionService:RemoveTag(subjectCharacter, HostilityConfig.HOSTILE_TAG_NAME)
				SetHostilityIndicatorVisibility(subjectCharacter, false)

				if(subjectsInSafeZoneThreads[subjectCharacter]) then
					subjectsInSafeZoneThreads[subjectCharacter] = nil
				end
			end)
			subjectsInSafeZoneThreads[subjectCharacter] = newInSafeZoneThread
		end
	end
end

function HostilitySystem.Initialize()
	ProximityInteractionSignals.ProximityObjectsFound:Connect(function(interactionType: string,
		proximityObjects: {[Instance]: {Instance?}?})
		if(interactionType ~= ProximityInteractionConfig.proximityInteractionTypes.T_SafeZone.Name) then
			return
		end
		
		local subjectsOutOfSafeZone = GetSubjectsOutOfSafeZone(proximityObjects)
		if(not subjectsOutOfSafeZone) then return end
		MarkSubjectsAsHostile(subjectsOutOfSafeZone)
		if(#subjectsOutOfSafeZone == 0) then
			StartMarkingSubjectsInSafeZone({})
		else
			StartMarkingSubjectsInSafeZone(subjectsOutOfSafeZone)	
		end
	end)
end
return HostilitySystem
