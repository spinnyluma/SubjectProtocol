local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)


local VectorHelper = {}

--[[
	Gets a unit direction Vector3 between two parts.
	@param BasePart instance1
	@param BasePart instance2
	@returns Vector3? The unit direction vector between the two parts.
]]
function VectorHelper.GetUnitVectorBetweenParts(instance1: BasePart, 
	instance2: BasePart
): Vector3?
	local instance1IsValid = AssertHelper.InvalidArgAssert(
		typeof(instance1) == "Instance"
			and instance1:IsA("BasePart"),
		instance1,
		"instance1",
		"VectorHelper.GetUnitVectorBetweenParts",
		"BasePart"
	)
	if(not instance1IsValid) then return end
	
	local instance2IsValid = AssertHelper.InvalidArgAssert(
		typeof(instance2) == "Instance"
			and instance2:IsA("BasePart"),
		instance2,
		"instance2",
		"VectorHelper.GetUnitVectorBetweenParts",
		"BasePart"
	)
	if(not instance2IsValid) then return end
	
	local vector: Vector3 = instance2.Position - instance1.Position
	return vector.Unit
end

return VectorHelper
