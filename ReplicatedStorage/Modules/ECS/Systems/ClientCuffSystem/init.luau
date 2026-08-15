const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities

const Promise = require(Utilities.Promise)

const AssertHelper = require("../../Helpers/Debug/AssertHelper")

const setupCuffConstraintRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SetupCuffConstraint

const Config = require(script.Config)

local ClientCuffSystem = {}

local function SpawnAlignPosition(cuffAttachment: Attachment, targetRootAttachment: Attachment, parentHRP: BasePart)
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "CuffAlignPosition"
	alignPosition.Attachment0 = targetRootAttachment
	alignPosition.Attachment1 = cuffAttachment
	alignPosition.MaxForce = 20_000
	alignPosition.Responsiveness = 50_000
	alignPosition.Parent = parentHRP
end

local function SpawnAlignOrientation(cuffAttachment: Attachment, targetRootAttachment: Attachment, parentHRP: BasePart)
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "CuffAlignOrientation"
	alignOrientation.Attachment0 = targetRootAttachment
	alignOrientation.Attachment1 = cuffAttachment
	alignOrientation.MaxTorque = 100_000
	alignOrientation.Responsiveness = 100_000
	alignOrientation.Parent = parentHRP
end

function ClientCuffSystem.Initialize()
	setupCuffConstraintRE.OnClientEvent:Connect(function(playerToCuff: Player, constraintType: string)
		if not playerToCuff then return end
		if not constraintType then return end
		
		local localPlayer = Players.LocalPlayer
		if not localPlayer then return end
		
		local localCharacter = localPlayer.Character
		if not localCharacter then return end
		
		local targetCharacter = playerToCuff.Character
		if not targetCharacter then return end
		
		local constraintConfig = Config.constraintTypes[constraintType]
		if not constraintConfig then return end
		
		Promise.try(function()
			local localHRP = localCharacter:WaitForChild("HumanoidRootPart")
			local targetHRP = targetCharacter:WaitForChild("HumanoidRootPart")
			local cuffAttachment = localHRP:WaitForChild("CuffAttachment")
			local targetRootAttachment = targetHRP:WaitForChild("RootAttachment")
			
			if constraintType == Config.constraintTypes.AlignPosition.Name then
				SpawnAlignPosition(cuffAttachment, targetRootAttachment, localHRP)
			elseif constraintType == Config.constraintTypes.AlignOrientation.Name then
				SpawnAlignOrientation(cuffAttachment, targetRootAttachment, localHRP)
			end
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
	end)
end

return ClientCuffSystem
