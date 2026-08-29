const ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Modules.Utilities.t)

const AssertHelper = require("../Debug/AssertHelper")

local RaycastWeaponHelper = {}

-- Checks if the given tool has an "Ammo" attribute.
function RaycastWeaponHelper.HasAmmoAttribute(tool: Instance?): boolean
	const toolIsValidFn = t.instanceIsA("Tool")
	
	const toolIsValid, toolInvalidReason = toolIsValidFn(tool)
	if not toolIsValid then
		AssertHelper.Warn(toolInvalidReason)
		return false
	end
	
	return tool:GetAttribute("A_Ammo") ~= nil
end

-- Checks if the given ammo amount is a valid number >= 0.
function RaycastWeaponHelper.IsAmmoValid(ammo: number): boolean
	local ammoIsValidFn = t.numberMin(0)
	
	local ammoIsValid, ammoInvalidReason = ammoIsValidFn(ammo)
	if not ammoIsValid then
		AssertHelper.Warn(ammoInvalidReason)
		return false
	end
	
	return true
end

return RaycastWeaponHelper
