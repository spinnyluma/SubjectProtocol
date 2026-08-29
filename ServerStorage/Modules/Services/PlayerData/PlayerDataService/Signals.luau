const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities

const NamedSignal = require(Utilities.NamedSignal)

local Signals = {}

Signals.PlayerDataLoaded = NamedSignal.new()

return Signals
