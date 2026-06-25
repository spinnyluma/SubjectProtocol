local Teams = game:GetService("Teams")

local TeamConfig = {}

TeamConfig.teams = {
	Guards = {
		Name = "Guards",
		Team = Teams.Guards,
		Value = 0
	},
	Subjects = {
		Name = "Subjects",
		Team = Teams.Subjects,
		Value = 1
	}
}

return TeamConfig
