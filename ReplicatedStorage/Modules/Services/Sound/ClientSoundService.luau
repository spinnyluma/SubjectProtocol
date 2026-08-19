const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")
const t = require("../../Utilities/t")
local TweenService = game:GetService("TweenService")

local ClientSoundService = {}

function ClientSoundService.PlayLocalSound(soundConfig: SoundConfig.SoundConfig): Sound
	const soundConfigIsValid, soundConfigInvalidityReason = t.table(soundConfig)
	if(not soundConfigIsValid) then
		AssertHelper.Warn(soundConfigInvalidityReason)
		return
	end
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundConfig.SoundId
	sound.Volume = soundConfig.Volume or 1
	sound.Looped = soundConfig.Looped or false
	sound.Parent = game:GetService("SoundService")
	sound:Play()
	return sound
end


--[[
	Fades out the volume of a sound over a specified duration.
	Once the volume reaches 0, the sound is stopped and destroyed.
	
	@yields
	@param sound: The Sound instance to fade out.
	@param duration: The duration of the fade in seconds.
]]
function ClientSoundService.FadeOutSound(sound: Sound, duration: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(sound, tweenInfo, {Volume = 0})
	
	
	
	tween:Play()
	
	tween.Completed:Wait()
	sound:Stop()
	sound:Destroy()
end

return ClientSoundService
