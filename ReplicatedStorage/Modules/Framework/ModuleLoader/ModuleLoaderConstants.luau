local ModuleLoaderConstants = {}

ModuleLoaderConstants.RUN_CONTEXT_TAGS = {
	["T_ClientModule"] = {
		["Name"] = "T_ClientModule",
		["Value"] = 0
	},
	["T_ServerModule"] = {
		["Name"] = "T_ServerModule",
		["Value"] = 1
	},
	["T_ReplicatedModule"] = {
		["Name"] = "T_ReplicatedModule",
		["Value"] = 2
	}
}
return ModuleLoaderConstants
