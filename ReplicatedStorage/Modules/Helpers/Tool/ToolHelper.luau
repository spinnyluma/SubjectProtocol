const CollectionService = game:GetService("CollectionService")
const Players = game:GetService("Players")

const AssertHelper = require("../Debug/AssertHelper")
const ToolConfig = require("../../Shared/Constants/ToolConfig")
const t = require("../../Utilities/t")

local ToolHelper = {}

function ToolHelper.GetToolType(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ToolHelper.GetToolType",
		"Tool"
	)
	if(not toolIsValid) then return end

	local toolTypeObtained: string? = nil

	for _, toolType in ToolConfig.toolTypes do
		local toolTypeTag = toolType.Tag
		if(not toolTypeTag) then continue end
		if(CollectionService:HasTag(tool, toolTypeTag)) then
			toolTypeObtained = toolType.Name
			break
		end
	end

	return toolTypeObtained
end
function ToolHelper.ToolBelongsToCharacter(tool: Tool, character: Model): boolean
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ToolHelper.ToolBelongsToCharacter",
		"Tool"
	)
	if(not toolIsValid) then return false end

	local characterIsValid = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
			and character:IsA("Model"),
		character,
		"character",
		"ToolHelper.ToolBelongsToCharacter",
		"Model"
	)
	if(not characterIsValid) then return false end

	-- Tool is currently equipped (held) by the character
	if(tool.Parent == character) then
		return true
	end

	-- Tool is sitting in the character's backpack
	local player = Players:GetPlayerFromCharacter(character)
	if(player and tool.Parent == player.Backpack) then
		return true
	end

	return false
end

function ToolHelper.PlayerHasTool(player: Player, toolName: string): boolean
	const playerIsValid, playerInvalidityReason = t.instanceIsA("Player")(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	const toolNameIsValid, toolNameInvalidityReason = t.string(toolName)
	if(not toolNameIsValid) then
		AssertHelper.Warn(toolNameInvalidityReason)
		return false
	end

	-- Check the player's character for an equipped tool with the given name
	local character = player.Character
	if(character) then
		local tool = character:FindFirstChild(toolName)
		if(tool and tool:IsA("Tool")) then
			return true
		end
	end

	-- Check the player's backpack for a tool with the given name
	local backpack = player:FindFirstChildOfClass("Backpack")
	if(backpack) then
		local tool = backpack:FindFirstChild(toolName)
		if(tool and tool:IsA("Tool")) then
			return true
		end
	end

	return false
end

return ToolHelper
