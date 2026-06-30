local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replica = require(ReplicatedStorage.Modules.Utilities.ReplicaClient)

local ReplicaInitSystem = {}

function ReplicaInitSystem.PostInitialize()
	Replica.RequestData()
end

return ReplicaInitSystem
