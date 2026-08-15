local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = require(ReplicatedStorage.Modules.Utilities.t)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local CuffHelper = {}

function CuffHelper.LocalPlayerIsCuffingPlayer(localPlayer: Player, targetPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const localPlayerIsValid, localPlayerInvalidityReason = playerIsValidFn(localPlayer)
	if not localPlayerIsValid then
		AssertHelper.Warn(localPlayerInvalidityReason)
		return false
	end
	
	const targetPlayerIsValid, targetPlayerInvalidityReason = playerIsValidFn(targetPlayer)
	if not targetPlayerIsValid then
		AssertHelper.Warn(targetPlayerInvalidityReason)
		return false
	end
	
	local character = localPlayer.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local cuffAlignPosition = humanoidRootPart:FindFirstChild("CuffAlignPosition")
	if not cuffAlignPosition then return false end
	
	local cuffAlignOrientation = humanoidRootPart:FindFirstChild("CuffAlignOrientation")
	if not cuffAlignOrientation then return false end
	
	-- Attachment0 points to the cuffed player's RootAttachment on their HRP
	local targetAttachment = cuffAlignPosition.Attachment0
	if not targetAttachment then return false end
	
	local targetHRP = targetAttachment.Parent
	if not targetHRP then return false end
	
	local targetCharacter = targetHRP.Parent
	if not targetCharacter then return false end
	
	local playerFromCharacter = Players:GetPlayerFromCharacter(targetCharacter)
	if not playerFromCharacter then return false end
	
	return playerFromCharacter == targetPlayer
end

function CuffHelper.LocalPlayerIsCuffing(localPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerIsValid, playerInvalidityReason = playerIsValidFn(localPlayer)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	local character = localPlayer.Character
	if not character then return false end
	
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	const cuffAlignPosition = humanoidRootPart:FindFirstChild("CuffAlignPosition")
	if not cuffAlignPosition then return false end
	
	const cuffAlignOrientation = humanoidRootPart:FindFirstChild("CuffAlignOrientation")
	if(not cuffAlignOrientation) then return false end
	
	return true
end



return CuffHelper
