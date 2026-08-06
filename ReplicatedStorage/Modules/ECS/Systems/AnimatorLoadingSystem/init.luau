local ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

local AnimatorLoadingSystemSignals = require(script.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)

local AnimatorLoadingSystem = {}



local function IsAnimationLoadedInAnimator(animator: Animator, animTrack: AnimationTrack)
	local animatorIsValid = AssertHelper.InvalidArgAssert(
		typeof(animator) == "Instance"
		and animator:IsA("Animator"),
		animator,
		"animator",
		"IsAnimationLoadedInAnimator",
		"Animator"
	)
	if(not animatorIsValid) then return end
	
	local animationTrackIsValid = AssertHelper.InvalidArgAssert(
		typeof(animTrack) == "Instance"
		and animTrack:IsA("AnimationTrack"),
		animTrack,
		"animation",
		"IsAnimationLoadedInAnimator",
		"AnimationTrack"
	)
	if(not animationTrackIsValid) then return end
	
	return SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animTrack) ~= nil
end

local function InitializeComponentsCleanup()
	local localPlayer = Players.LocalPlayer
	localPlayer.CharacterRemoving:Connect(function(character: Model)
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if(not humanoid) then
			return
		end		
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if(not animator) then
			return
		end
		print("Cleaned up!!")
		print(SystemManagerModule.world["Components"])	

		SystemManagerModule.RemoveComponent("LoadedAnimatorAnims", animator)
		print(SystemManagerModule.world["Components"])	
	end)

	
end


function AnimatorLoadingSystem.Initialize()
	AnimatorLoadingSystemSignals.AnimatorTrackCacheRequested:Connect(function(animator: Animator, animTrack: AnimationTrack)
		local animationLoadedInAnimator = IsAnimationLoadedInAnimator(animator, animTrack)
		if(not animationLoadedInAnimator) then
			local loadedAnimTracksComp = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
			if(not loadedAnimTracksComp) then
				local component = SystemManagerModule.AddComponent("LoadedAnimatorAnims", animator, animTrack)
				local componentIsValid = AssertHelper.ExpectedValAssert(
					type(component) == "table",
					component,
					"component",
					"table"
				)
				if(not componentIsValid) then return end
				local animationId = animTrack.Animation.AnimationId
				component.LoadedAnimationTracks[animationId] = animTrack
			else
				local animationId = animTrack.Animation.AnimationId
				loadedAnimTracksComp.LoadedAnimationTracks[animationId] = animTrack
			end
			
		end		
	end)
	
	InitializeComponentsCleanup()
end

return AnimatorLoadingSystem
