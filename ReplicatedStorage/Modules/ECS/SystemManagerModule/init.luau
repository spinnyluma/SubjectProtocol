local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SystemManagerModuleConstants = require(script.SystemManagerModuleConstants)

const Trove = require("../Utilities/Trove")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)
local ModuleLoader = require(ReplicatedStorage.Modules.Framework.ModuleLoader)
local FastSignal = require(ReplicatedStorage
	.Modules
	.Framework
	.FastSignal)
local SystemUpdateFunctions = require(script.SystemUpdateFunctions)
local SystemUpdateFunctionsConstants = require(script
	.SystemUpdateFunctions
	.SystemUpdateFunctionsConstants)
local SharedTypes = require(ReplicatedStorage.Modules.Types.SharedTypes)
local ComponentConstants = require(script.ComponentConstants)

local SystemManagerModule = {}
SystemManagerModule.systems = {}
SystemManagerModule.world = {
	["Components"] = {},
	["Game"] = {}
}

--[[
	Sets a value in the SystemManagerModule.world.Game table.
]]
function SystemManagerModule.SetGlobalGameState(key: string, value: any): any?
	local keyIsValid = AssertHelper.InvalidArgAssert(
		type(key) == "string",
		key,
		"key",
		" SystemManagerModule.SetGlobalGameState",
		"string"
	)
	if(not keyIsValid) then return end
	
	SystemManagerModule.world.Game[key] = value
	return SystemManagerModule.world.Game[key]
end

function SystemManagerModule.GetGlobalGameState(key: string)
	local keyIsValid = AssertHelper.InvalidArgAssert(
		type(key) == "string",
		key,
		"key",
		" SystemManagerModule.GetGlobalGameState",
		"string"
	)
	if(not keyIsValid) then return nil end
	
	local existingPairValue = SystemManagerModule.world.Game[key]
	local existingPairValueIsValid = AssertHelper.ExpectedValAssert(
		typeof(existingPairValue) ~= "nil",
		existingPairValue,
		"existingPairValue",
		"SystemManagerModule.GetGlobalGameState",
		"any"
	)
	if(not existingPairValue) then
		return nil
	end
	return existingPairValue
end
--[[
	Gets the component's index by an entity.
	
	@param string componentName The name of the component for which to get the entity's index.
	@param Instance | {} entity The entity for which to get the component.
	@returns number? The index of the component for the entity if it was found.
]]
function SystemManagerModule.GetComponentIndexByEntity(componentName: string, entity: Instance): number?
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManager.GetComponentIndexByEntity. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	local entityIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManager.GetComponentIndexByEntity. Instance | \{} expected for entity, got {entity}`,
		typeof(entity) == "Instance"
		or type(entity) == "table"
	)
	if(not entityIsValid) then
		return nil
	end
	
	local componentTable: {[string]: any?}? = SystemManagerModule.world["Components"][componentName]
	local componentTableIsValid: boolean? = type(componentTable) == "table"
	
	if(not componentTableIsValid) then
		return nil
	end
	local entityIndex: number? = componentTable[SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.EntityToDataIndex.Name][entity]
	return entityIndex
end


--[[
	Gets the index for the last component in a component ("Data") table.
	
	@param string componentName The name of the component to get the index for.
	@returns number? Gets the index for the last component in the component ("Data") table.
]]
function SystemManagerModule.GetLastComponentIndex(componentName: string): number?
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetLastComponentIndex. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local currentComponentIndex: number = -1
	
	local dataIndexesToEntities: {[number]: Instance?}? = SystemManagerModule.GetComponentTableValueByKey(componentName, SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.DataIndexToEntity.Name)
	local dataIndexesToEntitiesIsValid: boolean? = AssertHelper.Assert(
		`table expected for dataIndexesToEntities, got {dataIndexesToEntities}`,
		type(dataIndexesToEntities) == "table"
	)
	if(not dataIndexesToEntitiesIsValid) then
		return nil
	end
	for index, _ in dataIndexesToEntities do
		index = index :: number
		currentComponentIndex = math.max(index, currentComponentIndex)
	end
	if(currentComponentIndex == -1) then
		return nil
	end
	return currentComponentIndex
end

--[[
	Gets a component by an index.
	
	@param string componentName The name of the component to get.
	@param number index The index of the component to get.
	@returns T? The component if it was found.
]]
function SystemManagerModule.GetComponentByIndex<T>(componentName: string, index: number): T?
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentByIndex. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local indexIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentByIndex. number expected for index, got {componentName}`,
		type(componentName) == "string"
	)
	if(not indexIsValid) then
		return nil
	end
	
	local componentTable: {[string]: any?}? = SystemManagerModule.world["Components"][componentName]
	local componentTableIsValid: boolean? = AssertHelper.Assert(
		`Component with name {componentName} does not exist`,
		type(componentTable) == "table"
	)
	if(not componentTableIsValid) then
		return nil
	end
	
	local component: {any?}? = componentTable[SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.Data.Name][index]
	return component
