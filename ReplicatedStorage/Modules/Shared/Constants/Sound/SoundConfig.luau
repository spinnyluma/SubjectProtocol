local SoundConfig = {}

export type SoundConfig = {
	SoundId: string,
	Volume: number?,
	EmittingPart: BasePart?,
	EmittingPosition: Vector3?,
	Looped: boolean?,
	Children: {[string]: any?}?
}

SoundConfig.clientSoundConfigs = {
	Action = {
		Exfiltrate = {
			SoundId = "139980780754211",
			Looped = true,
			Volume = 0.5,
		},
		Ghost = {
			SoundId = "136702072604210",
			Looped = true,
			Volume = 0.5,
		},
	},
	Environment = {
		Siren = {
			SoundId = "139859524926265",
			Looped = true,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 100,
			Volume = 0.4,
			--Children = {
			--	PitchShiftSoundEffect = {
			--		Octave = 0.8
			--	}
			--}
		},
		MetalDoorOpen = {
			SoundId = "7024302454",
			Volume = 0.5,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 50,
		},
		KeycardUnlock = {
			SoundId = "102049975232975",
			RollOffMinDistance = 10,
			RollOffMaxDistance = 50,
		}
	},
	Gun = {
		PistolGunshot = {
			SoundId = "127881022189244",
			Volume = 0.5
		},
		PistolReload = {
			SoundId = "127374386997069",
			Volume = 0.5
		},
		TurretShot = {
			SoundId = "138074730724614",
			Volume = 0.5,			
		}
	},
	Announcement = {
		
		TurretOverrideAnnouncementVoice = {
			SoundId = "134276280202109",
			Volume = 0.5,
			Children = {
				ReverbSoundEffect = {
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
				},
				DistortionSoundEffect = {
					Level = 0.15,
				},
			},
		},
		SystemFacilityRestored = {
			SoundId = "108061868879937",
			Volume = 0.5,
			Children = {
				DistortionSoundEffect = {
					Level = 0.15,
				},
				ReverbSoundEffect = {
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
				},
			},
		},
		TerminalControlHasBeenCompromised = {
			SoundId = "138992130905434",
			Volume = 0.5,
			Children = {
				DistortionSoundEffect = {
					Level = 0.15,
				},
				ReverbSoundEffect = {
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
				},
			},
		},
		FacilityBombardmentAnnouncement = {
			SoundId = "120233428353090",
			Volume = 0.5,
			Children = {
				ReverbSoundEffect = {
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
				},
				DistortionSoundEffect = {
					Level = 0.15,
				},
			},
		},
		RoleReversalAnnouncement = {
			SoundId = "124643941714688",
			Volume = 0.5,
			Children = {
				DistortionSoundEffect = {
					Level = 0.15,
				},
				ReverbSoundEffect = {
					DecayTime = 1.5,
					Density = 0.5,
					Diffusion = 1,
					DryLevel = 0,
					WetLevel = 0,
				},
			},
		},
	}
	
}
return SoundConfig
