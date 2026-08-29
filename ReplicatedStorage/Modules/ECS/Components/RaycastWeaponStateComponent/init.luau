const ReplicatedStorage = game:GetService("ReplicatedStorage")

const t = require(ReplicatedStorage.Modules.Utilities.t)

local RaycastWeaponStateComponent = {}

export type RaycastWeaponStateComponent = {
	InCooldown: boolean,
	PredictedWeaponAmmo: number,
	WeaponState: string
}

RaycastWeaponStateComponent.interface = {
	InCooldown = t.boolean,
	PredictedWeaponAmmo = t.number,
	WeaponState = t.string
}

function RaycastWeaponStateComponent.new()
	return {
		InCooldown = false,
		PredictedWeaponAmmo = -1,
		WeaponState = "Idle"
	}
end

return RaycastWeaponStateComponent
