local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local TerminalConfig = {}

export type TerminalContestState = keyof<typeof(TerminalConfig.terminalContestStates)>
export type TeamsOnTerminalState = keyof<typeof(TerminalConfig.teamsOnTerminalStates)>

TerminalConfig.terminalContestStates = {
	Contesting = {
		Name = "Contesting",
		Value = 0
	},
	GuardsContesting = {
		Name = "GuardsContesting",
		Value = 1
	},
	SubjectsContesting = {
		Name = "SubjectsContesting",
		Value = 2
	},
	Uncontested = {
		Name = "Uncontested",
		Value = 3
	}
}

TerminalConfig.teamsOnTerminalStates = {
	[TeamConfig.teams.Guards.Name] = {
		Name = TeamConfig.teams.Guards.Name,
		Value = 0
	},
	[TeamConfig.teams.Subjects.Name] = {
		Name = TeamConfig.teams.Subjects.Name,
		Value = 1
	},
	NumberOfTeamsOnTerminal = {
		Name = "nTeamsOnTerminal",
		Value = 2
	},
	NoTeamsOnTerminal = {
		Name = "NoTeamsOnTerminal",
		Value = 3
	}
	
}

TerminalConfig.contestStateToTeamsMap = {
	[TerminalConfig.terminalContestStates.GuardsContesting.Name] = TeamConfig.teams.Guards.Team,
	[TerminalConfig.terminalContestStates.SubjectsContesting.Name] = TeamConfig.teams.Subjects.Team
}

TerminalConfig.teamsOnTerminalStateToTeamsMap = {
	[TeamConfig.teams.Guards.Name] = TeamConfig.teams.Guards.Team,
	[TeamConfig.teams.Subjects.Name] = TeamConfig.teams.Subjects.Team
}

TerminalConfig.teamsToContestStateMap = {
	[TeamConfig.teams.Guards.Team] = TerminalConfig.terminalContestStates.GuardsContesting.Name,
	[TeamConfig.teams.Subjects.Team] = TerminalConfig.terminalContestStates.SubjectsContesting.Name
}

TerminalConfig.terminalContestTimeStates = {
	TerminalTimeMaxReached = {
		Name = "TerminalTimeMaxReached",
		Value = 0
	},
	TerminalTimeMinReached = {
		Name = "TerminalTimeMinReached",
		Value = 1
	}
}


TerminalConfig.TIME_TO_CAPTURE = 6

return TerminalConfig
