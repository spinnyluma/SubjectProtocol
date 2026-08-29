const Particle2dEmitterConfig = require("./Config")
const ParticleEmitter = require("../../../Utilities/ParticleEmitter")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const UIEmitterV2 = require("../../../Utilities/UIEmitterV2")
const t = require("../../../Utilities/t")

local Particle2dHandlers = {}

const function GetConfigFromParticle(particle: GuiObject, hook: GuiObject)
	const guiObjectIsValidFn = t.instanceIsA("GuiObject")
	const particleIsValid, particleInvalidReason = guiObjectIsValidFn(particle)
	if not particleIsValid then
		AssertHelper.Warn(particleInvalidReason)
		return
	end
	
	const config = {}
	
	const size = particle:GetAttribute("Size")
	if(size) then
		config.Size = size
	end
	
	const texture = particle:GetAttribute("Texture")
	if(texture) then
		config.Texture = texture
	end
	
	const velocity = particle:GetAttribute("Velocity")
	if(velocity) then
		config.Velocity = velocity
	end
	
	const velocityNestedTable = {}
	
	const velocityMinX = particle:GetAttribute("VelocityMinX")
	const velocityMaxX = particle:GetAttribute("VelocityMaxX")
	
	const velocityMinY = particle:GetAttribute("VelocityMinY")
	const velocityMaxY = particle:GetAttribute("VelocityMaxY")
	
	if(velocityMinX
		and velocityMaxX
		and velocityMinY
		and velocityMaxY) then
		table.insert(velocityNestedTable, {velocityMinX, velocityMaxX})
		table.insert(velocityNestedTable, {velocityMinY, velocityMaxY})
		config.Velocity = velocityNestedTable
	end
	
	
	const lifetime = particle:GetAttribute("LifeTime")
	if(lifetime) then
		config.LifeTime = lifetime
	end
	
	const drag = particle:GetAttribute("Drag")
	if(drag) then
		config.Drag = drag
	end
	
	const directionNestedTable = {}
	const directionMinX = particle:GetAttribute("DirectionMinX")
	const directionMaxX = particle:GetAttribute("DirectionMaxX")
	
	const directionMinY = particle:GetAttribute("DirectionMinY")
	const directionMaxY = particle:GetAttribute("DirectionMaxY")
	
	if(directionMinX
		and directionMaxX
		and directionMinY
		and directionMaxY) then
		table.insert(directionNestedTable, {directionMinX, directionMaxX})
		table.insert(directionNestedTable, {directionMinY, directionMaxY})
		config.Direction = directionNestedTable
	end
	
	const gravity = particle:GetAttribute("Gravity")
	if(gravity) then
		config.Gravity = gravity
	end
	
	const drag = particle:GetAttribute("Drag")
	if(drag) then
		config.Drag = drag
	end	
	
	const zIndex = particle:GetAttribute("ZIndex")
	if(zIndex) then
		config.ZIndex = zIndex
	end
	
	const squash = particle:GetAttribute("Squash")
	if(squash) then
		config.Squash = squash
	end
	
	const color = particle:GetAttribute("Color")
	if(color) then
		config.Color = color
	end
	
	const transparency = particle:GetAttribute("Transparency")
	if(transparency) then
		config.Transparency = transparency
	end
	
	const rotation = particle:GetAttribute("Rotation")
	if(rotation) then
		config.Rotation = rotation
	end
	
	const rotationSpeed = particle:GetAttribute("RotationSpeed")
	if(rotationSpeed) then
		config.RotationSpeed = rotationSpeed
	end
	

	config.Properties = {
		Position = UDim2.fromOffset(
			hook.AbsolutePosition.X + hook.AbsoluteSize.X / 2,
			hook.AbsolutePosition.Y + hook.AbsoluteSize.Y / 2
		),
	}
	return config
end

const function LightningParticleHandler(hook: GuiObject)
	const guiObjectIsValidFn = t.instanceIsA("GuiObject")
	const hookIsValid, hookInvalidReason = guiObjectIsValidFn(hook)
	if not hookIsValid then
		AssertHelper.Warn(hookInvalidReason)
		return
	end
	

	const particleEnum = Particle2dEmitterConfig.particleEmitterNames.Lightning
	const particleEnumIsValid, particleEnumInvalidReason = t.table(particleEnum)
	if not particleEnumIsValid then
		AssertHelper.Warn(particleEnumInvalidReason)
		return
	end
	
	const particles = particleEnum.Particles
	for _, particle in particles do
		const particleConfig = GetConfigFromParticle(particle, hook)
		const particleConfigIsValid, particleConfigInvalidReason = t.table(particleConfig)
		if not particleConfigIsValid then
			AssertHelper.Warn(particleConfigInvalidReason)
			return
		end
		const screenGui = hook:FindFirstAncestorOfClass("ScreenGui")
		UIEmitterV2:Emit(20, particleConfig, screenGui or hook)
	end
	
end

Particle2dHandlers.handlers = {
	[Particle2dEmitterConfig.particleEmitterNames.Lightning.Name] = LightningParticleHandler
}

return Particle2dHandlers
