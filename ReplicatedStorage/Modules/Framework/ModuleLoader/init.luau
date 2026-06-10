local ModuleLoader = {}
ModuleLoader.cachedModules = {}
ModuleLoader.NAME = script.Name
ModuleLoader.BLACKLISTED_MODULES = {
	"GoodSignal"
}
--[[
	Adds a cached ModuleScript value to the cachedModules table in the ModuleLoader table.
	
	@param moduleScript ModuleScript The module script to add to a container.
]]
local function AddCachedModuleScript(moduleScript: ModuleScript)
	local requiredModuleScript: ModuleScript = require(moduleScript)
	ModuleLoader.cachedModules[moduleScript.Name] = requiredModuleScript
end

--[[
	Gets a module script value by its name.
	
	@param moduleScriptName string The name of the module script to get.
	@returns {[string]: any?}? The module script with the given name or nil if it does not exist.
]]
function ModuleLoader.Get(moduleScriptName: string): {[string]: any?}?
	return ModuleLoader.cachedModules[moduleScriptName]
end

--[[
	Initializes the module loader. Requires all the module scripts.
	
	@param moduleScripts {ModuleScript?} The module scripts to require.
]]
function ModuleLoader.Init(moduleScripts: {ModuleScript?})	
	for _, moduleScript in ipairs(moduleScripts) do
		--[[
			Check if the module script to require is not the same name as the ModuleLoader's name
			because we don't want to start the module loader recursively.
		]]
		
		local blacklistedModuleIndex: number? = table.find(ModuleLoader.BLACKLISTED_MODULES, moduleScript.Name)
		if(moduleScript:IsA("ModuleScript")
			and moduleScript.Name ~= ModuleLoader.NAME
			and not blacklistedModuleIndex) then
			AddCachedModuleScript(moduleScript)
		end
	end
	
end

--[[ 
	Starts all the modules if they have a Start() method.
	
	@param cachedModuleContainer {ModuleScript?} The container of module scripts for which you should run the Start() method.
]]
function ModuleLoader.Start(cachedModuleContainer: {ModuleScript?})
	for _, moduleScript in pairs(cachedModuleContainer) do
		if(type(moduleScript) == "table" 
			and moduleScript.Start ~= nil) then

			task.defer(moduleScript.Start)
		end
	end
end

return ModuleLoader