end

--[[
	Gets a component by an entity.
	
	@param string componentName The name of the component to get.
	@param Instance | {} entity The entity to get the component for.
	@returns T? The component if it was found.
]]
function SystemManagerModule.GetComponentByEntity<T>(componentName: string, entity: Instance | {}): T?
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentByEntity. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local entityIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentByEntity. Instance | \{} expected for entity, got {entity}`,
		typeof(entity) == "Instance"
		or type(entity) == "table"
	)
	if(not entityIsValid) then
		return nil
	end
	local componentIndex: number? = SystemManagerModule.GetComponentIndexByEntity(componentName, entity)
	local componentIndexIsValid: boolean? = type(componentIndex) == "number"
	
	if(not componentIndexIsValid) then
		return nil
	end
	
	local component: any? = SystemManagerModule.GetComponentByIndex(componentName, componentIndex)
	local componentIsValid: boolean? = type(component) == "table"
		or typeof(component) == "Instance"
	
	if(not componentIsValid) then
		return nil
	end
	return component
end

--[[
	Gets the Components table containing {
		[<Data>] = {},
		[<EntityToDataIndex>] = {},
		[<DataIndexToEntity>] = {}
	}
	for a particular component name.
	
	@param string componentName The name of the component to get.
	@returns {[string]: {any}}? The component table if it was found.
]]
function SystemManagerModule.GetComponentTableByComponentName(componentName: string): {[string]: {any}}?
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"SystemManagerModule.GetComponentTableByComponentName",
		"string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local componentTable: {[string]: {any}}? = SystemManagerModule.world["Components"][componentName]
	
	return componentTable
end

--[[
	Gets a component table value (Data, EntityToDataIndex, DataIndexToEntity) by the key.
	
	@param string componentName The name of the component to get.
	@param string componentTableKey The key of the component table to get.
	@returns {any?}? The component table value if it was found.
]]
function SystemManagerModule.GetComponentTableValueByKey(componentName: string, componentTableKey: string): {any?}?
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentTableValueByKey. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local componentTableKeyIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentTableValueByKey. string for componentTableKey, got {componentTableKey}`,
		type(componentTableKey) == "string"
	)
	if(not componentTableKeyIsValid) then
		return nil
	end
	
	local componentTable: {[string]: any?}? = SystemManagerModule.world["Components"][componentName]
	local componentTableIsValid: boolean? = AssertHelper.Assert(
		`table expected for componentTable, got {componentTable}`,
		type(componentTable) == "table"
	)
	if(not componentTableIsValid) then
		return nil
	end
	
	local componentTableValue: {any?}? = componentTable[componentTableKey]
	return componentTableValue
