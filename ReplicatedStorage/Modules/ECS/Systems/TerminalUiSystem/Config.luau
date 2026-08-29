local Config = {}

Config.terminalAnnouncementSoundConfigs = {
	TerminalCompromised = {
		Name = "TerminalCompromised",
		SoundConfig = {
			SoundId = "138992130905434",
			Volume = 0.5,
			Children = {
				DistortionSoundEffect = {
					Enabled = true,
					Level = 0.15,
					Priority = 0
				},
				ReverbSoundEffect = {
					Enabled = true,
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
					Priority = 0
				}
			}
		},
		
	}
}

return Config
