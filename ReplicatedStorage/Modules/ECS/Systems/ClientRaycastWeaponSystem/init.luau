local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

const Assets = ReplicatedStorage.Assets

const Shared = Assets.Shared

const Remotes = Shared.Remotes

const Events = Remotes.Events

const reloadWeaponRE = Events.ReloadWeapon

local RaycastParamsHelper = require(ReplicatedStorage.Modules.Helpers.SpatialQuery.RaycastParamsHelper)
local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local WeaponDataConfig = require(ReplicatedStorage.Modules.Shared.Constants.WeaponDataConfig)
local CharacterHelper = require(ReplicatedStorage.Modules.Helpers.Character.CharacterHelper)
local CombatService = require(ReplicatedStorage.Modules.Services.Combat.CombatService)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local InputSignals = require(ReplicatedStorage.Modules.ECS.Systems.InputSystem.Signals)
local TableHelper = require(ReplicatedStorage.Modules.Helpers.Table.TableHelper)
local UiHelper = require(ReplicatedStorage.Modules.Helpers.UI.UiHelper)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)
local Trove = require(ReplicatedStorage.Modules.Utilities.Trove)

local ClientRaycastWeaponConfig = require(script.Config)

const ClientSoundReplicationService = require("../../Services/SoundReplication/ClientSoundReplicationService")
const RaycastWeaponStateComponent = require("../Components/RaycastWeaponStateComponent")
const RaycastWeaponHelper = require("../../Helpers/RaycastWeapon/RaycastWeaponHelper")
const SystemManagerModule = require("../SystemManagerModule")
const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")
const TimeHelper = require("../../Helpers/Time/TimeHelper")
const RaycastWeaponStateComponentConfig = require("../Components/RaycastWeaponStateComponent/Config")
const t = require("../../Utilities/t")

local usingRaycastWeaponInputContext: InputContext = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon


local fireWeaponInputAction: InputAction = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon.FireWeapon
const reloadInputAction: InputAction = usingRaycastWeaponInputContext.Reload

const fireWeaponTouchBinding: InputBinding = fireWeaponInputAction.TouchBinding
const reloadTouchBinding: InputBinding = reloadInputAction.TouchBinding



local tracerTemplate: Model = ReplicatedStorage.Assets.Ray.Templates.TracerTemplate

local raycastWeaponCursor = "rbxassetid://124821953531726"


local weaponTroves: {[Tool]: Trove.Trove} = {}


local fireRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.FireRay

local ClientRaycastWeaponSystem = {}

local ammoScreenGui: ScreenGui? = nil
local mobileActionButtonsScreenGui: ScreenGui? = nil
local fireMobileButton: ImageButton? = nil
local reloadMobileButton: ImageButton? = nil
local crosshair: ImageLabel? = nil
local mobileCrosshairScreenGui: ScreenGui? = nil

local raycastWeaponLength = 500

