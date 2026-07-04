local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaycastWeaponConfig = require(script.Config)

local InputSignals = require(ReplicatedStorage.Modules.ECS.Systems.InputSystem.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local CombatService = require(ReplicatedStorage.Modules.Services.Combat.CombatService)

local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local usingRaycastWeaponInputContext: InputContext = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon

local fireWeaponInputAction: InputAction = ReplicatedStorage.Assets.Input.Contexts.UsingRaycastWeapon.FireWeapon

local raycastWeaponCursor = "rbxassetid://124821953531726"

local RaycastWeaponSystem = {}

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
	
	local head: BasePart? = playerCharacter:FindFirstChild("Head")
	local headIsValid = AssertHelper.ExpectedValAssert(
		typeof(head) == "Instance"
			and head:IsA("BasePart"),
		head,
		"head",
		"BasePart"
	)
	if(not headIsValid) then return end
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = currentCamera:ViewportPointToRay(
		mouseLocation.X,
		mouseLocation.Y)
	
	local params = SpatialQueryConfig.GetRaycastParams(RaycastWeaponConfig.SYSTEM_TAG_NAME, {
		["Self"] = weapon
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
	
	
	local realFiringRayDirection = (endPosition - head.Position).Unit
	local realFiringRayResult: RaycastResult? = CombatService.FireRay(
		head.Position,
		realFiringRayDirection * raycastWeaponLength,
		params
	)
	
end

local function InitializeRaycastWeapon(weapon: Tool)
	local weaponIsValid = AssertHelper.ExpectedValAssert(
		typeof(weapon) == "Instance",
		weapon,
		"weapon",
		"Instance"
	)
	if(not weaponIsValid) then return end
	
	
	weapon.Equipped:Connect(function(_)
		UserInputService.MouseIcon = raycastWeaponCursor
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, true)
		
	end)
	fireWeaponInputAction.Pressed:Connect(function()
		FireRaycastWeaponFromMousePosition(weapon)
		
	end)
	weapon.Unequipped:Connect(function()
		UserInputService.MouseIcon = ""
		InputSignals.InputContextEnabledChanged:Fire(usingRaycastWeaponInputContext, false)

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
	
	local selectorString = "." .. RaycastWeaponConfig.SYSTEM_TAG_NAME
	local raycastWeapons: {Tool?} = backpack:QueryDescendants(selectorString)
	
	for _, weapon in raycastWeapons do
		InitializeRaycastWeapon(weapon)
	end	
end

function RaycastWeaponSystem.Initialize()
	InitializeExistingRaycastWeapons()
	
	
	CollectionService:GetInstanceAddedSignal(RaycastWeaponConfig.SYSTEM_TAG_NAME):Connect(function(instance: Instance)
		if(not instance:IsA("Tool")) then
			return
		end
		print("here")
		
		InitializeRaycastWeapon(instance)
	end)
end

return RaycastWeaponSystem
