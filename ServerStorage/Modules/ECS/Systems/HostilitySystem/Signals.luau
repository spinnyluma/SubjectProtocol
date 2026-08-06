local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)

local Signals = {}

Signals.HostilityRequested = NamedSignal.new()

return Signals
