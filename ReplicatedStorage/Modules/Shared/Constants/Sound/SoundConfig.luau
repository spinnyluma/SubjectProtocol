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
			Volume = 0.25,
		},
		--Ghost = {
		--	SoundId = "136702072604210",
		--	Looped = true,
		--	Volume = 0.25,
		--},
		
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
		}
	},
	Gun = {
		PistolGunshot = {
			SoundId = "127881022189244",
			Volume = 0.5
		},
	}
	
}
return SoundConfig
