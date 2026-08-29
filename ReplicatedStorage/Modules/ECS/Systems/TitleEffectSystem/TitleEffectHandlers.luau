const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenService = game:GetService("TweenService")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers

const Debug = Helpers.Debug
const Time = Helpers.Time

const AssertHelper = require(Debug.AssertHelper)
const TimeHelper = require(Time.TimeHelper)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

local TitleEffectHandlers = {}

const disruptorTitleEffectTweenInfo = TweenInfo.new(
	5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.InOut,
	-1
)

const function InitializeDisruptorTitleEffect(taggedObject: GuiBase)
	const guiBaseIsValidFn = t.instanceIsA("GuiBase")
	const taggedObjectIsValid, taggedObjectInvalidReason = guiBaseIsValidFn(taggedObject)
	if not taggedObjectIsValid then
		AssertHelper.Warn(taggedObjectInvalidReason)
		return
	end
	
	const promise = Promise.try(function()
		const titleContainer = taggedObject:WaitForChild("TitleContainer")
		const title = titleContainer:WaitForChild("Title")
		const rotatingGradient = title:WaitForChild("RotatingGradient")
		
		const tween = TweenService:Create(rotatingGradient,
			disruptorTitleEffectTweenInfo,
			{
				Rotation = 180
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			tween:Cancel()
			tween:Play()
		end)
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	taggedObject.Destroying:Once(function()
		promise:cancel()
	end)
end

const function InitializeSystemErrorTitleEffect(taggedObject: GuiBase)
	const guiBaseIsValidFn = t.instanceIsA("GuiBase")
	const taggedObjectIsValid, taggedObjectInvalidReason = guiBaseIsValidFn(taggedObject)
	if not taggedObjectIsValid then
		AssertHelper.Warn(taggedObjectInvalidReason)
		return
	end
	
	Promise.try(function()
		const titleContainerAberration = taggedObject:WaitForChild("TitleContainerAberration")
		const greenTitle = titleContainerAberration:WaitForChild("GreenTitle")
		const redTitle = titleContainerAberration:WaitForChild("RedTitle")
		const blueTitle = titleContainerAberration:WaitForChild("BlueTitle")
		
		const titleContainer = taggedObject:WaitForChild("TitleContainer")
		const greenTitleNoOffset = titleContainer:WaitForChild("GreenTitle")
		const redTitleNoOffset = titleContainer:WaitForChild("RedTitle")
		const blueTitleNoOffset = titleContainer:WaitForChild("BlueTitle")
		
		
		const randomObject = Random.new()
		const function AnimateTitleOffset()
			task.spawn(function()
				while taggedObject.Parent do
					local greenPositionOffsetXRandom = randomObject:NextNumber(0.495, 0.52)
					local redPositionOffsetXRandom = randomObject:NextNumber(0.48, 0.505)
					local bluePositionOffsetXRandom = randomObject:NextNumber(0.54, 0.56)

					const offsetTweenInfo = TweenInfo.new(
						0.01,
						Enum.EasingStyle.Cubic,
						Enum.EasingDirection.In,
						-1,
						true
					)
					const offsetTweenGreenTitle = TweenService:Create(greenTitle,
						offsetTweenInfo,
						{
							Position = UDim2.fromScale(greenPositionOffsetXRandom, 0.5)
						}
					)
					const offsetTweenRedTitle = TweenService:Create(redTitle,
						offsetTweenInfo,
						{
							Position = UDim2.fromScale(redPositionOffsetXRandom, 0.5)
						}
					)
					const offsetTweenBlueTitle = TweenService:Create(blueTitle,
						offsetTweenInfo,
						{
							Position = UDim2.fromScale(bluePositionOffsetXRandom, 0.5)		
						}
					)
					offsetTweenRedTitle:Play()
					offsetTweenGreenTitle:Play()
					offsetTweenBlueTitle:Play()
					offsetTweenRedTitle.Completed:Wait()
					--greenTitleNoOffset.Visible = true
					--redTitleNoOffset.Visible = true
					--blueTitleNoOffset.Visible = true
					--task.wait(0.06)
					
					--greenTitleNoOffset.Visible = false
					--redTitleNoOffset.Visible = false
					--blueTitleNoOffset.Visible = false
					
				end
			end)
			
			
		end
		AnimateTitleOffset()
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
end

const function InitializeUnit01TitleEffect(taggedObject: GuiBase)
	const guiBaseIsValidFn = t.instanceIsA("GuiBase")
	const taggedObjectIsValid, taggedObjectInvalidReason = guiBaseIsValidFn(taggedObject)
	if not taggedObjectIsValid then
		AssertHelper.Warn(taggedObjectInvalidReason)
		return
	end
	
	Promise.try(function()
		const scannerContainer = taggedObject:WaitForChild("ScannerContainer")
		const scannerGradient = scannerContainer:WaitForChild("ScannerGradient")
		
		scannerContainer.BackgroundTransparency = 0
		const offsetScannerTweenInfo = TweenInfo.new(
			2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)
		const offsetScannerTween = TweenService:Create(scannerGradient,
			offsetScannerTweenInfo,
			{
				Offset = Vector2.new(1.25, 0)
			}
		)
		offsetScannerTween:Play()
		offsetScannerTween.Completed:Connect(function()
			scannerContainer.BackgroundTransparency = 1
			
			offsetScannerTween:Cancel()
			scannerGradient.Offset = Vector2.new(-0.5, 0)
			task.wait(2)
			scannerContainer.BackgroundTransparency = 0
			offsetScannerTween:Play()
		end)
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
end
TitleEffectHandlers.handlers = {
	Disruptor = InitializeDisruptorTitleEffect,
	SystemError = InitializeSystemErrorTitleEffect,
	Unit01 = InitializeUnit01TitleEffect
}
return TitleEffectHandlers
