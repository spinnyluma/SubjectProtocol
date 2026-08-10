local Config = {}
export type MeleeState = keyof<typeof(Config.states)>

Config.states = {
	Idle = {
		Name = "Idle",
		Value = 0,
	},
	Equip = {
		Name = "Equip",
		Value = 1,
	},
	Attacking = {
		Name = "Attacking",
		Value = 1,
	}
}

return Config
