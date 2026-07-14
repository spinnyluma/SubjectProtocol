local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)

local Signals = {}

Signals.DamageableObjectDamageRequested = NamedSignal.new()

return Signals
