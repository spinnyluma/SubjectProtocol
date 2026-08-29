local WeaponDataConfig = {}

export type RaycastPacket = {
	Weapon: Model,
	Origin: Vector3,
	Direction: Vector3,
	EndPosition: Vector3,
	InstanceHit: Instance?,
	ShootStartTime: number?
}

export type HitboxPacket = {
	Weapon: Model,
	DamageableObjectHit: Model
}

return WeaponDataConfig
