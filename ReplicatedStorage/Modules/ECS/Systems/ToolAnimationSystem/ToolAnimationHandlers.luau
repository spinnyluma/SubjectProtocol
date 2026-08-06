const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const ToolConfig = require("../../../Shared/Constants/ToolConfig")
const Trove = require("../../../Utilities/Trove")



local ToolAnimationHandlers = {}

ToolAnimationHandlers.toolAnimTrove = Trove.new()

local function InitializeTwoHandedToolHandlers(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"InitializeTwoHandedToolHandlers",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	
end

local activationFunctions = {
	[ToolConfig.toolTypes.TwoHandedTool.Name] = InitializeTwoHandedToolHandlers
}

function ToolAnimationHandlers.GetToolActivationHandlerFn(toolType: string)
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(toolType) == "string",
		toolType,
		"toolType",
		"GetToolActivationHandlerFn",
		"string"
	)
	if(not toolTypeIsValid) then return end
	
	local activationFunction = activationFunctions[toolType]
	
	return activationFunction
end

return ToolAnimationHandlers
