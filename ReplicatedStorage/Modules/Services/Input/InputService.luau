const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const InputConfig = require("../../Shared/Constants/InputConfig")
const InputSystemSignals = require("../../ECS/Systems/InputSystem/Signals")


local InputService = {}

function InputService.SetInputContextStateByToolType(toolType: string, state: boolean): boolean
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(toolType) == "string",
		toolType,
		"toolType",
		"SetInputContextStateByToolType",
		"string"
	)
	if(not toolTypeIsValid) then return false end

	local stateIsValid = AssertHelper.InvalidArgAssert(
		typeof(state) == "boolean",
		state,
		"state",
		"SetInputContextStateByToolType",
		"boolean"
	)
	if(not stateIsValid) then return false end
	
	local inputContext = InputConfig.inputContextsByToolType[toolType]
	local inputContextIsValid = AssertHelper.ExpectedValAssert(
		typeof(inputContext) == "Instance"
			and inputContext:IsA("InputContext"),
		inputContext,
		"inputContext",
		"InputContext"
	)
	if(not inputContextIsValid) then return false end

	InputSystemSignals.InputContextEnabledChanged:Fire(inputContext, state)
	return inputContext
end


return InputService
