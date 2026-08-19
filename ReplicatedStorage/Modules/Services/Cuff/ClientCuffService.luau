const Players = game:GetService("Players")

const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const t = require("../../Utilities/t")
const Promise = require("../../Utilities/Promise")
const SystemManagerModule = require("../../ECS/SystemManagerModule")
const CuffStateComponent = require("../../ECS/Components/CuffStateComponent")
const ClientCuffSystemSignals = require("../../ECS/Systems/ClientCuffSystem/Signals")

local ClientCuffService = {}

function ClientCuffService.RemoveCuffConstraints(localPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")

	local playerIsValid, playerInvalidityReason = playerIsValidFn(localPlayer)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	local character = localPlayer.Character
	if not character then return false end

	Promise.try(function()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		if not humanoidRootPart then return false end

		local cuffAlignPosition = humanoidRootPart:FindFirstChild("CuffAlignPosition")
		if not cuffAlignPosition then return false end

		local cuffAlignOrientation = humanoidRootPart:FindFirstChild("CuffAlignOrientation")
		if(not cuffAlignOrientation) then return false end

		cuffAlignPosition:Destroy()
		cuffAlignOrientation:Destroy()
	end)
end

function ClientCuffService.SetCuffState(newCuffState: string)
	const newCuffStateIsValid, newCuffStateInvalidityReason = t.string(newCuffState)
	if not newCuffState then
		AssertHelper.Warn(newCuffStateInvalidityReason)
		return
	end

	const localPlayer = Players.LocalPlayer
	if not localPlayer then return end

	const cuffStateComp: CuffStateComponent.CuffStateComponent? = SystemManagerModule.GetComponentByEntity("CuffState", localPlayer)
	const cuffStateCompIsValid, cuffStateCompInvalidityReason = t.table(cuffStateComp)
	if not cuffStateCompIsValid then
		AssertHelper.Warn(cuffStateCompInvalidityReason)
		return
	end
	const oldCuffState = cuffStateComp.CuffState
	cuffStateComp.CuffState = newCuffState
	if(oldCuffState ~= cuffStateComp.CuffState) then
		ClientCuffSystemSignals.CuffStateChanged:Fire(newCuffState, cuffStateComp.CuffState)
	end
end

return ClientCuffService
