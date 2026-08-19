const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Debug = Helpers.Debug
const Table = Helpers.Table
const Time = Helpers.Time

const Constants = Shared.Constants
const Packages = Shared.Packages

const Sound = Constants.Sound

const ReplicaShared = Packages.ReplicaShared

const DictionaryHelper = require(Table.DictionaryHelper)
const AssertHelper = require(Debug.AssertHelper)
const SoundConfig = require(Sound.SoundConfig)
const TableHelper = require(Table.TableHelper)
const ModeConfig = require(Constants.ModeConfig)
const TimeHelper = require(Time.TimeHelper)

const SoundReplicatoinSystemConfig = require("./SoundReplicationSystem/Config")
const SoundReplicationService = require("../../Services/Sound/SoundReplicationService")
const WeaponPortSystemConfig = require("@self/Config")
const FacilityModeSignals = require("./FacilityModeSystem/Signals")

const grenade = ServerStorage.Assets.Explosives.Grenades.Grenade

local WeaponPortSystem = {}



local modeActive = false
const minimumRandomSpawnDelay = 5
const maximumRandomSpawnDelay = 8
const baseLaunchSpeed = 10
const minimumLaunchMult = 0.5
const maximumLaunchMult = 1.15

const weaponSpawnThreads: {[Model]: {[string]: {thread}}} = {}




const function LaunchWeaponFromAttachment(weapon: Model, attachment: Attachment)
	const weaponIsValid = AssertHelper.InvalidArgAssert(
		typeof(weapon) == "Instance"
		and weapon:IsA("Model"),
		weapon,
		"weapon",
		"WeaponPortSystem.LaunchWeaponFromAttachment",
		"Model"
	)
	if(not weaponIsValid) then return end
	
	const attachmentIsValid = AssertHelper.InvalidArgAssert(
		typeof(attachment) == "Instance"
		and attachment:IsA("Attachment"),
		attachment,
		"attachment",
		"WeaponPortSystem.LaunchWeaponFromAttachment",
		"Attachment"
	)
	if(not attachmentIsValid) then return end
	
	const primaryPart = weapon.PrimaryPart
	const primaryPartIsValid = AssertHelper.ExpectedValAssert(
		typeof(primaryPart) == "Instance"
		and primaryPart:IsA("BasePart"),
		primaryPart,
		"primaryPart",
		"WeaponPortSystem.LaunchWeaponFromAttachment",
		"BasePart"
	)
	if(not primaryPartIsValid) then return end
	
	const random = Random.new()
	
	const speed = baseLaunchSpeed * random:NextNumber(minimumLaunchMult, maximumLaunchMult)
	const attachmentForwardVector = attachment.WorldCFrame.LookVector
	const impulse = attachmentForwardVector * speed
	primaryPart:ApplyImpulse(impulse)
end

local function AddThreadToWeaponSpawnThreads(weaponPort: Model,
	weaponSpawnType: string,
	thread: thread
)
	local weaponPortIsValid = AssertHelper.InvalidArgAssert(
		typeof(weaponPort) == "Instance"
		and weaponPort:IsA("Model"),
		weaponPort,
		"weapon",
		"WeaponPortSystem.AddThreadToWeaponSpawnThreads",
		"Model"
	)
	if(not weaponPortIsValid) then return end
	
	local weaponSpawnTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(weaponSpawnType) == "string",
		weaponSpawnType,
		"weaponSpawnType",
		"WeaponPortSystem.AddThreadToWeaponSpawnThreads",
		"string"
	)
	if(not weaponSpawnTypeIsValid) then return end
	
	local threadIsValid = AssertHelper.InvalidArgAssert(
		typeof(thread) == "thread",
		thread,
		"thread",
		"WeaponPortSystem.AddThreadToWeaponSpawnThreads",
		"thread"
	)
	if(not threadIsValid) then return end
	
	if(not weaponSpawnThreads[weaponPort]) then
		weaponSpawnThreads[weaponPort] = {}
	end
	
	if(not weaponSpawnThreads[weaponPort][weaponSpawnType]) then
		weaponSpawnThreads[weaponPort][weaponSpawnType] = {}
	end
	table.insert(weaponSpawnThreads[weaponPort][weaponSpawnType], thread)
end

