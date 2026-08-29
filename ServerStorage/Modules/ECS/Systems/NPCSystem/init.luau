const ReplicatedStorage = game:GetService("ReplicatedStorage")
const t = require(ReplicatedStorage.Modules.Utilities.t)
const AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const NPCConfig = require("@self/Config")

local NPCSystem = {}

const function InitializeStaticNpc()
	for _, obj in workspace:GetDescendants() do
		if not obj:IsA("Model") then continue end
		if obj:GetAttribute(NPCConfig.NPC_TYPE_ATTR_NAME) ~= NPCConfig.npcTypes.Static.Name then continue end

		const npcIsValidFn = t.instanceIsA("Model")
		const npcIsValid, npcInvalidityReason = npcIsValidFn(obj)
		if(not npcIsValid) then
			AssertHelper.Warn(npcInvalidityReason)
			continue
		end

		local humanoid = obj:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			AssertHelper.Warn("[NPCSystem] No Humanoid found in npc: " .. obj.Name)
			continue
		end

		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge

		local forceField = Instance.new("ForceField")
		forceField.Visible = false
		forceField.Parent = obj

		humanoid.HealthChanged:Connect(function()
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end
end

function NPCSystem.Initialize()
	InitializeStaticNpc()
end

return NPCSystem