local function FireRaycastWeaponFromMousePosition(weapon: Tool)
	local weaponIsValid = AssertHelper.InvalidArgAssert(
		typeof(weapon) == "Instance"
			and weapon:IsA("Tool"),
		weapon,
		"weapon",
		"FireRaycastWeapon",
		"Tool"
	)
	if(not weaponIsValid) then return end
	
	local currentCamera = workspace.CurrentCamera
	local currentCameraIsValid = AssertHelper.ExpectedValAssert(
		typeof(currentCamera) == "Instance"
			and currentCamera:IsA("Camera"),
		currentCamera,
		"currentCamera",
		"Camera"
	)
	if(not currentCameraIsValid) then return end
	
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	local playerCharacter = localPlayer.Character
	local playerCharacterIsValid = AssertHelper.ExpectedValAssert(
		typeof(playerCharacter) == "Instance"
		and playerCharacter:IsA("Model"),
		playerCharacter,
		"playerCharacter",
		"Model"
	)
	if(not playerCharacterIsValid) then return end
	
	local accessories: {BasePart?}?  = CharacterHelper.GetHatParts(playerCharacter)
	local accessoriesIsValid = AssertHelper.ExpectedValAssert(
		type(accessories) == "table",
		accessories,
		"accessories",
		"table"
	)
	if(not accessoriesIsValid) then return end
	
	
	local head: BasePart? = playerCharacter:FindFirstChild("Head")
	local headIsValid = AssertHelper.ExpectedValAssert(
		typeof(head) == "Instance"
			and head:IsA("BasePart"),
		head,
		"head",
		"BasePart"
	)
	if(not headIsValid) then return end
	
	local firePoint: BasePart? = weapon:FindFirstChild("FirePoint")
	local firePointIsValid = AssertHelper.ExpectedValAssert(
		typeof(firePoint) == "Instance"
			and firePoint:IsA("BasePart"),
		firePoint,
		"firePoint",
		"BasePart"
	)
	if(not firePointIsValid) then return end
	
	
	local rayLocation: Vector2? = nil
	
	Promise.try(function()
		if(UserInputService.PreferredInput == Enum.PreferredInput.Touch) then
			const imageLabelIsValidFn = t.instanceIsA("ImageLabel")
			const crosshairIsValid, crosshairInvalidReason = imageLabelIsValidFn(crosshair)
			if(not crosshairIsValid) then
				AssertHelper.Warn(crosshairInvalidReason)
				return
			end
			const dividedBy2AbsoluteSize = Vector2.new(
				crosshair.AbsoluteSize.X / 2,
				crosshair.AbsoluteSize.Y / 2
			)
			rayLocation = Vector2.new(
				crosshair.Position.X.Scale * currentCamera.ViewportSize.X,
				crosshair.Position.Y.Scale * currentCamera.ViewportSize.Y
			)

		elseif(UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse) then
			rayLocation = UserInputService:GetMouseLocation()
			print(rayLocation)

		end
		local ray = currentCamera:ViewportPointToRay(
			rayLocation.X,
			rayLocation.Y)
		local params: RaycastParams? = SpatialQueryConfig.GetRaycastParams(ClientRaycastWeaponConfig.SYSTEM_TAG_NAME, {
			["Self"] = weapon,
			["AdditionalInstances"] = accessories
		})

		local paramsIsValid = AssertHelper.ExpectedValAssert(
			typeof(params) == "RaycastParams",
			params,
			"params",
			"RaycastParams"
		)
		if(not paramsIsValid) then return end

		local rayResult: RaycastResult? = CombatService.FireRay(ray.Origin,
			ray.Direction * raycastWeaponLength,
			params)

		local endPosition: Vector3? = nil
		if(not rayResult) then
			endPosition = ray.Origin + ray.Direction * raycastWeaponLength
		else
			const highlight = Instance.new("Highlight")
			highlight.Parent = rayResult.Instance
			task.delay(1, function()
				highlight:Destroy()
			end)
			endPosition = rayResult.Position
		end
		
		local realFiringParams = RaycastParamsHelper.CloneRaycastParams(params)
		local realFiringParamsIsValid = AssertHelper.ExpectedValAssert(
			typeof(realFiringParams) == "RaycastParams",
			realFiringParams,
			"realFiringParams",
			"RaycastParams"
		)
		if(not realFiringParamsIsValid) then return end
		local newExcludeInstances: {Instance?}? = TableHelper.JoinTables({playerCharacter},
			realFiringParams.ExcludeInstances)
		local newExcludeInstancesIsValid = AssertHelper.ExpectedValAssert(
			type(newExcludeInstances) == "table",
			newExcludeInstances,
			"newExcludeInstances",
			"table"
		)
		if(not newExcludeInstancesIsValid) then return end
		realFiringParams.ExcludeInstances = newExcludeInstances
		local epsilon = 0.05
		local rayDirection = (endPosition - head.Position)
		local rayDirectionMagnitude = rayDirection.Magnitude
		local realFiringRayDirection = rayDirection.Unit * (rayDirectionMagnitude + epsilon)
		local realFiringRayResult: RaycastResult? = CombatService.FireRay(
			head.Position,
			realFiringRayDirection,
			realFiringParams
		)
		local realFiringEndPosition: Vector3? = nil
		local instanceHit: Instance? = nil
		if(not realFiringRayResult) then
			realFiringEndPosition = head.Position + realFiringRayDirection

		else
			realFiringEndPosition = realFiringRayResult.Position
			instanceHit = realFiringRayResult.Instance	
		end
		CombatService.GenerateRay(
			tracerTemplate,
			firePoint.Position,
			realFiringEndPosition,
			{Team = localPlayer.Team}
		)

		const shootStartTime = workspace:GetServerTimeNow()
		local raycastPacket: WeaponDataConfig.RaycastPacket = {
			Weapon = weapon,
			Origin = head.Position,
			Direction = realFiringRayDirection,
			EndPosition = realFiringEndPosition,
			InstanceHit = instanceHit,
			ShootStartTime = shootStartTime
		}
		ClientSoundReplicationService.PlaySoundFromPosition(head.Position, SoundConfig.clientSoundConfigs.Gun.PistolGunshot)
		fireRayRE:FireServer(raycastPacket)
		return Promise.resolve()
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)
end



