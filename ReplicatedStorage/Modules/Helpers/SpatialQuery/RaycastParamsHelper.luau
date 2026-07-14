local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)


local RaycastParamsHelper = {}


--[[
	Clones a RaycastParams.
	Since FilterDescendantsInstances and FilterType properties are superseded by ExcludeInstances
	and IncludeInstances, this function will NOT clone over these properties over to the new RaycastParams.
	
	@param raycastParams RaycastParams The RaycastParams to clone.
	@returns RaycastParams? A clone of the RaycastParams. If the argument passed was not a RaycastParams, the function will return nil.
]]
function RaycastParamsHelper.CloneRaycastParams(raycastParams: RaycastParams): RaycastParams?
	local raycastParamsIsValid = AssertHelper.InvalidArgAssert(
		typeof(raycastParams) == "RaycastParams",
		raycastParams,
		"raycastParams",
		"RaycastParamsHelper.CloneRaycastParams",
		"RaycastParams"
	)
	if(not raycastParamsIsValid) then return end
	
	local newRaycastParams = RaycastParams.new()
	newRaycastParams.ExcludeInstances = raycastParams.ExcludeInstances
	newRaycastParams.IncludeInstances = raycastParams.IncludeInstances
	newRaycastParams.IgnoreWater = raycastParams.IgnoreWater
	newRaycastParams.CollisionGroup = raycastParams.CollisionGroup
	newRaycastParams.RespectCanCollide = raycastParams.RespectCanCollide
	newRaycastParams.BruteForceAllSlow = raycastParams.BruteForceAllSlow
	return newRaycastParams
end

return RaycastParamsHelper
