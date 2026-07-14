local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReflectionService = game:GetService("ReflectionService")
local CollectionService = game:GetService("CollectionService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local ReflectionHelper = require(ReplicatedStorage.Modules.Helpers.Reflection.ReflectionHelper)


local VfxService = {}

function VfxService.SpawnFire(fireConfig: {[string]: any?}, fireSpawn: Attachment | BasePart)
	local fireConfigIsValid = AssertHelper.InvalidArgAssert(
		type(fireConfig) == "table",
		fireConfig,
		"fireConfig",
		"VfxService.SpawnFire",
		"table"
	)
	if not fireConfigIsValid then
		return
	end
	local fireSpawnIsValid = AssertHelper.InvalidArgAssert(
		typeof(fireSpawn) == "Instance"
		and (fireSpawn:IsA("Attachment")
			or fireSpawn:IsA("BasePart")	
		),
		fireSpawn,
		"fireSpawn",
		"VfxService.SpawnFire",
		"Attachment | BasePart"
	)
	if not fireSpawnIsValid then
		return
	end
	
	
	
	local fire = Instance.new("Fire")
	for property, value in fireConfig do
		local propertyExists = ReflectionHelper.DoesClassHaveProperty("Fire", property)
		local propertyExistsIsValid = AssertHelper.ExpectedValAssert(
			propertyExists,
			propertyExists,
			"propertyExists",
			"true"
		)
		
		if not propertyExistsIsValid then
			continue
		end
		
		fire[property] = value
	end
	
	
	CollectionService:AddTag(fire, "T_Vfx")
	fire.Parent = fireSpawn
end

function VfxService.SpawnExplosion(explosionConfig: {[string]: any?})
	local explosionConfigIsValid = AssertHelper.InvalidArgAssert(
		type(explosionConfig) == "table",
		explosionConfig,
		"explosionConfig",
		"VfxService.SpawnExplosion",
		"table"
	)
	
	if not explosionConfigIsValid then
		return
	end
	
	local explosion = Instance.new("Explosion")
	for property, value in explosionConfig do
		local propertyExists = ReflectionHelper.DoesClassHaveProperty("Explosion", property)
		local propertyExistsIsValid = AssertHelper.ExpectedValAssert(
			propertyExists,
			propertyExists,
			"propertyExists",
			"true"
		)
		
		if not propertyExistsIsValid then
			continue
		end
		
		explosion[property] = value
	end
	
	CollectionService:AddTag(explosion, "T_Vfx")
	explosion.Parent = workspace
	task.delay(3, function()
		explosion:Destroy()
	end)
end

function VfxService.RemoveVfxOnInstance(instance: Instance)
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"VfxService.RemoveVfxOnInstance",
		"Instance"
	)
	if not instanceIsValid then
		return
	end
	
	local vfxSelector = "." .. "T_Vfx"
	
	local vfxInstances = instance:QueryDescendants(vfxSelector)
	
	for _, vfxInstance in vfxInstances do
		vfxInstance:Destroy()
	end
end


return VfxService