local function InitializeAmmoUi(weapon: Tool)	
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return 
	end
	if not ammoScreenGui then return end
	ammoScreenGui.Enabled = true

	local background = ammoScreenGui:WaitForChild("Background")
	local innerBackground = background:WaitForChild("InnerBackground")
	local ammoContent = innerBackground:WaitForChild("AmmoContent")
	local textContainer = ammoContent:WaitForChild("TextContainer")
	local ammoLabel = textContainer:WaitForChild("AmmoLabel")
	
	local function updateAmmoText(weapon: Tool)
		const toolIsValidFn = t.instanceIsA("Tool")
		const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
		if(not weaponIsValid) then 
			AssertHelper.Warn(weaponInvalidReason)
			return 
		end

		local currentAmmo = weapon:GetAttribute("A_Ammo")
		local maxAmmo = weapon:GetAttribute("A_MaxAmmo")
		if currentAmmo ~= nil and maxAmmo ~= nil then
			ammoLabel.Text = `{currentAmmo}/{maxAmmo}`
		elseif currentAmmo ~= nil then
			ammoLabel.Text = tostring(currentAmmo)
		end
	end
	
	updateAmmoText(weapon)

	local currentWeaponTrove = weaponTroves[weapon]
	if currentWeaponTrove then
		currentWeaponTrove:Add(weapon:GetAttributeChangedSignal("A_Ammo"):Connect(function()
			updateAmmoText(weapon)
			
			const raycastWeaponStateComp: RaycastWeaponStateComponent.RaycastWeaponStateComponent = SystemManagerModule.GetComponentByEntity("RaycastWeaponState", weapon)
			const raycastWeaponStateCompIsValid, raycastWeaponStateCompInvalidReason = t.interface(RaycastWeaponStateComponent.interface)
			if(not raycastWeaponStateCompIsValid) then
				AssertHelper.Warn(raycastWeaponStateCompInvalidReason)
				return
			end
			
			const currentAmmo = weapon:GetAttribute("A_Ammo")
			const currentAmmoIsValid, currentAmmoInvalidReason = t.number(currentAmmo)
			if(not currentAmmoIsValid) then
				AssertHelper.Warn(currentAmmoInvalidReason)
				return
			end
			
			raycastWeaponStateComp.PredictedWeaponAmmo = currentAmmo
		end))
	end
end

local function DeinitializeAmmoUi()
	if not ammoScreenGui then return end
	ammoScreenGui.Enabled = false
end

const function DeinitializeRaycastWeapon(weapon: Tool)
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then
		AssertHelper.Warn(weaponInvalidReason)
		return
	end

	const currentWeaponTrove = weaponTroves[weapon]
	if(currentWeaponTrove) then
		currentWeaponTrove:Clean()
	end
	weaponTroves[weapon] = nil

	const raycastWeaponStateCompExists: boolean = SystemManagerModule.DoesEntityComponentExist("RaycastWeaponState", weapon)
	if(raycastWeaponStateCompExists) then
		SystemManagerModule.RemoveComponent("RaycastWeaponState", weapon)
	end
end

const function CleanupOnCharacterDeath()
	UserInputService.MouseIcon = ""
	InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, false)

	DeinitializeAmmoUi()

	if(mobileActionButtonsScreenGui) then
		mobileActionButtonsScreenGui.Enabled = false
		mobileCrosshairScreenGui.Enabled = false
	end

	const localPlayer = Players.LocalPlayer
	const localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end

	const selectorString = "." .. ClientRaycastWeaponConfig.SYSTEM_TAG_NAME

	const backpack = localPlayer.Backpack
	if(backpack) then
		const backpackWeapons: {Tool?} = backpack:QueryDescendants(selectorString)
		for _, weapon in backpackWeapons do
			DeinitializeRaycastWeapon(weapon)
		end
	end

	const playerCharacter = localPlayer.Character
	if(playerCharacter) then
		const characterWeapons: {Tool?} = playerCharacter:QueryDescendants(selectorString)
		for _, weapon in characterWeapons do
			DeinitializeRaycastWeapon(weapon)
		end
	end
end

