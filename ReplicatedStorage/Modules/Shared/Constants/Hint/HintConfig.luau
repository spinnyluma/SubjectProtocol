local HintConfig = {}

export type HintColorName = keyof<typeof(HintConfig.hintColors)>

HintConfig.hintColors = {
	["Rejection"] = {
		Name = "Rejection",
		TextColor3 = Color3.fromRGB(255, 67, 60),
		Value = 0
	}
	
}

return HintConfig
