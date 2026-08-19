const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const TeamConfig = require(Shared.Constants.TeamConfig)
const TableHelper = require(Helpers.Table.TableHelper)
const AssertHelper = require(Helpers.Debug.AssertHelper)
const t = require(Utilities.t)

local SpawnService = {}

--[[
	Reloads the player's character and spawns them at a random spawn
	location that corresponds to their current team.

	- Guards team spawns at a random GuardSpawns location.
	- Subjects team spawns at a random SubjectSpawns location.
	- Any other team (e.g. Choosing) spawns at the default SpawnLocation.

	@param player Player The player whose character should be reloaded.
	@returns boolean? Whether the reload and spawn succeeded.
]]
function SpawnService.ReloadCharacterAndSpawnOnTeamSpawn(player: Player): boolean?
	const playerIsValidFn = t.instanceIsA("Player")

	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	-- Reload the character and capture the newly created character.
	local newCharacter: Model? = nil
	const characterAddedConnection = player.CharacterAdded:Connect(function(character: Model)
		newCharacter = character
	end)
	player:LoadCharacter()

	while(not newCharacter) do
		task.wait()
	end
	characterAddedConnection:Disconnect()

	-- Determine which spawns to use based on the player's current team.
	const playerTeam = player.Team
	local spawnsModel: Model?
	if(playerTeam == TeamConfig.teams.Guards.Team) then
		spawnsModel = workspace.GuardSpawns
	elseif(playerTeam == TeamConfig.teams.Subjects.Team) then
		spawnsModel = workspace.SubjectSpawns
	end

	if(spawnsModel) then
		const spawnsTable = spawnsModel:GetChildren()
		const randomSpawn = TableHelper.GetRandomValueFromTable(spawnsTable)
		if(randomSpawn) then
			newCharacter:PivotTo(randomSpawn.CFrame)
		end
	else
		-- Fallback for teams without a dedicated spawn (e.g. Choosing).
		const defaultSpawn = workspace.SpawnLocation
		if(defaultSpawn) then
			newCharacter:PivotTo(defaultSpawn.CFrame)
		end
	end

	return true
end

return SpawnService
