local ReplicatedStorage = game:GetService("ReplicatedStorage")

local inputContextsFolder = ReplicatedStorage.Assets.Input.Contexts

local InputSignals = require(script.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local InputSystem = {}

local function SetInputContextEnabled(inputContext: InputContext, enabled: boolean)
	local inputContextIsValid = AssertHelper.InvalidArgAssert(
		typeof(inputContext) == "Instance"
			and inputContext:IsA("InputContext"),
		inputContext,
		"inputContext",
		"InputSystem.SetInputContextEnabled",
		"InputContext"
	)
	if(not inputContextIsValid) then return end
	
	local enabledIsValid = AssertHelper.InvalidArgAssert(
		type(enabled) == "boolean",
		enabled,
		"enabled",
		"InputSystem.SetInputContextEnabled",
		"boolean"
	)
	if(not enabledIsValid) then return end
	inputContext.Enabled = enabled
end


function InputSystem.Initialize()
	InputSignals.InputContextEnabledChanged:Connect(function(inputContext: InputContext,
		enabled: boolean
	)
		SetInputContextEnabled(inputContext, enabled)
	end)
end

return InputSystem
