const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Shared = Modules.Shared

const Constants = Shared.Constants

const ClientReplicaConfig = require(Constants.ClientReplicaConfig)

const Replica = require("../Utilities/ReplicaServer")

local ReplicaConfig = {}

ReplicaConfig.tokens = {
	[ClientReplicaConfig.replicaTokenNames.CellImprisonment.Name] = {
		Token = Replica.Token(ClientReplicaConfig.replicaTokenNames.CellImprisonment.Name),
		Name = ClientReplicaConfig.replicaTokenNames.CellImprisonment.Name,
		Value = ClientReplicaConfig.replicaTokenNames.CellImprisonment.Value
	},
	[ClientReplicaConfig.replicaTokenNames.CurrentMode.Name] = {
		Token = Replica.Token(ClientReplicaConfig.replicaTokenNames.CurrentMode.Name),
		Name = ClientReplicaConfig.replicaTokenNames.CurrentMode.Name,
		Value = ClientReplicaConfig.replicaTokenNames.CurrentMode.Value
	},
	[ClientReplicaConfig.replicaTokenNames.PlayerStats.Name] = {
		Token = Replica.Token(ClientReplicaConfig.replicaTokenNames.PlayerStats.Name),
		Name = ClientReplicaConfig.replicaTokenNames.PlayerStats.Name,
		Value = ClientReplicaConfig.replicaTokenNames.PlayerStats.Value
	}
}

return ReplicaConfig