const function BindDeathCleanupToHumanoid(player: Player)
	Promise.try(function()
		local character = player.Character
		if(not character) then
			character = player.CharacterAdded:Wait()
		end

		const humanoid = character:WaitForChild("Humanoid")
		const humanoidIsValid = AssertHelper.ExpectedValAssert(
			typeof(humanoid) == "Instance"
				and humanoid:IsA("Humanoid"),
			humanoid,
			"humanoid",
			"Humanoid"
		)
		if(not humanoidIsValid) then return end

		humanoid.Died:Connect(CleanupOnCharacterDeath)
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)
end

const function ReloadWeapon(weapon: Tool)
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return 
	end
	
	const ammo = weapon:GetAttribute("A_Ammo")
	const ammoIsValid, ammoInvalidReason = t.number(ammo)
	if(not ammoIsValid) then
		AssertHelper.Warn(ammoInvalidReason)
		return
	end
	
	const maxAmmo = weapon:GetAttribute("A_MaxAmmo")
	const maxAmmoIsValid, maxAmmoInvalidReason = t.number(maxAmmo)
	
	if(not maxAmmoIsValid) then
		AssertHelper.Warn(maxAmmoInvalidReason)
		return
	end
	
	
	if(ammo == maxAmmo) then return end
	
	const raycastWeaponStateComp: RaycastWeaponStateComponent.RaycastWeaponStateComponent? = SystemManagerModule.GetComponentByEntity("RaycastWeaponState", weapon)
	const raycastWeaponStateCompIsValid, raycastWeaponStateCompInvalidReason = t.table(raycastWeaponStateComp)
	if(not raycastWeaponStateCompIsValid) then
		AssertHelper.Warn(raycastWeaponStateCompInvalidReason)
		return
	end
	
	
	
	const weaponPivot = weapon:GetPivot()
	const weaponPosition = weaponPivot.Position
	
	const baseReloadSoundConfig = SoundConfig.clientSoundConfigs.Gun.PistolReload
	const baseReloadSoundConfigIsValid, baseReloadSoundConfigInvalidReason = t.table(baseReloadSoundConfig)
	if(not baseReloadSoundConfigIsValid) then
		AssertHelper.Warn(baseReloadSoundConfigInvalidReason)
		return
	end
	
	const reloadTime: number? = weapon:GetAttribute(ClientRaycastWeaponConfig.RELOAD_ATTR_NAME)
	const reloadTimeIsValid, reloadTimeInvalidReason = t.number(reloadTime)
	if(not reloadTimeIsValid) then
		AssertHelper.Warn(reloadTimeInvalidReason)
		return
	end
	
	Promise.try(function()
		raycastWeaponStateComp.WeaponState = RaycastWeaponStateComponentConfig.raycastWeaponStates.Reloading.Name
		TimeHelper.CreateCountdownInSeconds(reloadTime)
		raycastWeaponStateComp.WeaponState = RaycastWeaponStateComponentConfig.raycastWeaponStates.Idle.Name
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
	reloadWeaponRE:FireServer(weapon)
	ClientSoundReplicationService.PlaySoundFromPosition(weaponPosition, baseReloadSoundConfig)

end

local function InitializeRaycastWeapon(weapon: Tool)
	local weaponIsValid = AssertHelper.ExpectedValAssert(
		typeof(weapon) == "Instance",
		weapon,
		"weapon",
		"Instance"
	)
	if(not weaponIsValid) then return end
	
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	if(not weaponTroves[weapon]) then
		weaponTroves[weapon] = Trove.new()
	end
	
	const raycastWeaponStateCompExists = SystemManagerModule.DoesEntityComponentExist("RaycastWeaponState", weapon)
	local raycastWeaponStateComp: RaycastWeaponStateComponent.RaycastWeaponStateComponent? = nil
	if(not raycastWeaponStateCompExists) then
		raycastWeaponStateComp = SystemManagerModule.AddComponent("RaycastWeaponState", weapon)
	else
		raycastWeaponStateComp = SystemManagerModule.GetComponentByEntity("RaycastWeaponState", weapon)
		const inCooldown = raycastWeaponStateComp.InCooldown
		if(inCooldown) then
			return
		end
	end
	
	const raycastWeaponStateCompIsValid, raycastWeaponStateCompInvalidReason = t.table(raycastWeaponStateComp)
	if(not raycastWeaponStateCompIsValid) then
		AssertHelper.Warn(raycastWeaponStateCompInvalidReason)
		return
	end
	
	const ammoAttribute = weapon:GetAttribute("A_Ammo")
	const ammoAttributeIsValid, ammoAttributeInvalidReason = t.number(ammoAttribute)
	if(not ammoAttributeIsValid) then
		AssertHelper.Warn(ammoAttributeInvalidReason)
		return
	end
	raycastWeaponStateComp.PredictedWeaponAmmo = ammoAttribute 
	local currentWeaponTrove: Trove.Trove = weaponTroves[weapon]
	
	const weaponFireRate: number? = weapon:GetAttribute(ClientRaycastWeaponConfig.FIRE_RATE_ATTR_NAME)	
	const numberIsMin0Fn = t.numberMin(0)
	const weaponFireRateIsValid, weaponFireRateInvalidReason = numberIsMin0Fn(weaponFireRate)
	if(not weaponFireRateIsValid) then
		AssertHelper.Warn(weaponFireRateInvalidReason)
		return
	end
	
	currentWeaponTrove:Add(weapon.Equipped:Connect(function(_)
		UserInputService.MouseIcon = raycastWeaponCursor
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, true)
		const weaponHasAmmo: boolean = RaycastWeaponHelper.HasAmmoAttribute(weapon)
		
		if(weaponHasAmmo) then
			const screenGuiValidFn = t.instanceIsA("ScreenGui")
			const ammoScreenGuiIsValid, screenGuiInvalidReason = screenGuiValidFn(ammoScreenGui)
			if(not ammoScreenGuiIsValid) then
				AssertHelper.Warn(screenGuiInvalidReason)
			else
				Promise.try(function()
					InitializeAmmoUi(weapon)
				end)
					:catch(function(err)
						AssertHelper.Warn(tostring(err))
					end)

			end
		end
		

		if UserInputService.PreferredInput == Enum.PreferredInput.Touch and mobileActionButtonsScreenGui then
			mobileCrosshairScreenGui.Enabled = true
			mobileActionButtonsScreenGui.Enabled = true
		end
	end))
	currentWeaponTrove:Add(reloadInputAction.Pressed:Connect(function()
		const raycastWeaponStateComp: RaycastWeaponStateComponent.RaycastWeaponStateComponent? = SystemManagerModule.GetComponentByEntity("RaycastWeaponState", weapon)
		const raycastWeaponStateCompIsValid, weaponStateCompInvalidReason = t.table(raycastWeaponStateComp)
		if(not raycastWeaponStateCompIsValid) then
			AssertHelper.Warn(weaponStateCompInvalidReason)
			return
		end
		
		if(raycastWeaponStateComp.WeaponState ~= RaycastWeaponStateComponentConfig.raycastWeaponStates.Idle.Name) then return end
		ReloadWeapon(weapon)
	end))
	currentWeaponTrove:Add(fireWeaponInputAction.Pressed:Connect(function(touch)
		if(raycastWeaponStateComp.InCooldown) then return end
		const raycastWeaponStateComp: RaycastWeaponStateComponent.RaycastWeaponStateComponent? = SystemManagerModule.GetComponentByEntity("RaycastWeaponState", weapon)
		const raycastWeaponStateCompIsValid, weaponStateCompInvalidReason = t.table(raycastWeaponStateComp)
		if(not raycastWeaponStateCompIsValid) then
			AssertHelper.Warn(weaponStateCompInvalidReason)
			return
		end

		if(raycastWeaponStateComp.WeaponState ~= RaycastWeaponStateComponentConfig.raycastWeaponStates.Idle.Name) then return end
		raycastWeaponStateComp.InCooldown = true
		task.spawn(function()
			const endTime = workspace:GetServerTimeNow() + weaponFireRate
 			TimeHelper.CreateCountdownUntilServerEndTime(endTime)
			raycastWeaponStateComp.InCooldown = false
		end)
		
		if(raycastWeaponStateComp.PredictedWeaponAmmo <= 0) then return end
		raycastWeaponStateComp.PredictedWeaponAmmo -= 1
		FireRaycastWeaponFromMousePosition(weapon)
		
	end))
	
	currentWeaponTrove:Add(weapon.Unequipped:Connect(function()
		UserInputService.MouseIcon = ""
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, false)
		DeinitializeAmmoUi()
		
		if mobileActionButtonsScreenGui then
			mobileCrosshairScreenGui.Enabled = false
			mobileActionButtonsScreenGui.Enabled = false
		end
	end))
	
	localPlayer.CharacterRemoving:Once(function()
		if(not weaponTroves[weapon]) then return end
		weaponTroves[weapon]:Clean()
		
		weaponTroves[weapon] = nil
	end)
