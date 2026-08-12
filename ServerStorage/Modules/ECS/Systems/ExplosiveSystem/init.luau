const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Services = Modules.Services
const Helpers = Modules.Helpers

const VFX = Services.VFX

const Debug = Helpers.Debug
const Time = Helpers.Time

const AssertHelper = require(Debug.AssertHelper)
const TimeHelper = require(Time.TimeHelper)
const VfxService = require(VFX.VfxService)

const ExplosiveSystemConfig = require("@self/Config")
const AreaDamageService = require("../../Services/Area/AreaDamageService")

local ExplosiveSystem = {}

const BLAST_PRESSURE = 500_000
const BLAST_RADIUS = 15
const DETONATION_TIME = 3

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
	const primaryPartIsValid = AssertHelper.InvalidArgAssert(
		typeof(primaryPart) == "Instance"
			and primaryPart:IsA("BasePart"),
		primaryPart,
		"primaryPart",
		"ExplosiveSystem.Initialize",
		"BasePart"
	)
	if(not primaryPartIsValid) then return end
	VfxService.SpawnExplosion({
		Position = primaryPart.Position,
		BlastPressure = BLAST_PRESSURE,
		BlastRadius = BLAST_RADIUS,
		DestroyJointRadiusPercent = 0,
		ExplosionType = Enum.ExplosionType.NoCraters,
		TimeScale = 1,
		Visible = true
	})
	AreaDamageService.DamageCharacterInRadiusFalloff(chara)
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
