const CollectionService = game:GetService("CollectionService")
const ServerStorage = game:GetService("ServerStorage")
const Lighting = game:GetService("Lighting")

const ClientSoundReplicationService = require("../../Services/SoundReplication/ClientSoundReplicationService")
const ClientReplicaConfig = require("../../Shared/Constants/ClientReplicaConfig")
const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")
const Replica = require("../../Utilities/ReplicaClient")

--const FacilityModeSystemSignals = require(Systems.FacilityModeSystem.Signals)

const ExtendedTweenService = require("../../Services/Tween/ExtendedTweenService")
const SirenLightSystemConfig = require("@self/Config")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const ModeConfig = require("../../Shared/Constants/ModeConfig")
const Promise = require("../../Utilities/Promise")
const Maid = require("../../Shared/Packages/ReplicaShared/Maid")
const t = require("../../Utilities/t")

local SirenLightSystem = {}

const sirenLightSpinTweenInfo = TweenInfo.new(
	1.5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	-1
)

const sirenTweens: {Tween?} = {}
const soundAttachments: {Attachment?} = {}

local sirenAddedConn: RBXScriptConnection? = nil

local function SetSirenLightsState(state: boolean)
	const stateIsValid, stateInvalidityReason = t.boolean(state)
	if(not stateIsValid) then return end
	const sirenLights = CollectionService:GetTagged(SirenLightSystemConfig.SYSTEM_TAG_NAME)

	if(state) then
		for _, sirenLight in sirenLights do
			Promise.try(function()
				const sirenBody: BasePart = sirenLight:WaitForChild("SirenBody")
				const lightPart: BasePart = sirenLight:WaitForChild("LightPart")
				const spotLight: SpotLight = lightPart:WaitForChild("SpotLight")
				const lightPart2: BasePart = sirenLight:WaitForChild("LightPart2")
				const spotLight2: SpotLight = lightPart2:WaitForChild("SpotLight")
				const sirenBodyPosition = sirenBody.CFrame.Position
				const soundAttachment = ClientSoundReplicationService.PlaySoundFromPosition(
					sirenBodyPosition,
					SoundConfig.clientSoundConfigs.Environment.Siren
				)
				const newTween = ExtendedTweenService.Spin(sirenBody, sirenLightSpinTweenInfo)
				if(newTween) then
					table.insert(sirenTweens, newTween)
				end
				
				if(soundAttachment) then
					table.insert(soundAttachments, soundAttachment)
				end
				
				spotLight.Enabled = state
				spotLight2.Enabled = state
			end)
				:catch(function(err)
					AssertHelper.Warn(tostring(err))
				end)
		end
		if(sirenAddedConn) then
			sirenAddedConn:Disconnect()
		end
		
		sirenAddedConn = CollectionService:GetInstanceAddedSignal(SirenLightSystemConfig.SYSTEM_TAG_NAME):Connect(function(instance: Instance)
			Promise.try(function()
				const sirenBody = instance:WaitForChild("SirenBody")

				ExtendedTweenService.Spin(sirenBody, sirenLightSpinTweenInfo)
			end)
				:catch(function(err)
					AssertHelper.Warn(err)
				end)
		end)
	else
		if(sirenAddedConn) then
			sirenAddedConn:Disconnect()
		end
		Promise.try(function()
			for _, sirenLight in sirenLights do
				const lightPart: BasePart = sirenLight:WaitForChild("LightPart")
				local lightPart2: BasePart = sirenLight:WaitForChild("LightPart2")
				const spotLight: SpotLight = lightPart:WaitForChild("SpotLight")
				const spotLight2: SpotLight = lightPart2:WaitForChild("SpotLight")
				spotLight.Enabled = state
				spotLight2.Enabled = state
			end
			
			
			for _, tween in sirenTweens do
				tween:Cancel()
				tween:Destroy()
			end
			
			for _, attachment in soundAttachments do
				attachment:Destroy()
				
			end

			table.clear(sirenTweens)
			table.clear(soundAttachments)
		end)			
	end
end

function SirenLightSystem.Initialize()
	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.CurrentMode.Name, function(replica: Replica.Replica)
		const replicaData = replica.Data
		const currentMode = replicaData.CurrentMode
		if(currentMode ~= ModeConfig.modes.Idle.Name) then
			SetSirenLightsState(true)
		else
			SetSirenLightsState(false)
		end		
		
		replica:OnSet({"CurrentMode"}, function(newValue: ModeConfig.Mode, oldValue: ModeConfig.Mode)
			if(newValue ~= ModeConfig.modes.Idle.Name) then
				SetSirenLightsState(true)
			else
				SetSirenLightsState(false)
			end			
		end)
	end)
	--FacilityModeSystemSignals.ModeChanged:Connect(function(newMode: ModeConfig.Mode, oldMode: ModeConfig.Mode)
	--	if(newMode ~= ModeConfig.modes.Idle.Name) then
			
	--	end
	--end)
end


return SirenLightSystem
