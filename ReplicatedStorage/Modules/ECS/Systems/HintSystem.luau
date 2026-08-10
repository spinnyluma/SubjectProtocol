const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const remoteEventsFolder = ReplicatedStorage.Assets.Shared.Remotes.Events

const sendHintRE = remoteEventsFolder.SendHint

const HintConfig = require("../../Shared/Constants/Hint/HintConfig")
const Promise = require("../../Utilities/Promise")

local HintSystem = {}

local hintScreenGui: ScreenGui? = nil

local hintText: TextLabel? = nil

local function InitializeUiElements()
	const localPlayer = Players.LocalPlayer
	Promise.try(function()
		const playerGui = localPlayer:WaitForChild("PlayerGui")
		hintScreenGui = playerGui:WaitForChild("Hint")
		const hintContainer = hintScreenGui:WaitForChild("Container")
		hintText = hintContainer:WaitForChild("Text")
	end)
end

function HintSystem.Initialize()
	InitializeUiElements()
	sendHintRE.OnClientEvent:Connect(function(message: string,
		color: HintConfig.HintColorName
	)
		
	end)
end

return HintSystem
