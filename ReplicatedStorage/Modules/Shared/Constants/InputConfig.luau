const ReplicatedStorage = game:GetService("ReplicatedStorage")


const contextsFolder = ReplicatedStorage.Assets.Input.Contexts


const UsingActivatableTool = contextsFolder.UsingActivatableTool

const ToolConfig = require("./ToolConfig")

local InputConfig = {}


InputConfig.inputContextsByToolType = {
	[ToolConfig.toolTypes.TwoHandedTool.Name] = UsingActivatableTool
}

return InputConfig
