local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)
local MeleeStateComponentConfig = require(ReplicatedStorage
	.Modules
	.ECS
	.Components
	.MeleeStateComponent
	.Config)
local MeleeStateComponentSignals = require(ReplicatedStorage
	.Modules
	.ECS
	.Components
	.MeleeStateComponent
	.Signals)
local SystemManagerModule = require(ReplicatedStorage
	.Modules
	.ECS
	.SystemManagerModule)

local MeleeStateService = {}

--[[
	Changes the state of a melee state component to a new state.
	The new state must be defined in MeleeStateComponent.Config.states.
	Fires the MeleeStateChanged signal with the component and the new state.

	@param {State: string} meleeStateComponent The melee state component to change.
	@param string newStateName The name of the new state (must exist in MeleeStateComponent.Config.states).
	@param entity Instance? The entity the melee state component is attached to.
	@returns {State: string}? The updated melee state component, or nil if the change failed.
	
]]
function MeleeStateService.ChangeMeleeState(meleeStateComponent: {State: string}, newStateName: string, entity: Instance): {State: string}?
	local meleeStateComponentIsValid = AssertHelper.InvalidArgAssert(
		type(meleeStateComponent) == "table",
		meleeStateComponent,
		"meleeStateComponent",
		"MeleeStateService.ChangeMeleeState",
		"table"
	)
	if(not meleeStateComponentIsValid) then return end

	local newStateNameIsValid = AssertHelper.InvalidArgAssert(
		type(newStateName) == "string",
		newStateName,
		"newStateName",
		"MeleeStateService.ChangeMeleeState",
		"string"
	)
	if(not newStateNameIsValid) then return end

	local newState = MeleeStateComponentConfig.states[newStateName]
	local newStateIsValid = AssertHelper.ExpectedValAssert(
		type(newState) == "table",
		newState,
		"newState",
		"MeleeStateComponent.Config.states[" .. newStateName .. "]"
	)
	if(not newStateIsValid) then return end

	meleeStateComponent.State = newState.Name

	MeleeStateComponentSignals.MeleeStateChanged:Fire(meleeStateComponent, entity, newState.Name)

	return meleeStateComponent
end

--[[
	Adds a MeleeState component to an entity through the SystemManagerModule.
	The component is added using the "MeleeState" component name.

	@param Instance | {} entity The entity to add the MeleeState component to.
	@returns any? The MeleeState component that was added, or nil if it could not be added.
]]
function MeleeStateService.AddMeleeStateComponent(entity: Instance | {}): any?
	local entityIsValid = AssertHelper.InvalidArgAssert(
		typeof(entity) == "Instance"
		or type(entity) == "table",
		entity,
		"entity",
		"MeleeStateService.AddMeleeStateComponent",
		"Instance | table"
	)
	if(not entityIsValid) then return nil end

	local meleeStateComponent = SystemManagerModule.AddComponent("MeleeState", entity)
	if(not meleeStateComponent) then return nil end

	MeleeStateComponentSignals.MeleeStateCreated:Fire(meleeStateComponent, entity)

	return meleeStateComponent
end

--[[
	Removes a MeleeState component from an entity through the SystemManagerModule.
	The component is removed using the "MeleeState" component name.
	Fires the MeleeStateRemoved signal with the tool as a parameter.

	@param Instance | {} tool The entity (tool) to remove the MeleeState component from.
	@returns boolean true if the component was removed successfully, false otherwise.
]]
function MeleeStateService.RemoveMeleeStateComponent(tool: Instance | {}): boolean
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		or type(tool) == "table",
		tool,
		"tool",
		"MeleeStateService.RemoveMeleeStateComponent",
		"Instance | table"
	)
	if(not toolIsValid) then return false end

	local componentRemoved = SystemManagerModule.RemoveComponent("MeleeState", tool)
	if(not componentRemoved) then return false end

	MeleeStateComponentSignals.MeleeStateRemoved:Fire(tool)

	return true
end

return MeleeStateService