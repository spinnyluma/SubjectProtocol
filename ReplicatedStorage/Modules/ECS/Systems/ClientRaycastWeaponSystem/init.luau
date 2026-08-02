local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientRaycastWeaponConfig = require(script.Config)
local WeaponDataConfig = require(ReplicatedStorage.Modules.Shared.Constants.WeaponDataConfig)

local InputSignals = require(ReplicatedStorage.Modules.ECS.Systems.InputSystem.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local CharacterHelper = require(ReplicatedStorage.Modules.Helpers.Character.CharacterHelper)
local RaycastParamsHelper = require(ReplicatedStorage.Modules.Helpers.SpatialQuery.RaycastParamsHelper)
local TableHelper = require(ReplicatedStorage.Modules.Helpers.Table.TableHelper)
local UiHelper = require(ReplicatedStorage.Modules.Helpers.UI.UiHelper)

local CombatService = require(ReplicatedStorage.Modules.Services.Combat.CombatService)

local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)
local Trove = require(ReplicatedStorage.Modules.Utilities.Trove)


local usingRaycastWeaponInputContext: InputContext = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon

local fireWeaponInputAction: InputAction = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon.FireWeapon

local tracerTemplate: Model = ReplicatedStorage.Assets.Ray.Templates.TracerTemplate

local raycastWeaponCursor = "rbxassetid://124821953531726"


local weaponTroves: {[Tool]: Trove.Trove} = {}


local fireRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.FireRay

local ClientRaycastWeaponSystem = {}

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
	
	
	
	local mouseLocation = UserInputService:GetMouseLocation()
	
	Promise.try(function()
		if(UserInputService.PreferredInput == Enum.PreferredInput.Touch) then
			local touchPositionInCoreGui = UiHelper.IsJoystickAtPosition(
				mouseLocation.X,
				mouseLocation.Y
			)
			if(touchPositionInCoreGui) then
				return
			end
		end
		local ray = currentCamera:ViewportPointToRay(
			mouseLocation.X,
			mouseLocation.Y)
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

		local raycastPacket: WeaponDataConfig.RaycastPacket = {
			Weapon = weapon,
			Origin = head.Position,
			Direction = realFiringRayDirection,
			EndPosition = realFiringEndPosition,
			InstanceHit = instanceHit
		}
		fireRayRE:FireServer(raycastPacket)
		return Promise.resolve()
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)

	
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
	
	local currentWeaponTrove: Trove.Trove = weaponTroves[weapon]
	
	currentWeaponTrove:Add(weapon.Equipped:Connect(function(_)
		UserInputService.MouseIcon = raycastWeaponCursor
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, true)

	end))
	
	currentWeaponTrove:Add(fireWeaponInputAction.Pressed:Connect(function(touch)
		FireRaycastWeaponFromMousePosition(weapon)
		
	end))
	
	currentWeaponTrove:Add(weapon.Unequipped:Connect(function()
		UserInputService.MouseIcon = ""
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, false)

	end))
	
	localPlayer.CharacterRemoving:Once(function()
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

function ClientRaycastWeaponSystem.Initialize()
	InitializeExistingRaycastWeapons()
	
	
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
end

return ClientRaycastWeaponSystem
