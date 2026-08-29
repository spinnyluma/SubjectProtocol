const CollectionService = game:GetService("CollectionService")

const Particle2dEmitterConfig = require("@self/Config")
const Particle2dHandlers = require("@self/Particle2dHandlers")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const t = require("../../Utilities/t")

local particleEmitters = {}



local Particle2dEmitterSystem = {}

const function InitializeParticle2dHandler(hookObject: GuiObject)
	const guiObjectIsValidFn = t.instanceIsA("GuiObject")
	const hookObjectIsValid, hookObjectInvalidReason = guiObjectIsValidFn(hookObject)
	if not hookObjectIsValid then
		AssertHelper.Warn(hookObjectInvalidReason)
		return
	end
	const particle2dName = hookObject:GetAttribute(Particle2dEmitterConfig.PARTICLE_2D_NAME_ATTR_NAME)
	const particle2dNameIsValid, particle2dNameInvalidReason = t.string(particle2dName)
	if not particle2dNameIsValid then
		AssertHelper.Warn(particle2dNameInvalidReason)
		return
	end

	const handler = Particle2dHandlers.handlers[particle2dName]
	const handlerIsValid, handlerInvalidReason = t.callback(handler)
	if not handlerIsValid then
		AssertHelper.Warn(handlerInvalidReason)
		return
	end

	handler(hookObject)
end

const function Initialize2dParticles()
	const particles2dUiObjects = CollectionService:GetTagged(Particle2dEmitterConfig.SYSTEM_TAG_NAME)
	for _, particle2dUiObject in particles2dUiObjects do
		InitializeParticle2dHandler(particle2dUiObject)
	end
	
	CollectionService:GetInstanceAddedSignal(Particle2dEmitterConfig.SYSTEM_TAG_NAME):Connect(function(particle2dUiObject)
		InitializeParticle2dHandler(particle2dUiObject)
	end)
end

function Particle2dEmitterSystem.Initialize()
	Initialize2dParticles()
end

return Particle2dEmitterSystem
