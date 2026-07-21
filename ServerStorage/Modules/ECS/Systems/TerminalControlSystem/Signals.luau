local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)

local Signals = {}

Signals.TerminalOwnerChanged = NamedSignal.new()
Signals.TerminalOwnerCaptureTimeMaxReached = NamedSignal.new()
Signals.ModeCooldownFinished = NamedSignal.new()
Signals.ModeVoteAvailable = NamedSignal.new()

return Signals
