local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = require(ReplicatedStorage.Modules.Utilities.t)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ClientCuffHelper = {}

function ClientCuffHelper.LocalPlayerIsCuffingPlayer(localPlayer: Player, targetPlayer: Player)
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

function ClientCuffHelper.LocalPlayerIsCuffing(localPlayer: Player)
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



function ClientCuffHelper.LocalPlayerIsCuffingPlayerByAttachments(localPlayer: Player, targetPlayer: Player)
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

	local localCharacter = localPlayer.Character
	if not localCharacter then return false end

	local localHumanoidRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localHumanoidRootPart then return false end

	local cuffAlignPosition = localHumanoidRootPart:FindFirstChild("CuffAlignPosition")
	if not cuffAlignPosition then return false end

	local cuffAlignOrientation = localHumanoidRootPart:FindFirstChild("CuffAlignOrientation")
	if not cuffAlignOrientation then return false end

	local targetCharacter = targetPlayer.Character
	if not targetCharacter then return false end

	local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not targetHumanoidRootPart then return false end

	local targetRootAttachment = targetHumanoidRootPart:FindFirstChild("RootAttachment")
	if not targetRootAttachment then return false end

	local alignPositionAttachment0 = cuffAlignPosition.Attachment0
	local alignOrientationAttachment0 = cuffAlignOrientation.Attachment0

	if not alignPositionAttachment0 or not alignOrientationAttachment0 then
		return false
	end

	return alignPositionAttachment0 == targetRootAttachment and alignOrientationAttachment0 == targetRootAttachment
end

return ClientCuffHelper
