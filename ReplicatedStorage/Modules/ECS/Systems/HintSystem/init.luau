const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenService = game:GetService("TweenService")
const Players = game:GetService("Players")

const remoteEventsFolder = ReplicatedStorage.Assets.Shared.Remotes.Events

const sendHintRE = remoteEventsFolder.SendHint

const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const Color3Helper = require("../../Helpers/Color/Color3Helper")
const HintConfig = require("../../Shared/Constants/Hint/HintConfig")
const Promise = require("../../Utilities/Promise")

local HintSystem = {}

const hintTweenInfo = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

const containerTweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)
const hintTextContainerTemplate = ReplicatedStorage.Assets.UI.Templates.Text.HintTextContainer

local hintScreenGui: ScreenGui? = nil
local hintContainer: Frame? = nil

local playingTweens: {Tween?} = {}

local function InitializeUiElements()
	const localPlayer = Players.LocalPlayer
	Promise.try(function()
		const playerGui = localPlayer:WaitForChild("PlayerGui")
		hintScreenGui = playerGui:WaitForChild("Hint")
		hintContainer = hintScreenGui:WaitForChild("HintContainer")
	end)
end

local function ShowHint(message: string, color: HintConfig.HintColorName)
	const messageIsValid = AssertHelper.InvalidArgAssert(
		type(message) == "string",
		message,
		"message",
		"ShowHint",
		"string"
	)
	if not messageIsValid then
		return
	end

	const colorIsValid = AssertHelper.InvalidArgAssert(
		HintConfig.hintColors[color] ~= nil,
		color,
		"color",
		"ShowHint",
		"HintConfig.HintColorName"
	)
	if(not colorIsValid) then return end

	const realColorEnum = HintConfig.hintColors[color]
	const realColorEnumIsValid = AssertHelper.ExpectedValAssert(
		type(realColorEnum) == "table",
		realColorEnum,
		"realColor",
		"table"
	)
	if(not realColorEnumIsValid) then return end
	if(not hintTextContainerTemplate
		or (not hintScreenGui)
		or (not hintContainer)) then return end
	
	const textColor3 = realColorEnum.TextColor3
	if(not textColor3) then return end
	
	const r, g, b = Color3Helper.ToRGB(textColor3)

	if(not r or not g or not b) then return end
	
	const soundConfig = realColorEnum.SoundConfig
	if(soundConfig) then
		ClientSoundService.PlayLocalSound(soundConfig)
	end
	const textClone = hintTextContainerTemplate:Clone()
	
	local canvasGrpTween = TweenService:Create(textClone,
		containerTweenInfo,
		{
			Position = UDim2.new(hintContainer.Position.X.Scale, 
				0, 
				hintContainer.Position.Y.Scale,
				30),

			GroupTransparency = 0
		}
	)
	Promise.try(function()
		const hintText: TextLabel = textClone:WaitForChild("HintText")
		hintText.Text = message
		hintText.TextColor3 = Color3.fromRGB(r, g, b)
		textClone.Parent = hintContainer
		hintScreenGui.Enabled = true
		canvasGrpTween:Play()

		canvasGrpTween.Completed:Once(function()
			task.delay(6, function()
				canvasGrpTween = TweenService:Create(textClone,
					containerTweenInfo,
					{
						Position = UDim2.new(hintContainer.Position.X.Scale, 
							0, 
							hintContainer.Position.Y.Scale,
							0),
						GroupTransparency = 1
					}
				)
				canvasGrpTween:Play()
				
				canvasGrpTween.Completed:Once(function()
					textClone:Destroy()

					
				end)
				
			end)

		end)
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)
	

	
end

function HintSystem.Initialize()
	InitializeUiElements()
	sendHintRE.OnClientEvent:Connect(function(message: string,
		color: HintConfig.HintColorName
	)
		ShowHint(message, color)
	end)
end

return HintSystem
