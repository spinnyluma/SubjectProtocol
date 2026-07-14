local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)

local SpatialQueryHelper = {}



function SpatialQueryHelper.GetStaticGeometryInInstance(instance: Instance): {Instance?}?
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"SpatialQueryHelper.GetStaticGeometryInInstance",
		"Instance"
	)
	if not instanceIsValid then return nil end
	
	
	return instance:QueryDescendants(SpatialQueryConfig.STATIC_GEOMETRY_SELECTOR)
end

return SpatialQueryHelper
