local HintConfig = {}

export type HintColorName = keyof<typeof(HintConfig.hintColors)>

HintConfig.hintColors = {
	["Rejection"] = Color3.fromRGB(255, 106, 106),
	
}

return HintConfig
