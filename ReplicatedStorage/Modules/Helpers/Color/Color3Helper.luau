local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)


local Color3Helper = {}

--[[
	Converts a normalized Color3 value (0-1 channels) to its proper RGB values (0-255).
	@param Color3 color3 The normalized color to convert.
	@returns (number, number, number) The red, green, and blue values in the 0-255 range.
		Returns nothing if the input is invalid.
]]
function Color3Helper.ToRGB(color3: Color3): (number, number, number)
	local color3IsValid = AssertHelper.InvalidArgAssert(
		typeof(color3) == "Color3",
		color3,
		"color3",
		"Color3Helper.ToRGB",
		"Color3"
	)
	if(not color3IsValid) then return end

	local r: number = math.round(color3.R * 255)
	local g: number = math.round(color3.G * 255)
	local b: number = math.round(color3.B * 255)
	return r, g, b
end

return Color3Helper
