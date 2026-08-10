const NamedSignal = require("../../../Utilities/NamedSignal")


local Signals = {}

Signals.MeleeStateChanged = NamedSignal.new()
Signals.MeleeStateCreated = NamedSignal.new()
Signals.MeleeStateRemoved = NamedSignal.new()

return Signals
