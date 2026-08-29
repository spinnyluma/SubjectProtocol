local HintConfig = {}

export type HintColorName = keyof<typeof(HintConfig.hintColors)>

HintConfig.hintColors = {
	["Rejection"] = {
		Name = "Rejection",
		TextColor3 = Color3.fromRGB(255, 67, 60),
		Value = 0,
		SoundConfig = {
			SoundId = "87519554692663"
		}
	},
	["Error"] = {
		Name = "Error",
		TextColor3 = Color3.fromRGB(190, 0, 0),
		Value = 1
	},
	["Warning"] = {
		Name = "Warning",
		TextColor3 = Color3.fromRGB(255, 190, 60),
		Value = 2
	},
	["Info"] = {
		Name = "Info",
		TextColor3 = Color3.fromRGB(80, 200, 220),
		Value = 3
	},
	["Success"] = {
		Name = "Success",
		TextColor3 = Color3.fromRGB(0, 188, 38),
		Value = 4,
		SoundConfig = {
			SoundId = "90420386076500"

		}
	}
}

return HintConfig
