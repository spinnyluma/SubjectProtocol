local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local CharacterConfig = require(ReplicatedStorage.Modules.Shared.Constants.CharacterConfig)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local HostilityConfig = require(ReplicatedStorage.Modules.Shared.Constants.HostilityConfig)

local CombatHelper = {}

function CombatHelper.PlayerCanAttackCharacter(player: Player, instance: Instance)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"CombatHelper.PlayerCanAttack",
		"Player"
	)
	if(not playerIsValid) then return false end
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"CombatHelper.PlayerCanAttack",
		"Instance"
	)
	if(not instanceIsValid) then return false end
	
	local character = DataModelHelper.GetRootParentWithTag(instance, CharacterConfig.CHARACTER_TAG_NAME)
	local characterIsValid = AssertHelper.ExpectedValAssert(
		typeof(character) == "Instance"
			and character:IsA("Model"),
		character,
		"character",
		"CombatHelper.PlayerCanAttack",
		"Model"
	)
	if(not characterIsValid) then return false end
	
	local attackingPlayerIsSubject = player.Team == TeamConfig.teams.Subjects.Team
	local attackingPlayerIsGuard = player.Team == TeamConfig.teams.Guards.Team
	
	local playerFromCharacter = Players:GetPlayerFromCharacter(character)
	if(not playerFromCharacter) then
		return false
	end
	local receivingPlayerIsSubject = playerFromCharacter.Team == TeamConfig.teams.Subjects.Team
	local receivingPlayerIsGuard = playerFromCharacter.Team == TeamConfig.teams.Guards.Team
	local receivingPlayerIsHostile = CollectionService:HasTag(character, HostilityConfig.HOSTILE_TAG_NAME)
	
	
	
	local guardAttackingHostile = attackingPlayerIsGuard 
		and receivingPlayerIsSubject
		and receivingPlayerIsHostile
	local subjectAttackingGuard = attackingPlayerIsSubject
		and receivingPlayerIsGuard
	local subjectAttackingSubject = attackingPlayerIsSubject
		and receivingPlayerIsSubject
	
	print("gaurd attacking hostile", guardAttackingHostile)
	print("subject attacking guard", subjectAttackingGuard)
	print("subject attacking subject", subjectAttackingSubject)
	
	if(guardAttackingHostile
		or subjectAttackingGuard
		or subjectAttackingSubject) then
		return true
	end
	
	return false
		
	
end


return CombatHelper