end

local function InitializeExistingRaycastWeapons()
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	local backpack = localPlayer.Backpack
	
	local selectorString = "." .. ClientRaycastWeaponConfig.SYSTEM_TAG_NAME
	local raycastWeapons: {Tool?} = backpack:QueryDescendants(selectorString)
	for _, weapon in raycastWeapons do
		InitializeRaycastWeapon(weapon)
	end
end

local function ToolMannedByWeapon(player: Player, weapon: Model)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"ToolMannedByWeapon",
		"Player"
	)
	if(not playerIsValid) then return end
	
	local weaponIsValid = AssertHelper.InvalidArgAssert(
		typeof(weapon) == "Instance"
			and weapon:IsA("Model"),
		weapon,
		"weapon",
		"ToolMannedByWeapon",
		"Model"
	)
	if(not weaponIsValid) then return end
	
	local toolOwnerCharacter: Model? = weapon.Parent 
	if(not toolOwnerCharacter) then return end
	
	
	local toolOwner = Players:GetPlayerFromCharacter(toolOwnerCharacter)
	
	local backpack = player.Backpack
	local weaponInBackpack = table.find(backpack:GetChildren(), weapon)
	return toolOwner == player
		or weaponInBackpack
		
end

const function InitializeUiElements()
	const localPlayer = Players.LocalPlayer
	const playerGui = localPlayer:WaitForChild("PlayerGui")
	
	ammoScreenGui = playerGui:WaitForChild("Ammo")
	mobileActionButtonsScreenGui = playerGui:WaitForChild("MobileActionButtons")
	fireMobileButton = mobileActionButtonsScreenGui:WaitForChild("ShootButton")
	reloadMobileButton = mobileActionButtonsScreenGui:WaitForChild("ReloadButton")
	
	mobileCrosshairScreenGui = playerGui:WaitForChild("MobileCrosshair")
	const crosshairContainer = mobileCrosshairScreenGui:WaitForChild("Container")
	crosshair = crosshairContainer:WaitForChild("Crosshair")
