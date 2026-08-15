local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Modules.Utilities.t)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local NetworkService = {}

function NetworkService.SetPlayerNetworkOwnership(player: Player)
	local playerIsValidFn = t.instanceIsA("Player")
	local playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	local character = player.Character
	if not character then
		AssertHelper.Warn("[NetworkService] Player has no character to set network ownership on.")
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		AssertHelper.Warn("[NetworkService] Character has no HumanoidRootPart.")
		return false
	end

	local hrpIsValidFn = t.instanceIsA("BasePart")
	local hrpIsValid, hrpInvalidityReason = hrpIsValidFn(hrp)
	if not hrpIsValid then
		AssertHelper.Warn(hrpInvalidityReason)
		return false
	end

	hrp:SetNetworkOwner(player)

	return true
end

return NetworkService
