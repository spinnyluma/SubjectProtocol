local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ClientExperimentHandlers = {}

local stumbleActive = false

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

		currentVelocity += humanoid.MoveDirection * 0.30
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
		slideConnection:Disconnect()
	end)
end


local function ApplyClientStumble()
	if(stumbleActive) then return end

	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if not localPlayerIsValid then return end

	local character = localPlayer.Character
	if(not character) then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if(not humanoid) then return end
	stumbleActive = true
	humanoid.Died:Connect(function()
		stumbleActive = false		
	end)
	while stumbleActive do
		local random = Random.new()
		local randomStumbleTime = random:NextInteger(3, 6)
		task.wait(randomStumbleTime)

		character = localPlayer.Character
		if(not character) then continue end

		humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if(not humanoid) then continue end



		

		local randomX = (random:NextNumber() * 2) - 1
		local randomZ = (random:NextNumber() * 2) - 1

		local randomDirection = 
			Vector3.new(randomX,
				0,
				randomZ
			)

		if(randomDirection.Magnitude < 0.01) then
			return
		end
		local runServiceConnection = RunService:BindToSimulation(function()

			humanoid:Move(randomDirection)
		end, Enum.StepFrequency.Hz60, Enum.RenderPriority.Character.Value + 1)
		task.delay(0.5, function()
			runServiceConnection:Disconnect()
		end)
	end

	
end
local clientExperimentHandlers = {
	["Slide"] = ApplyClientSlide,
	["Stumble"] = ApplyClientStumble
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
	
	local clientExperimentHandler: () -> ()? = clientExperimentHandlers[experimentType]
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
