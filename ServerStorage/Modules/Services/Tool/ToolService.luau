local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Modules.Utilities.t)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ToolService = {}

local storedTools: {[Player]: {Tool}} = {}

function ToolService.StorePlayerTools(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	local tools: {Tool} = {}

	-- Collect equipped tools from the character
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") then
				table.insert(tools, child)
			end
		end
	end

	-- Collect tools from the backpack
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				table.insert(tools, child)
			end
		end
	end

	if #tools == 0 then
		return false
	end

	-- Remove tools from the player by parenting to nil, keep references in table
	for _, tool in tools do
		tool.Parent = nil
	end

	-- Append to existing stored tools if any
	if not storedTools[player] then
		storedTools[player] = {}
	end
	for _, tool in tools do
		table.insert(storedTools[player], tool)
	end
	return true
end

function ToolService.GiveTool(player: Player, tool: Tool)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	const toolIsValidFn = t.instanceIsA("Tool")
	const toolIsValid, toolInvalidityReason = toolIsValidFn(tool)
	if not toolIsValid then
		AssertHelper.Warn(toolInvalidityReason)
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	const backpackIsValidFn = t.instanceIsA("Backpack")
	const backpackIsValid, backpackInvalidityReason = backpackIsValidFn(backpack)
	if not backpackIsValid then
		AssertHelper.Warn(backpackInvalidityReason)
		return false
	end

	-- Check if the player already has a tool with the same name (backpack or equipped)
	for _, child in backpack:GetChildren() do
		if child:IsA("Tool") and child.Name == tool.Name then
			return false
		end
	end

	local character = player.Character
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") and child.Name == tool.Name then
				return false
			end
		end
	end

	-- Player doesn't have it yet — clone and give it
	local clonedTool = tool:Clone()
	clonedTool.Parent = backpack
	return true
end

function ToolService.UnstorePlayerTools(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	local tools = storedTools[player]
	const toolsIsValidFn = t.array(t.instanceIsA("Tool"))
	const toolsIsValid, toolsInvalidityReason = toolsIsValidFn(tools)
	if not toolsIsValid then
		AssertHelper.Warn(toolsInvalidityReason)
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	const backpackIsValidFn = t.instanceIsA("Backpack")
	const backpackIsValid, backpackInvalidityReason = backpackIsValidFn(backpack)
	if not backpackIsValid then
		AssertHelper.Warn(backpackInvalidityReason)
		return false
	end

	-- Return all stored tools to the player's backpack
	for _, tool in tools do
		tool.Parent = backpack
	end

	storedTools[player] = nil

	return true
end

return ToolService

