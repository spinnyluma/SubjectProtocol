const NPCSystemConfig = require("./Config")

local NPCInitializeHandlers = {}

const function InitializeStaticNPC(npc: Model)
	
end

NPCInitializeHandlers.handlers = {
	[NPCSystemConfig.npcTypes.Static.Name] = InitializeStaticNPC 
}


return NPCInitializeHandlers
