local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientExperimentHandlers = require(script.ClientExperimentHandlers)


local startClientExperimentRE = ReplicatedStorage.Assets.Shared.Remotes.Events.StartClientExperiment


local ClientExperimentSystem = {}

function ClientExperimentSystem.Initialize()
	startClientExperimentRE.OnClientEvent:Connect(function(experimentType: string)
		if(not experimentType) then return end
		
		ClientExperimentHandlers.ExecuteClientExperimentByType(experimentType)
	end)
end

return ClientExperimentSystem
