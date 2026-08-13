const CollectionService = game:GetService("CollectionService")

const ToolPromptSystemConfig = require("@self/Config")
const t = require("../../Utilities/t")

local ToolPromptSystem = {}

local function InitializePromptTool(toolPromptInstance: Tool)
	const toolPromptInstanceIsValid, toolPromptInvalidityReason = t.instanceIsA("Tool")(toolPromptInstance)
	if not toolPromptInstanceIsValid then return end
	
	
end

local function InitializePromptTools()
	local toolPromptInstances = CollectionService:GetTagged(ToolPromptSystemConfig.SYSTEM_TAG_NAME)
	
	for _, toolPromptInstance: Tool in toolPromptInstances do
		local instanceIsToolFn = t.instanceIsA("Tool")
		
		local toolPromptInstanceIsValid, toolPromptInstanceInvalidityReason = instanceIsToolFn(toolPromptInstance)
		if not toolPromptInstanceIsValid then return end
		
		toolPromptInstance.Equipped:Connect(function()
			print("equippred", tostring(toolPromptInstance))
		end)
	end
end

function ToolPromptSystem.Initialize()
	
end

return ToolPromptSystem
