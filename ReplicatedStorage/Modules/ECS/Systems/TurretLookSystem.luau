local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local replicateTurretRotationRE = ReplicatedStorage
	.Assets
	.Shared
	.Remotes
	.Events
	.ReplicateTurretRotation
local turretRotationTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local TurretLookSystem = {}

local function OrientTurretToCframe(turret: Model, rayIntersection: Vector3)
	local turretIsValid = AssertHelper.InvalidArgAssert(
		typeof(turret) == "Instance"
		and turret:IsA("Model"),
		turret,
		"turret",
		"TweenTurretToCframe",
		"Model"
	)
	if(not turretIsValid) then return end
	local rayIntersectionIsValid = AssertHelper.InvalidArgAssert(
		typeof(rayIntersection) == "Vector3",
		rayIntersection,
		"rayIntersection",
		"TweenTurretToCframe",
		"Vector3"
	)
	if(not rayIntersectionIsValid) then return end
	
	
	local primaryPart = turret.PrimaryPart
	local primaryPartIsValid = AssertHelper.ExpectedValAssert(
		typeof(primaryPart) == "Instance"
		and primaryPart:IsA("BasePart"),
		primaryPart,
		"primaryPart",
		"TweenTurretToCframe",
		"BasePart"
	)
	if(not primaryPartIsValid) then return end
	
	local lookAtCframe = CFrame.lookAt(primaryPart.Position, rayIntersection)
		* CFrame.Angles(0, math.rad(-90), 0)
	local tween = TweenService:Create(primaryPart,
		turretRotationTweenInfo,
		{
			CFrame = lookAtCframe
		}
	)
	tween:Play()
end

function TurretLookSystem.Initialize()
	replicateTurretRotationRE.OnClientEvent:Connect(function(turret: Model, rayIntersection: Vector3)
		OrientTurretToCframe(turret, rayIntersection)
	end)
end

return TurretLookSystem
