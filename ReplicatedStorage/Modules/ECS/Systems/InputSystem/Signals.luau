local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)

local Signals = {}

Signals.InputContextEnabledChanged = NamedSignal.new()

return Signals