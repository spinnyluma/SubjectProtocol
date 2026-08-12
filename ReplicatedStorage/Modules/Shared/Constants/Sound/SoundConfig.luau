local SoundConfig = {}

export type SoundConfig = {
	SoundId: string,
	Volume: number?,
	EmittingPart: BasePart?,
	EmittingPosition: Vector3?
}

return SoundConfig
