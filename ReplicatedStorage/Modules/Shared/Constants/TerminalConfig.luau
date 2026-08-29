local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

const HintConfig = require("./Hint/HintConfig")

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
		Name = "NumberOfTeamsOnTerminal",
		Value = 2
	},
	NoTeamsOnTerminal = {
		Name = "NoTeamsOnTerminal",
		Value = 3
	}
	
}

TerminalConfig.terminalOwnerToOwnerMsgMap = {
	[TeamConfig.teams.Guards.Team] = "Terminal secure",
	[TeamConfig.teams.Subjects.Team] = "Subjects are controlling terminal"
}

TerminalConfig.contestStateToTeamsMap = {
	[TerminalConfig.terminalContestStates.GuardsContesting.Name] = TeamConfig.teams.Guards.Team,
	[TerminalConfig.terminalContestStates.SubjectsContesting.Name] = TeamConfig.teams.Subjects.Team
}

TerminalConfig.teamsOnTerminalStateToCapturingMsgMap = {
	[TerminalConfig.teamsOnTerminalStates.NumberOfTeamsOnTerminal.Name] = "Terminal contested",
	[TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name] = "Terminal uncontested",
	[TerminalConfig.teamsOnTerminalStates[TeamConfig.teams.Guards.Name].Name] = "Guards capturing terminal",
	[TerminalConfig.teamsOnTerminalStates[TeamConfig.teams.Subjects.Name].Name] = "Subjects capturing terminal"
}


TerminalConfig.teamsOnTerminalStateToTeamsMap = {
	[TeamConfig.teams.Guards.Name] = TeamConfig.teams.Guards.Team,
	[TeamConfig.teams.Subjects.Name] = TeamConfig.teams.Subjects.Team
}

TerminalConfig.teamsToContestStateMap = {
	[TeamConfig.teams.Guards.Team] = TerminalConfig.terminalContestStates.GuardsContesting.Name,
	[TeamConfig.teams.Subjects.Team] = TerminalConfig.terminalContestStates.SubjectsContesting.Name
}

TerminalConfig.terminalCaptureTimeStates = {
	TerminalCaptureTimeMaxReached = {
		Name = "TerminalCaptureTimeMaxReached",
		Value = 0
	},
	TerminalCaptureTimeMinReached = {
		Name = "TerminalCaptureTimeMinReached",
		Value = 1
	}
}

TerminalConfig.terminalOwnerCaptureTimeStates = {
	TimeMaxReached = {
		Name = "TimeMaxReached",
		Value = 0
	},
	TimeMinReached = {
		Name = "TimeMinReached",
		Value = 1
	}
}

TerminalConfig.captureHints = {
	SubjectsControlling = {
		Name = "SubjectsControlling",
		Hint = "Attention. Terminal control compromised.",
		HintColor = HintConfig.hintColors.Warning.Name
	}
}


TerminalConfig.TIME_TO_CAPTURE = 2
TerminalConfig.TIME_TO_OWN_TERMINAL = 5
return TerminalConfig