local function RemoveThreadFromWeaponSpawnThreads(weaponPort: Model,
	weaponSpawnType: string,
	thread
)
	local weaponPortIsValid = AssertHelper.InvalidArgAssert(
		typeof(weaponPort) == "Instance"
		and weaponPort:IsA("Model"),
		weaponPort,
		"weapon",
		"WeaponPortSystem.RemoveThreadFromWeaponSpawnThreads",
		"Model"
	)
	if(not weaponPortIsValid) then return end
	
	local weaponSpawnTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(weaponSpawnType) == "string",
		weaponSpawnType,
		"weaponSpawnType",
		"WeaponPortSystem.RemoveThreadFromWeaponSpawnThreads",
		"string"
	)
	if(not weaponSpawnTypeIsValid) then return end
	
	local threadIsValid = AssertHelper.InvalidArgAssert(
		typeof(thread) == "thread",
		thread,
		"thread",
		"WeaponPortSystem.RemoveThreadFromWeaponSpawnThreads",
		"thread"
	)
	if(not threadIsValid) then return end
	
	if(not weaponSpawnThreads[weaponPort]) then
		return
	end
	
	if(not weaponSpawnThreads[weaponPort][weaponSpawnType]) then
		return
	end
	const weaponSpawnThreadIndex = table.find(weaponSpawnThreads[weaponPort][weaponSpawnType], thread)
	if(not weaponSpawnThreadIndex) then return end
	local foundThread = weaponSpawnThreads[weaponPort][weaponSpawnType][weaponSpawnThreadIndex]
	if(not foundThread) then return end
	
	-- Only cancel if it's not the currently running thread
	if(foundThread ~= coroutine.running()) then
		task.cancel(foundThread)
	end
	
	table.remove(weaponSpawnThreads[weaponPort][weaponSpawnType], weaponSpawnThreadIndex)
	
	if(#weaponSpawnThreads[weaponPort][weaponSpawnType] == 0) then
		weaponSpawnThreads[weaponPort][weaponSpawnType] = nil
	end
	
	const weaponSpawnTypesDictLen = DictionaryHelper.GetLengthOfDictionary(weaponSpawnThreads[weaponPort])
	if(weaponSpawnTypesDictLen == 0) then
		weaponSpawnThreads[weaponPort] = nil
	end
	
end

local function PlayThrowSoundEffect(emittingPart: BasePart)
	const throwSoundEffect: SoundConfig.SoundConfig = {
		EmittingPart = emittingPart,
		SoundId = SoundReplicatoinSystemConfig.sounds.ThrowSound.SoundId,
		RollOffMaxDistance = 125,
		RollOffMinDistance = 10,
		Volume = 0.5
	}
	SoundReplicationService.ReplicateSound(Players:GetPlayers(), throwSoundEffect)
end

local function InitializeWeaponPortSpawning()
	const weaponPorts = CollectionService:GetTagged(WeaponPortSystemConfig.SYSTEM_TAG_NAME)
	
	modeActive = true
	
	for _, port in weaponPorts do
		task.spawn(function()
			while modeActive do
				local spawnDelay = math.random(minimumRandomSpawnDelay, maximumRandomSpawnDelay)
				local weaponSpawnThread: thread? = nil
				weaponSpawnThread = task.delay(spawnDelay, function()
					const weaponPortAttachments = port.WeaponPortAttachments
					local weaponPortAttachmentIsValid = AssertHelper.ExpectedValAssert(
						typeof(weaponPortAttachments) == "Instance"
							and weaponPortAttachments:IsA("Folder"),
						weaponPortAttachments,
						"weaponPortAttachments",
						"WeaponPortSystem.InitializeWeaponPortSpawning",
						"Folder"
					)
					if(not weaponPortAttachmentIsValid) then return end

					local weaponPortAttach: Attachment? = weaponPortAttachments.WeaponPortAttachment
					if(not weaponPortAttach) then return end

					const clonedGrenade = grenade:Clone()
					clonedGrenade.Parent = workspace
					clonedGrenade:PivotTo(weaponPortAttach.WorldCFrame)
					
					const portPrimPart = port.PrimaryPart
					
					if(portPrimPart) then
						PlayThrowSoundEffect(portPrimPart)
					end
					LaunchWeaponFromAttachment(clonedGrenade, weaponPortAttach)
					if(not weaponSpawnThread) then return end
					RemoveThreadFromWeaponSpawnThreads(port, grenade.Name, weaponSpawnThread)
				end)
				AddThreadToWeaponSpawnThreads(port, grenade.Name, weaponSpawnThread)
				
				TimeHelper.CreateCountdownInSeconds(spawnDelay)

			end
		end)
		
	end
end

local function RemoveAllThreadsFromWeaponSpawnThreads()
	for weaponPort, weaponSpawnType in weaponSpawnThreads do
		for weaponSpawnType, spawnThreads in weaponSpawnType do
			for i = #spawnThreads, 1, -1 do
				local thread = spawnThreads[i]
				RemoveThreadFromWeaponSpawnThreads(weaponPort, weaponSpawnType, thread)
			end		
		end
	end
			
end
function WeaponPortSystem.Initialize()
	--InitializeWeaponPortSpawning()
	FacilityModeSignals.ModeChanged:Connect(function(newMode: ModeConfig.Mode, oldMode: ModeConfig.Mode)
		if(newMode == ModeConfig.modes.FacilityBombardment.Name) then
			InitializeWeaponPortSpawning()
		else
			modeActive = false
			RemoveAllThreadsFromWeaponSpawnThreads()
		end
	end)
end

return WeaponPortSystem
