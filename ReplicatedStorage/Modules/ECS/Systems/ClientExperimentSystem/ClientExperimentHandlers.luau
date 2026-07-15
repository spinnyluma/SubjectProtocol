local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ClientExperimentHandlers = {}

local function ApplyClientSlide()
	local currentVelocity = Vector3.zero
	
	local localPlayer = game.Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if not localPlayerIsValid then return end
	
	
	local slideConnection = RunService.PreRender:Connect(function()
		
		local character = localPlayer.Character
		if(not character) then return end

		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if(not humanoid) then return end

		local rootPart: BasePart = character:FindFirstChild("HumanoidRootPart")
		if(not rootPart) then return end

		currentVelocity += humanoid.MoveDirection * 0.40
		currentVelocity *= 0.992

		rootPart.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, rootPart.AssemblyLinearVelocity.Y, currentVelocity.Z)
	end)
	
	local character = localPlayer.Character
	if not character then return end
	
	local humanoid: Humanoid? = character:FindFirstChildWhichIsA("Humanoid")
	local humanoidIsValid = AssertHelper.ExpectedValAssert(
		typeof(humanoid) == "Instance"
		and humanoid:IsA("Humanoid"),
		humanoid,
		"humanoid",
		"Humanoid"
	)
	if not humanoidIsValid then return end
	humanoid.Died:Connect(function()
		print("died fired")
	end)
end

local clientExperimentHadnlers = {
	["Slide"] = ApplyClientSlide
}

function ClientExperimentHandlers.ExecuteClientExperimentByType(experimentType: string)
	local experimentTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentType) == "string",
		experimentType,
		"experimentType",
		"ExecuteClientExperimentByType",
		"string"
	)
	if(not experimentTypeIsValid) then return end
	
	local clientExperimentHandler: () -> ()? = clientExperimentHadnlers[experimentType]
	local handlerIsValid = AssertHelper.ExpectedValAssert(
		type(clientExperimentHandler) == "function",
		clientExperimentHandler,
		"clientExperimentHandler",
		"function"
	)
	if(not handlerIsValid) then return end
	
	clientExperimentHandler()
end
return ClientExperimentHandlers