end
--[[
	Gets the components by a system module name (the components a system is using).
	
	@param string systemModuleName The name of the system module to get the components enums by. This name must be in the format of "...System".
	@returns {SharedTypes.CustomEnum?}? The systeem component enums by a system module name.
]]
function SystemManagerModule.GetComponentsBySystemName(systemModuleName: string): {SharedTypes.CustomEnum?}?
	local systemModuleNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.GetComponentsToAddBySystemName. string expected for systemModuleName, got {systemModuleName}`,
		type(systemModuleName) == "string"
	)
	if(not systemModuleNameIsValid) then
		return nil
	end
	
	local requiredSystemConstants: {[string]: any?}? = ModuleLoader.Get(systemModuleName .. "Constants")
	local requiredSystemConstantsIsValid: boolean? = AssertHelper.Assert(
		`table expected for requiredSystemConstants, got {requiredSystemConstants}`,
		type(requiredSystemConstants) == "table"
	)
	if(not requiredSystemConstantsIsValid) then
		return nil
	end

	local systemComponents: {string?}? = requiredSystemConstants[SystemManagerModuleConstants.COMPONENTS_TO_ADD_VARIABLE_NAME]
	local systemComponentsIsValid: boolean? = AssertHelper.Assert(
		`table? expected for systemComponents, got {systemComponents}`,
		type(systemComponents) == "table" or type(systemComponents) == "nil"
	)
	if(not systemComponentsIsValid) then
		return nil
	end
	
	return systemComponents
end

--[[
	Returns a component property by its name.
	
	@param string systemModuleName The name of the system module to get the component property info by. This name must be in the format of "...System".
	@param string componentPropertyName The name of the component property to get.
	@returns any? The component property by its name.
]]
function SystemManagerModule.GetComponentPropertyByName(systemModuleName: string, 
	componentName: string,
	componentPropertyName: string): any?
	local systemModuleNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(systemModuleName) == "string",
		systemModuleName,
		"systemModuleName",
		"SystemManagerModule.GetComponentPropertyByName",
		"string"
	)
	if(not systemModuleNameIsValid) then
		return nil
	end
	
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"SystemManagerModule.GetComponentPropertyByName",
		"string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local componentPropertyNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentPropertyName) == "string",
		componentPropertyName,
		"componentPropertyName",
		"SystemManagerModule.GetComponentPropertyByName",
		"string"
	)
	if(not componentPropertyNameIsValid) then
		return nil
	end
	
	local componentPropertyInfo: ComponentConstants.ComponentPropertyInfo = SystemManagerModule.GetComponentPropertyInfoBySystemName(
		systemModuleName
	)
	local componentPropertyInfoIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(componentPropertyInfo) == "table",
		componentPropertyInfo,
		"componentPropertyInfo",
		"table"
	)
	if(not componentPropertyInfoIsValid) then
		return nil
	end
	local componentProperties: {[string]: any?}? = componentPropertyInfo[componentName]
	local componentPropertiesIsValid: boolean? = type(componentProperties) == "table"
	if(not componentPropertiesIsValid) then
		return nil
	end
	
	local property: any? = componentProperties[componentPropertyName]
	local propertyIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(property) ~= "nil",
		property,
		"property",
		"truthy value"
	)
	if(not propertyIsValid) then
		return nil
	end
	return property
end
--[[
	Gets a COMPONENT_PROPERTY_INFO from a system module.
	
	@param string systemModuleName The name of the system module to get the component property info by. This name must be in the format of "...System".
	@returns ComponentConstants.ComponentPropertyInfo? The component property info.
]]
function SystemManagerModule.GetComponentPropertyInfoBySystemName(systemModuleName: string): ComponentConstants.ComponentPropertyInfo?
	local systemModuleNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(systemModuleName) == "string",
		systemModuleName,
		"systemModuleName",
		"SystemManagerModule.GetComponentPropertyInfoBySystemName",
		"string"
	)
	if(not systemModuleNameIsValid) then
		return nil
	end
	
	local requiredSystemConstants: {[string]: any?}? = ModuleLoader.Get(systemModuleName .. "Constants")
	local requiredSystemConstantsIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(requiredSystemConstants) == "table",
		requiredSystemConstants,
		"requiredSystemConstants",
		"table"		
	)
	if(not requiredSystemConstantsIsValid) then
		return nil
	end
	
	local componentPropertyInfo: ComponentConstants.ComponentPropertyInfo? = requiredSystemConstants[SystemManagerModuleConstants.COMPONENT_PROPERTY_INFO_VARIABLE_NAME]
	return componentPropertyInfo
end

--[[
	Adds a component to an entity according to which components a system might manipulate.
	
	@param Instance entity The entity for which to add a component.
	@param string systemName The system for which its componentsToAdd variable 
		determines which components to add for an entity.
]]
function SystemManagerModule.AddComponentsBySystemName(entity: Instance, systemName: string)
	local entityIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.AddComponent. Instance expected for entity, got {entity}`,
		typeof(entity) == "Instance"
	)
	if(not entityIsValid) then
		return
	end
	
	local systemNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.AddComponent. string expected for systemName, got {systemName}`,
		type(systemName) == "string"
	)
	if(not systemNameIsValid) then
		return
	end
	
	local componentsToAddEnums: {SharedTypes.CustomEnum?}? = SystemManagerModule.GetComponentsBySystemName(systemName)
	if(not componentsToAddEnums) then
		return
	end

	for componentName, _ in componentsToAddEnums do
		SystemManagerModule.AddComponent(componentName, entity)
		
	end	
end

--[[
	Adds a component for an entity.
	
	@param string componentName The name of the component to add.
	@param Instance entity The entity to add the component to.
	@returns any? Returns the component that was added. Returns nil if there was an error creating the component or if the component already exists.
]]
function SystemManagerModule.AddComponent(componentName: string, entity: Instance | {}): any?
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"SystemManagerModule.AddComponent",
		"string"
	)
	if(not componentNameIsValid) then
		return nil
	end
	
	local entityIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance"
		or type(entity) == "table",
		entity,
		"entity",
		"SystemManagerModule.AddComponent",
		"Instance | table"
	)
	if(not entityIsValid) then
		return nil
	end
	
	if(not SystemManagerModule.world["Components"][componentName]) then
		SystemManagerModule.world["Components"][componentName] = {}
		--TODO: replace the string literals with constant definitions from constants
		SystemManagerModule.world["Components"][componentName][SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.Data.Name] = {}
		SystemManagerModule.world["Components"][componentName][SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.EntityToDataIndex.Name] = {}
		SystemManagerModule.world["Components"][componentName][SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.DataIndexToEntity.Name] = {}
	end
	local requiredComponentModule: {[string]: any?}? = ModuleLoader.Get(componentName .. "Component")
	local requiredComponentModuleIsValid: boolean? = AssertHelper.Assert(
		`table expected for requiredComponentModule, got {requiredComponentModule}`,
		type(requiredComponentModule) == "table"
	)
	if(not requiredComponentModuleIsValid) then
		return
	end
	
	
	local componentExists = SystemManagerModule.DoesEntityComponentExist(componentName, entity)
	
	if(componentExists) then
		return
	end
	local componentConstructor: (any?) -> any? = requiredComponentModule["new"]
	local componentConstructorIsValid: boolean? = AssertHelper.Assert(
		`function expected for componentConstructor, got {componentConstructor}`,
		type(componentConstructor) == "function"
	)
	if(not componentConstructorIsValid) then
		return
	end

	local newComponent: any? = componentConstructor()
	table.insert(SystemManagerModule.world["Components"][componentName]["Data"], newComponent)
	local entityToDataIndex: number = #SystemManagerModule.world["Components"][componentName]["Data"]
	SystemManagerModule.world["Components"][componentName]["EntityToDataIndex"][entity] = entityToDataIndex
	SystemManagerModule.world["Components"][componentName]["DataIndexToEntity"][entityToDataIndex] = entity
	return newComponent
end



--[[
	Checks whether if the component for an entity exists. 
	If the component table (containing component table key value pairs) or the entity to data index table is nil,
	then it returns false.
	
	
	@param string componentName The name of the component to check.
	@param Instance entity The entity to check the component for.
	@returns boolean Whether the component for the entity exists.
]]
function SystemManagerModule.DoesEntityComponentExist(componentName: string,
	entity: Instance
): boolean
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"SystemManagerModule.DoesEntityComponentExist",
		"string"
	)
	if(not componentNameIsValid) then
		return false
	end
	
	local entityIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance",
		entity,
		"entity",
		"SystemManagerModule.DoesEntityComponentExist",
		"Instance"
	)
	if(not entityIsValid) then
		return false
	end
	
	local componentTable: {[string]: {any?}?} = SystemManagerModule.world["Components"][componentName]
	local componentTableIsValid: boolean = type(componentTable) == "table"
	if(not componentTableIsValid) then
		return false
	end

	local entityToDataIndexTable: {[string]: any?}? = componentTable[SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.EntityToDataIndex.Name]
	local entityToDataIndexTableIsValid: boolean = type(entityToDataIndexTable) == "table"
	if(not entityToDataIndexTableIsValid) then
		return
	end
	
	local dataIndex: number? = entityToDataIndexTable[entity]
	local dataIndexIsValid: boolean = type(dataIndex) == "number"
	if(not dataIndexIsValid) then
		return false
	end
	
	local dataTable: {any?}? = componentTable[SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.Data.Name]
	local dataTableIsValid: boolean = type(dataTable) == "table"
	if(not dataTableIsValid) then
		return false
	end
	
	return dataTable[dataIndex] ~= nil
end

--[[
	Removes a component for a particular entity.
	
	@param string componentName The name of the component to remove.
	@param Instance entity The entity to remove the component from.
	@returns boolean true if the component was removed successfully, false otherwise.
]]
function SystemManagerModule.RemoveComponent(componentName: string, entity: Instance): boolean
	local entityIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.RemoveComponent. Instance expected for entity, got {entity}`,
		typeof(entity) == "Instance"
	)
	if(not entityIsValid) then
		return false
	end
	
	local componentNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.RemoveComponent. string expected for componentName, got {componentName}`,
		type(componentName) == "string"
	)
	if(not componentNameIsValid) then
		return false
	end
		
	local componentDataTable: {any?}? = SystemManagerModule.GetComponentTableValueByKey(componentName,
		SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.Data.Name
	)
	local componentDataTableIsValid: boolean? = AssertHelper.Assert(
		`table expected for componentDataTable, got {componentDataTable}`,
		type(componentDataTable) == "table"
	)
	if(not componentDataTableIsValid) then
		return false
	end
	local entityComponentIndex: number? = SystemManagerModule.GetComponentIndexByEntity(componentName, entity)
	
	local entityComponentIndexIsValid: boolean? = AssertHelper.Assert(
		`Attempted to remove component {componentName} which does not exist for entity {entity}`,
		type(entityComponentIndex) == "number"
	)
	if(not entityComponentIndexIsValid) then
		return false
	end

	local component: {any?}? = componentDataTable[entityComponentIndex]
	local componentIsValid: boolean? = AssertHelper.Assert(
		`table expected for component, got {component}`,
		type(component) == "table"
	)
	if(not componentIsValid) then
		return false
	end
	
	--[[
		Clear the component before removing it
		because there may be instances attached to the component that have not been destroyed
	]]
	local compCleared: boolean = SystemManagerModule.ClearComponentByEntity(
		componentName,
		entity
	)
	local compClearedIsValid: boolean? = AssertHelper.ExpectedValAssert(
		compCleared,
		compCleared,
		"compCleared",
		"true"
	)
	if(not compClearedIsValid) then
		return false
	end

	local dataIndexesToEntities: {[number]: Instance?}? = SystemManagerModule.GetComponentTableValueByKey(
		componentName,
		SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.DataIndexToEntity.Name
	)
	local dataIndexesToEntitiesIsValid: boolean? = AssertHelper.Assert(
		`table expected for dataIndexesToEntities, got {dataIndexesToEntities}`,
		type(dataIndexesToEntities) == "table"
	)
	if(not dataIndexesToEntitiesIsValid) then
		return false
	end


	local entitiesToDataIndexes: {[Instance]: number?}? = SystemManagerModule.GetComponentTableValueByKey(
		componentName,
		SystemManagerModuleConstants.COMPONENT_TABLE_KEYS.EntityToDataIndex.Name
	)
	local entitiesToDataIndexesIsValid: boolean? = AssertHelper.Assert(
		`table expected for entitiesToDataIndexes, got {entitiesToDataIndexes}`,
		type(entitiesToDataIndexes) == "table"
	)
	if(not entitiesToDataIndexesIsValid) then
		return false
	end
	
	
	local prevLastComponentIndex: number? = SystemManagerModule.GetLastComponentIndex(componentName)
	local prevLastComponentIndexIsValid: boolean? = AssertHelper.Assert(
		`number expected for prevLastComponentIndex, got {prevLastComponentIndex}`,
		type(prevLastComponentIndex) == "number"
	)
	if(not prevLastComponentIndexIsValid) then
		return false
	end
	
	local prevLastComponentEntity: Instance? = dataIndexesToEntities[prevLastComponentIndex]
	local prevLastComponentEntityIsValid: boolean? = AssertHelper.Assert(
		`Instance expected for prevLastComponentEntity, got {prevLastComponentEntity}`,
		typeof(prevLastComponentEntity) == "Instance"
	)
	if(not prevLastComponentEntityIsValid) then
		return false
	end
	
	local componentEntity: Instance? = dataIndexesToEntities[entityComponentIndex]
	local componentEntityIsValid: boolean? = AssertHelper.Assert(
		`Instance expected for componentEntity, got {componentEntity}`,
		typeof(componentEntity) == "Instance"
	)
	if(not componentEntityIsValid) then
		return false
	end
	
	
	local lastComponent: {any?}? = componentDataTable[prevLastComponentIndex]
	local lastComponentIsValid: boolean? = AssertHelper.Assert(
		`table expected for lastComponent, got {lastComponent}`,
		type(lastComponent) == "table"
	)
	if(not lastComponentIsValid) then
		return false
	end
	
	componentDataTable[entityComponentIndex] = nil
	dataIndexesToEntities[entityComponentIndex] = nil
	entitiesToDataIndexes[componentEntity] = nil
	
	--[[
		We ONLY switch the removed entity and the last component in table's positions 
		if the component entity's index is not the same as the last component's index
		because there may only be a single item in the array or the item's index may be the last index itself.
	]]
	if(entityComponentIndex ~= prevLastComponentIndex) then
		--[[
			Switch the last component's position in the table with the component that was just deleted
			because we want to keep the table contiguous.
		]]
		
		componentDataTable[entityComponentIndex] = lastComponent
		componentDataTable[prevLastComponentIndex] = nil		
		
		
		dataIndexesToEntities[entityComponentIndex] = prevLastComponentEntity
		dataIndexesToEntities[prevLastComponentIndex] = nil
		
		entitiesToDataIndexes[componentEntity] = nil
		entitiesToDataIndexes[prevLastComponentEntity] = entityComponentIndex	
	end
	
	return true
end



--[[
	Clears table instance variables in a component and sets instance variables of other types to nil.
	
	@param string componentName The name of the component to clear.
	@param Instance entity The instance for which a component should be cleared.	
	@returns boolean Whether the component was successfully cleared.
]]
function SystemManagerModule.ClearComponentByEntity(componentName: string,
	entity: Instance
): boolean
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"SystemManager.ClearComponentByEntity",
		"string"
	)
	if(not componentNameIsValid) then
		return false
	end
	
	local entityIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance",
		entity,
		"entity",
		"SystemManager.ClearComponentByEntity",
		"Instance"
	)
	if(not entityIsValid) then
		return false
	end
	local component: any? = SystemManagerModule.GetComponentByEntity(componentName, entity)
	local componentIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(component) == "table",
		component,
		"component",
		"table"
	)
	if(not componentIsValid) then
		return false
	end
	
	for key, val in component do
		local valIsTable: boolean = type(val) == "table"
		local valIsInstance: boolean = typeof(val) == "Instance"
		const valIsTrove = type(val) == "table" 
			and type(val.Add) == "function"
			and type(val.Clean) == "function"
			and type(val.Destroy) == "function"
		if(valIsTrove) then
			component[key]:Clean()
			component[key] = nil
		elseif(valIsTable) then
			table.clear(component[key])
			component[key] = nil
		elseif(valIsInstance) then
			component[key]:Destroy()
			component[key] = nil
		else
			component[key] = nil
		end
	end
	return true
end

--[[
	Checks if this system was initialized through the SystemManagerModule's first startup.
	
	@param string systemName The name of the system to check.
]]
function SystemManagerModule.IsSystemInitialized(systemName: string): boolean
	local systemNameIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to SystemManagerModule.IsSystemInitialized. string expected for systemName, got {systemName}`,
		type(systemName) == "string"
	)
	if(not systemNameIsValid) then
		--[[ 
			Return true
			because the caller might try to falsify the initialization of a system
		]]
		return true
	end
	
	return SystemManagerModule.systems[systemName] ~= nil
