const CollectionService = game:GetService("CollectionService")
const Players = game:GetService("Players")

const TitleEffectHandlers = require("@self/TitleEffectHandlers")
const TitleEffectConfig = require("@self/Config")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const t = require("../../Utilities/t")

local TitleEffectSystem = {}

const function InitializeTitleEffects()
	const titleEffects = CollectionService:GetTagged(TitleEffectConfig.SYSTEM_TAG_NAME)
	const localPlayer = Players.LocalPlayer
	const playerGui = localPlayer:WaitForChild("PlayerGui")
	
	for _, titleEffect in titleEffects do
		if(not titleEffect:IsDescendantOf(workspace)
			and (not titleEffect:IsDescendantOf(playerGui))) then continue end
		const titleEffectName = titleEffect:GetAttribute("A_TitleEffect")
		const titleEffectNameIsValid, titleEffectNameInvalidReason = t.string(titleEffectName)
		if not titleEffectNameIsValid then
			AssertHelper.Warn(titleEffectNameInvalidReason)
			continue
		end
		const handler = TitleEffectHandlers.handlers[titleEffectName]
		print(handler)
		const handlerIsValid, handlerInvalidReason = t.callback(handler)
		if not handlerIsValid then
			AssertHelper.Warn(handlerInvalidReason)
			continue
		end
		handler(titleEffect)
	end
	
	CollectionService:GetInstanceAddedSignal(TitleEffectConfig.SYSTEM_TAG_NAME):Connect(function(titleEffect)
		local titleEffectName = titleEffect:GetAttribute("A_TitleEffect")
		local titleEffectNameIsValid, titleEffectNameInvalidReason = t.string(titleEffectName)
		if not titleEffectNameIsValid then
			AssertHelper.Warn(titleEffectNameInvalidReason)
			return
		end
		local handler = TitleEffectHandlers.handlers[titleEffectName]
		local handlerIsValid, handlerInvalidReason = t.callback(handler)
		if not handlerIsValid then
			AssertHelper.Warn(handlerInvalidReason)
			return
		end
		handler(titleEffect)
	end)
end

function TitleEffectSystem.Initialize()
	InitializeTitleEffects()
end

return TitleEffectSystem
