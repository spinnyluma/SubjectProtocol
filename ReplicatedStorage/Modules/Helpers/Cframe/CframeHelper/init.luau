local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)
local CframeHelperConstants = require(script.CframeHelperConstants)


local CframeHelper = {}

--[[
	Gets the CFrame position in between the position of two CFrames.
	
	@param cframe1 CFrame The first cframe.
	@param cframe2 CFrame The second cframe.
	
	@returns CFrame? The cframe in between the two cframes.
]]
function CframeHelper.GetMidCframe(cframe1: CFrame, cframe2: CFrame): CFrame?
	local cframe1IsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to CframeModule.GetMidCframe. CFrame expected for cframe1, got {cframe1}`,
		typeof(cframe1) == "CFrame"
	)
	local cframe2IsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to CframeModule.GetMidCframe. CFrame expected for cframe2, got {cframe2}`,
		typeof(cframe2) == "CFrame"
	)
	

	if(not cframe1IsValid
		or (not cframe2IsValid)) then
		return nil	
	end

	local cframe1Position: Vector3 = cframe1.Position
	local cframe2Position: Vector3 = cframe2.Position


	local positionBetweenMagnitude1: Vector3 = cframe1:PointToObjectSpace(cframe2Position) / 2

	--[[
		Look at the new rotation from the position in-between the two cframes
		because we want the cframe to have the correct orientation.
	]]
	local newPosition: Vector3 = cframe1:PointToWorldSpace(positionBetweenMagnitude1)
	
	local newCframe: CFrame = CFrame.new(newPosition)
	return newCframe
end

--[[
	Gets the CFrame along the segment between cframeStart and cframeEnd that matches the local X coordinate of the compared CFrame.
	
	@param CFrame cframeStart The start cframe of the segment.
	@param CFrame cframeEnd The end cframe of the segment.
	@param CFrame cframeToCompare The cframe to compare to.
	@param CframeModuleConstants.ReturnedCframeOrientationType returnedCframeOrientationType The type of orientation the returned CFrame will have. See CframeModuleConstants for documentation.
	@param Vector3? up The up vector to use when calculating the cframe orientation if the position of the returned CFrame is along the segment, but not on the start and positions. If not provided, the Vector3.yAxis is used.
	@returns CFrame? The cframe along the segment between cframeStart and cframeEnd that matches the local X coordinate of the compared CFrame.
]]
function CframeHelper.GetCframeAlongSegment(cframeStart: CFrame, cframeEnd: CFrame, cframeToCompare: CFrame, returnedCframeOrientationType: CframeHelperConstants.ReturnedCframeOrientationType, up: Vector3?): CFrame?
	local cframeStartIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(cframeStart) == "CFrame",
		cframeStart,
		"cframeStart",
		"CframeModule.GetCframeAlongSegment",
		"CFrame"
	)
	if(not cframeStartIsValid) then
		return nil
	end
	
	local cframeEndIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(cframeEnd) == "CFrame",
		cframeEnd,
		"cframeEnd",
		"CframeModule.GetCframeAlongSegment",
		"CFrame"
	)
	if(not cframeEndIsValid) then
		return nil
	end
	
	local cframeToCompareIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(cframeEnd) == "CFrame",
		cframeToCompare,
		"cframeToCompare",
		"CframeModule.GetCframeAlongSegment",
		"CFrame"
	)
	if(not cframeToCompareIsValid) then
		return nil
	end
	
	local returnedCframeOrientationTypeIsValid: boolean? = AssertHelper.InvalidArgAssert(
		CframeHelperConstants.returnedCframeOrientationTypes[returnedCframeOrientationType] ~= nil,
		returnedCframeOrientationType,
		"returnedCframeOrientationType",
		"CframeModule.GetCframeAlongSegment",
		"CframeModuleConstants.ReturnedCframeOrientationType"
	)
	if(not returnedCframeOrientationTypeIsValid) then
		return nil
	end
	
	local comparedToStartVector: Vector3 = cframeToCompare.Position - cframeStart.Position
	local endToStartVector: Vector3 = cframeEnd.Position - cframeStart.Position 
	
	--[[
		We dot the vector from the start of the segment to the cframe we want to compare to
		with the vector from the start to the end of the segment
		because we want to know how many studs along the segment the "compared" position is.
	]]
	local distanceAlongSegment: number = comparedToStartVector:Dot(endToStartVector)
	
	--[[
		We dot product the end to start vector with itself to get the magnitude of the vector squared
		because the distanceAlongSegment does a dot product of two vectors that use studs (which equals an unit of measure unit squared).
	]]
	local distanceBetweenEndStart: number = endToStartVector:Dot(endToStartVector)
	local percentageAlongSegment: number = distanceAlongSegment / distanceBetweenEndStart
	local percentageAlongSegmentClamped: number = math.clamp(percentageAlongSegment, 0, 1)
	
	local cframeStartPosition: Vector3 = cframeStart.Position
	
	local positionAlongSegment: Vector3 = cframeStartPosition + (percentageAlongSegmentClamped * endToStartVector)
	
	local cframeAlongSegment: CFrame = CFrame.new()
	
	if(returnedCframeOrientationType == CframeHelperConstants.returnedCframeOrientationTypes.CFrameAlongSegment.Name
		or (percentageAlongSegmentClamped ~= 0 and percentageAlongSegmentClamped ~= 1)) then
		
		local cframeEndPosition: Vector3 = cframeEnd.Position
		local startToEndVector: Vector3 = cframeStartPosition -  cframeEndPosition
		local startToEndVectorDirection: Vector3 = startToEndVector.Unit
		
		--[[
			If the position difference between the cframe's end segment position and the position along the segment is 0,
			the cframe's end position is used to 
		]]
		local startPositionLookAtPositionDiffMagnitude: number = (positionAlongSegment - cframeEndPosition).Magnitude
		if(startPositionLookAtPositionDiffMagnitude == 0) then
			cframeAlongSegment = cframeEnd
		else
			if(not up) then
				up = Vector3.yAxis
			end

			cframeAlongSegment = CFrame.lookAt(positionAlongSegment, cframeEndPosition, up)
		end
	else
		if(percentageAlongSegmentClamped == 0) then
			local positionResetCframeStart: CFrame = cframeStart - cframeStart.Position
			cframeAlongSegment = positionResetCframeStart + positionAlongSegment
		elseif(percentageAlongSegmentClamped == 1) then
			local positionResetCframeEnd: CFrame = cframeEnd - cframeEnd.Position
			cframeAlongSegment = positionResetCframeEnd + positionAlongSegment
		end
	end
	
	return cframeAlongSegment
end


--[[
	Gets W, X, Y and Z rotation components from a CFrame.
]]
function CframeHelper.GetRotationComponents(cframe: CFrame)
	: (number, number, number, number, number, number, number, number, number)
	return select(4, cframe:GetComponents())
end

return CframeHelper
