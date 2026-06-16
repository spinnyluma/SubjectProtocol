local CframeModuleConstants = {}

export type ReturnedCframeOrientationType = keyof<typeof(CframeModuleConstants.returnedCframeOrientationTypes)>
CframeModuleConstants.returnedCframeOrientationTypes = {
	--[[
		When the point found along the segment is at the start or the end of the segment,
		the start or end CFrame's orientation is used to form the returned CFrame along the segment.
	]]
	["RespectStartEndCframe"] = {
		["Name"] = "RespectStartEndCframe",
		["Value"] = 0
	},
	--[[
		The returned CFrame along the segment returns orientation that matches the orientation of the segment vector.
		Does not respect the start or end CFrame's orientation.
	]]
	["CFrameAlongSegment"] = {
		["Name"] = "CFrameAlongSegment",
		["Value"] = 1
	}
}

return CframeModuleConstants
