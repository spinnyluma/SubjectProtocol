local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)


local UiHelper = {}

local coreGuiObjects = {
	"DynamicThumbstickFrame",
}

function UiHelper.IsJoystickAtPosition(xPosition: number, yPosition: number)
	local xPositionIsValid = AssertHelper.InvalidArgAssert(
		type(xPosition) == "number",
		xPosition,
		"xPosition",
		"UiHelper.IsCoreGuiAtPosition",
		"number"
	)
	if(not xPositionIsValid) then return end
	local yPositionIsValid = AssertHelper.InvalidArgAssert(
		type(yPosition) == "number",
		yPosition,
		"yPosition",
		"UiHelper.IsCoreGuiAtPosition",
		"number"
	)
	if(not yPositionIsValid) then return end
	
	
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"UiHelper.IsCoreGuiAtPosition",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	if(UserInputService.PreferredInput ~= Enum.PreferredInput.Touch) then
		return false
	end
	
	local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui")
	local guiObjectsOnPos = playerGui:GetGuiObjectsAtPosition(xPosition, yPosition)
	
	local touchGui = playerGui:WaitForChild("TouchGui")
	local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
	local dynamicThumbstickFrame = touchControlFrame:WaitForChild("DynamicThumbstickFrame")
	for _, guiObject in guiObjectsOnPos do
		if(guiObject.Name == "DynamicThumbstickFrame") then
			return true
		end
		
		local uiObjectIsInDynamicThumbstick = guiObject:IsDescendantOf(dynamicThumbstickFrame)
		if(uiObjectIsInDynamicThumbstick) then
			return true
		end
	end
	
	return false
end

return UiHelper
