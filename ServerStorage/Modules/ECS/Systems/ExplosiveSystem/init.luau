const CollectionService = game:GetService("CollectionService")
const ControllerService = game:GetService("ControllerService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Services = Modules.Services
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const VFX = Services.VFX

const Debug = Helpers.Debug
const Time = Helpers.Time

const Constants = Shared.Constants

const Sound = Constants.Sound

const AssertHelper = require(Debug.AssertHelper)
const SoundConfig = require(Sound.SoundConfig)
const ModeConfig = require(Constants.ModeConfig)
const TimeHelper = require(Time.TimeHelper)
const VfxService = require(VFX.VfxService)
const t = require(Utilities.t)

const SoundReplicationSystemConfig = require("./SoundReplicationSystem/Config")
const SoundReplicationService = require("../../Services/Sound/SoundReplicationService")
const ExplosiveSystemConfig = require("@self/Config")
const FacilityModeSignals = require("./FacilityModeSystem/Signals")
const AreaDamageService = require("../../Services/Area/AreaDamageService")

local ExplosiveSystem = {}

const BLAST_PRESSURE = 500_000
const BLAST_RADIUS = 19
const DAMAGE_RADIUS = 20
const DETONATION_TIME = 3

const GRENADE_DAMAGE = 90

local function ExplodeExplosive(explosive: Model)
	const explosiveIsValid = AssertHelper.InvalidArgAssert(
		typeof(explosive) == "Instance"
			and explosive:IsA("Model")
		and CollectionService:HasTag(explosive, ExplosiveSystemConfig.SYSTEM_TAG_NAME),
		explosive,
		"explosive",
		"ExplosiveSystem.ExplodeExplosive",
		"Model"
	)
	if(not explosiveIsValid) then return end
	
	const primaryPart = explosive.PrimaryPart
	
	const primPartIsValidFn = t.instanceIsA("BasePart")
	
	const primPartIsValid, _ = primPartIsValidFn(primaryPart)
	if(not primPartIsValid) then explosive:Destroy() return end
	VfxService.SpawnExplosion({
		Position = primaryPart.Position,
		BlastPressure = BLAST_PRESSURE,
		BlastRadius = BLAST_RADIUS,
		DestroyJointRadiusPercent = 0,
		ExplosionType = Enum.ExplosionType.NoCraters,
		TimeScale = 1,
		Visible = true
	})
	AreaDamageService.DamageCharacterInRadiusFalloff(
		primaryPart.Position,
		GRENADE_DAMAGE,
		5.5,
		DAMAGE_RADIUS
	)
	SoundReplicationService.ReplicateSound(Players:GetPlayers(),
		{
			SoundId = SoundReplicationSystemConfig.sounds.ExplosionSound1.SoundId,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 200,
			EmittingPosition =  primaryPart.Position
		}
	)
	explosive:Destroy()
end
local function InitializeExplosiveHandlers()
	const explosives = CollectionService:GetTagged(ExplosiveSystemConfig.SYSTEM_TAG_NAME)
	
	for _, explosive in explosives do
		if(not explosive:IsDescendantOf(workspace)) then continue end
		
		task.spawn(function()
			TimeHelper.CreateCountdownInSeconds(DETONATION_TIME)
			ExplodeExplosive(explosive)
		end)
		
	end
	
	CollectionService:GetInstanceAddedSignal(ExplosiveSystemConfig.SYSTEM_TAG_NAME):Connect(function(instance: Instance)
		if(not instance:IsDescendantOf(workspace)) then return end
		
		task.spawn(function()
			TimeHelper.CreateCountdownInSeconds(DETONATION_TIME)
			ExplodeExplosive(instance)
		end)
	end)
end

function ExplosiveSystem.Initialize()
	
	InitializeExplosiveHandlers()
end

return ExplosiveSystem
