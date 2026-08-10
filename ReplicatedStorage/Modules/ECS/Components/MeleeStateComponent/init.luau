const MeleeStateComponentConfig = require("@self/Config")

export type MeleeStateComponent = {
	State: MeleeStateComponentConfig.MeleeState
}

local MeleeStateComponent = {}


function MeleeStateComponent.new()
	return {
		State = MeleeStateComponentConfig.states.Idle.Name
	}
end

return MeleeStateComponent
