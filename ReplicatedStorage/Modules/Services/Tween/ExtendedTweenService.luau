const TweenService = game:GetService("TweenService")

const TerminalConfig = require("../../Shared/Constants/TerminalConfig")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const t = require("../../Utilities/t")

local ExtendedTweenService = {}

function ExtendedTweenService.Spin(instance: Model | BasePart, tweenInfo: TweenInfo)
	const modelIsValidFn = t.instanceIsA("Model") 
	const basePartIsValidFn = t.instanceIsA("BasePart") 
	const instanceIsValid, instanceInvalidityReason = modelIsValidFn(instance)
	const instanceIsValidBasePart, instanceBasePartInvalidityReason = basePartIsValidFn(instance)
	if(not instanceIsValid
		and (not instanceIsValidBasePart)) then 
		if(instanceInvalidityReason) then
			AssertHelper.Warn(instanceInvalidityReason)
		end
		
		if(instanceBasePartInvalidityReason) then
			AssertHelper.Warn(instanceBasePartInvalidityReason)
		end
		
		return
	end
	

	const tweenInfoIsValid, tweenInfoInvalidityReason = t.TweenInfo(tweenInfo)
	if(not tweenInfoIsValid) then
		AssertHelper.Warn(tweenInfoInvalidityReason)
		return
	end
	
	local partToSpin: BasePart? = nil
	if(instance:IsA("Model")) then
		partToSpin = instance.PrimaryPart
	else
		partToSpin = instance
	end
	
	const basePartIsValidFn = t.instanceIsA("BasePart")
	local partToSpinIsValid, partToSpinInvalidityReason = basePartIsValidFn(partToSpin)
	
	if(not partToSpinIsValid) then
		AssertHelper.Warn(partToSpinInvalidityReason)
		return
	end
	local tween = TweenService:Create(partToSpin,
		tweenInfo,
		{CFrame = partToSpin.CFrame * CFrame.Angles(0, math.rad(180), 0)})
	tween:Play()
	return tween
end

return ExtendedTweenService
