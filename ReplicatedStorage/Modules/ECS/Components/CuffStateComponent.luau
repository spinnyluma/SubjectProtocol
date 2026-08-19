const ClientCuffSystemConfig = require("../Systems/ClientCuffSystem/Config")

local CuffStateComponent = {}

export type CuffStateComponent = {
	CuffState: string
}
function CuffStateComponent.new()
	return {
		CuffState = ClientCuffSystemConfig.cuffStates.Idle.Name
	}
end
return CuffStateComponent
