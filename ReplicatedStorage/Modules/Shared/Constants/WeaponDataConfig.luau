local WeaponDataConfig = {}

export type RaycastPacket = {
	Weapon: Model,
	Origin: Vector3,
	Direction: Vector3,
	EndPosition: Vector3,
	InstanceHit: Instance?
}

return WeaponDataConfig