end

local function InitializeUpdateSystem(systemModule: ModuleScript)
	local systemModuleIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to InitializeUpdateSystem. ModuleScript expected for systemModule, got {systemModule}`,
		typeof(systemModule) == "Instance"
		and systemModule:IsA("ModuleScript")
	)
	if(not systemModuleIsValid) then
		return false
	end
	
	
	local systemUpdateIntervalType: string? = systemModule:GetAttribute(SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPE_ATTR)
	local systemUpdateIntervalTypeIsValid: boolean? = AssertHelper.Assert(
		`Module {systemModule.Name} expected to have {SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPE_ATTR} attribute, got {systemUpdateIntervalType}`,
		type(systemUpdateIntervalType) == "string"
	)
	
	if(not systemUpdateIntervalTypeIsValid) then
		return false
	end
	
	local updateSystemInitFunction: (ModuleScript) -> ()? = SystemUpdateFunctions.GetUpdateSystemInitFunction(systemUpdateIntervalType)
	if(updateSystemInitFunction ~= nil) then
		updateSystemInitFunction(systemModule)
	end	
	return true
end

local function GetSystemsFolder()
	local isClient: boolean = RunService:IsClient()
	local isServer: boolean = RunService:IsServer()
	if(isClient) then
		return ReplicatedStorage.Modules.ECS.Systems
	end
	if(isServer) then
		return ServerStorage.Modules.ECS.Systems
	end
end

local function InitializeSystemComponents(requiredSystemModuleConstants: {[string]: any?}): boolean
	local requiredSystemModuleConstantsIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(requiredSystemModuleConstants) == "table",
		requiredSystemModuleConstants,
		"requiredSystemModuleConstants",
		"InitializeSystemComponents",
		"table"
	)
	if(not requiredSystemModuleConstantsIsValid) then
		return false
	end
	local componentsToAddEnums: {[string]: {[string]: string | number}}? = requiredSystemModuleConstants[SystemManagerModuleConstants.COMPONENTS_TO_ADD_VARIABLE_NAME]
	local componentsToAddEnumsIsValid: boolean = type(componentsToAddEnums) == "table"
	if(not componentsToAddEnumsIsValid) then
		return true
	end
	
	for componentName, _ in componentsToAddEnums do
		local componentTable: {[string]: {any}}? = SystemManagerModule.world["Components"][componentName]
		local componentTableIsValid: boolean = type(componentTable) == "table"
		if(not componentTableIsValid) then
			SystemManagerModule.world["Components"][componentName] = {
				["Data"] = {},
				["EntityToDataIndex"] = {},
				["DataIndexToEntity"] = {}
			}
		end
	end
	
	return true
end

local function InitializeSystem(systemModule: ModuleScript): boolean
	local systemModuleIsValid: boolean? = AssertHelper.Assert(
		`Invalid argument to InitializeUpdateSystem. ModuleScript expected for systemModule, got {systemModule}`,
		typeof(systemModule) == "Instance"
		and systemModule:IsA("ModuleScript")
	)
	if(not systemModuleIsValid) then
		return false
	end
	
	local systemModuleName: string = systemModule.Name
	local requiredSystemModule: {[string]: any?}? = ModuleLoader.Get(systemModuleName)
	local requiredSystemModuleIsValid: boolean? = AssertHelper.Assert(
		`table expected for requiredSystemModule, got {requiredSystemModule}`,
		type(requiredSystemModule) == "table"
	)
	if(not requiredSystemModuleIsValid) then
		return false
	end
	
	local systemModuleInitializeFunction: () -> ()? = requiredSystemModule.Initialize
	local systemModuleInitializeFunctionIsValid: boolean = type(systemModuleInitializeFunction) == "function"
	if(systemModuleInitializeFunctionIsValid) then
		systemModuleInitializeFunction()
	end
	
	local systemConstants: {[string]: any?}? = ModuleLoader.Get(systemModuleName .. "Constants")

	local systemsConstantsIsValid: boolean? = type(systemConstants) == "table"
	if(not systemsConstantsIsValid) then
		--[[
			We return true because the system may not have constants
		]]
		return true
	end
	
	
	local systemCompInitialized: boolean = InitializeSystemComponents(systemConstants)
	if(not systemCompInitialized) then
		return false
	end
	
	local systemTagName: string? = systemConstants[SystemManagerModuleConstants.SYSTEM_TAG_MEMBER_VARIABLE_NAME]
	local systemTagNameIsValid: boolean? = type(systemTagName) == "string"
	if(not systemTagNameIsValid) then
		--[[
			We return true because the system may not need a system tag name
		]]
		return true
	else
		--[[
			Whenever an instance spawns in the world that has a system tag name in its CollectionService tags,
			we add new ECS components for that instance
			because we want to automatically add components for that instance/entity.
		]]
		CollectionService:GetInstanceAddedSignal(systemTagName):Connect(function(entity: Instance)
			if(not entity:IsDescendantOf(workspace)) then
				return
			end
			SystemManagerModule.AddComponentsBySystemName(entity, systemModuleName)
		end)
		CollectionService:GetInstanceRemovedSignal(systemTagName):Connect(function(entity: Instance)
			local systemComponents: {SharedTypes.CustomEnum?}? = SystemManagerModule.GetComponentsBySystemName(systemModuleName)
			if(not systemComponents) then
				return
			end

			local componentPropertyInfo: ComponentConstants.ComponentPropertyInfo? = SystemManagerModule.GetComponentPropertyInfoBySystemName(systemModuleName)
			if(componentPropertyInfo ~= nil) then				
				for componentName, _ in systemComponents do
					local removeComponentTriggerType: string? = SystemManagerModule.GetComponentPropertyByName(
						systemModuleName,
						componentName,
						ComponentConstants.COMPONENT_PROPERTIES_KEYS.RemoveComponentTriggerType.Name
					)
					local removeComponentTriggerTypeIsValid: boolean? = type(removeComponentTriggerType) == "string"
					if(not removeComponentTriggerTypeIsValid) then
						--[[
							We remove the component with the 'default' way
							because the component property information does not
							have information on how to remove this component
						]]
						SystemManagerModule.RemoveComponent(componentName, entity)
						continue
					end

					local removeComponentFunction: (string, string, string) -> ()? = SystemManagerModule.removeComponentFunctions[removeComponentTriggerType]
					local removeComponentFunctionIsValid: boolean? = AssertHelper.ExpectedValAssert(
						type(removeComponentFunction) == "function",
						removeComponentFunction,
						"removeComponentFunction",
						"function"
					)
					if(not removeComponentFunctionIsValid) then
						continue
					end
					removeComponentFunction(componentName, entity, systemModuleName)
				end
			else
				for componentName, _ in systemComponents do
					SystemManagerModule.RemoveComponent(componentName, entity)
				end	
			end

		end)

		local taggedEntities: {Instance?} = CollectionService:GetTagged(systemTagName)
		for _, entity in taggedEntities do
			SystemManagerModule.AddComponentsBySystemName(entity, systemModuleName)
		end
		return true
	end
end

local function InitializeSystems()
	local systemsFolder: Folder = GetSystemsFolder()
	for _, systemModule in systemsFolder:GetChildren() do
		if systemModule:IsA("ModuleScript") then
			local systemModuleName: string = systemModule.Name
			
			local systemIsInitialized: boolean = SystemManagerModule.IsSystemInitialized(systemModuleName)
			if(systemIsInitialized) then
				return
			end
			
			local systemInitialized: boolean = InitializeSystem(systemModule)
			local updateSystemInitialized: boolean = InitializeUpdateSystem(systemModule)
			if(systemInitialized and updateSystemInitialized) then
				SystemManagerModule.systems[systemModuleName] = systemModule
			else
				AssertHelper.Warn(`Failed to initialize system {systemModuleName} or update system`)
			end
			
		end
	end
end

--[[
	Runs the PostInitialize function for modules
	post the initialization (including initializing the update systems tick).
]]
local function PostInitializeSystems()
	local systemsFolder: Folder = GetSystemsFolder()
	for _, systemModule in systemsFolder:GetChildren() do
		if systemModule:IsA("ModuleScript") then
			local systemModuleName: string = systemModule.Name
			
			local systemIsInitialized: boolean = SystemManagerModule.IsSystemInitialized(systemModuleName)
			
			local systemIsInitialized: boolean? = AssertHelper.ExpectedValAssert(
				systemIsInitialized,
				systemIsInitialized,
				"systemIsInitialized",
				"true"
			)
				
			if(not systemIsInitialized) then
				continue
			end
			
			local requiredSystemModule: {[string]: any?}? = require(systemModule)
			
			local postSystemInitializeFunc: () -> ()? = requiredSystemModule["PostInitialize"]
			if(not postSystemInitializeFunc) then
				continue
			end
			
			postSystemInitializeFunc()
			
		end
	end
end


function SystemManagerModule.Start()
	InitializeSystems()
	PostInitializeSystems()
	--SystemUpdateFunctionsConstants.startSystemSignal:Fire("EchoRecordingSystem")
	--SystemUpdateFunctionsConstants.startSystemSignal:Fire("EchoReplayingSystem")
end

local function InstantRemoveComponentHandler(componentName: string, entity: Instance, _)
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"InstantRemoveComponentHandler",
		"string"
	)
	if(not componentNameIsValid) then
		return
	end
	local entityIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance",
		entity,
		"entity",
		"InstantRemoveComponentHandler",
		"Instance"
	)
	if(not entityIsValid) then
		return
	end
	
	SystemManagerModule.RemoveComponent(componentName, entity)
end

local function TimedRemoveComponentHandler(componentName: string, entity: Instance, systemModuleName: string)
	local componentNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(componentName) == "string",
		componentName,
		"componentName",
		"TimedRemoveComponentHandler",
		"string"
	)
	if(not componentNameIsValid) then
		return
	end
	local entityIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance",
		entity,
		"entity",
		"TimedRemoveComponentHandler",
		"Instance"
	)
	if(not entityIsValid) then
		return
	end
	local systemModuleNameIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(systemModuleName) == "string",
		systemModuleName,
		"systemModuleName",
		"TimedRemoveComponentHandler",
		"string"
	)
	if(not systemModuleNameIsValid) then
		return
	end
	
	local removeComponentTime: ComponentConstants.ComponentPropertyInfo? = SystemManagerModule.GetComponentPropertyByName(
		systemModuleName,
		componentName,
		ComponentConstants.COMPONENT_PROPERTIES_KEYS.TimedTime.Name
	)
	local removeComponentTimeIsValid: boolean? = AssertHelper.ExpectedValAssert(
		type(removeComponentTime) == "number",
		removeComponentTime,
		"removeComponentTime",
		"number"
	)
	if(not removeComponentTimeIsValid) then
		return
	end

	task.delay(removeComponentTime, function()
		SystemManagerModule.RemoveComponent(componentName, entity)
	end)
end

SystemManagerModule.removeComponentFunctions = {
	[ComponentConstants.ON_REMOVE_COMPONENT_TRIGGER_TYPES.Instant.Name] = InstantRemoveComponentHandler,
	[ComponentConstants.ON_REMOVE_COMPONENT_TRIGGER_TYPES.Timed.Name] = TimedRemoveComponentHandler,
	[ComponentConstants.ON_REMOVE_COMPONENT_TRIGGER_TYPES.Manual.Name] = function(componentName, _, _)
	end,
}

return SystemManagerModule