end

const function InitializeRaycastMobileActionButtons()
	const buttonIsValidFn = t.instanceIsA("ImageButton")
	const fireButtonIsValid, fireButtonInvalidReason = buttonIsValidFn(fireMobileButton)
	
	if(not fireButtonIsValid) then
		AssertHelper.Warn(fireButtonInvalidReason)
		return
	end
	
	const reloadButtonIsValid, reloadButtonInvalidReason = buttonIsValidFn(reloadMobileButton)
	if(not reloadButtonIsValid) then
		AssertHelper.Warn(reloadButtonInvalidReason)
		return
	end
	fireWeaponTouchBinding.UIButton = fireMobileButton
	reloadTouchBinding.UIButton = reloadMobileButton
end


function ClientRaycastWeaponSystem.Initialize()
	Promise.try(function()
		InitializeUiElements()
		InitializeRaycastMobileActionButtons()
		InitializeExistingRaycastWeapons()

		const localPlayer = Players.LocalPlayer
		const localPlayerIsValid = AssertHelper.ExpectedValAssert(
			typeof(localPlayer) == "Instance"
				and localPlayer:IsA("Player"),
			localPlayer,
			"localPlayer",
			"Player"
		)
		if(localPlayerIsValid) then
			BindDeathCleanupToHumanoid(localPlayer)

			localPlayer.CharacterAdded:Connect(function(_)
				BindDeathCleanupToHumanoid(localPlayer)
			end)
		end

		CollectionService:GetInstanceAddedSignal(ClientRaycastWeaponConfig.SYSTEM_TAG_NAME):Connect(function(instance: Instance)
			if(not instance:IsA("Tool")) then
				return
			end

			local localPlayer = Players.LocalPlayer
			local localPlayerIsValid = AssertHelper.ExpectedValAssert(
				typeof(localPlayer) == "Instance"
					and localPlayer:IsA("Player"),
				localPlayer,
				"localPlayer",
				"Player"
			)
			if(not localPlayerIsValid) then return end
			local toolHeldByLocalPlayer: boolean? = ToolMannedByWeapon(localPlayer, instance)
			if(not toolHeldByLocalPlayer) then return end
			InitializeRaycastWeapon(instance)
		end)
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
end

return ClientRaycastWeaponSystem
