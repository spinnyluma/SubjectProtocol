const ReplicatedStorage = game:GetService("ReplicatedStorage")

const NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)

const Signals = {}

Signals.PurchaseRequested = NamedSignal.new()

return Signals