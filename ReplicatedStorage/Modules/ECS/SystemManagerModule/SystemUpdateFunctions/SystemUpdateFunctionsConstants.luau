local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastSignal = require(ReplicatedStorage.Modules.Framework.FastSignal)

local SystemUpdateFunctionsConstants = {}
SystemUpdateFunctionsConstants.startSystemSignal = FastSignal.new()
SystemUpdateFunctionsConstants.stopSystemSignal = FastSignal.new()
return SystemUpdateFunctionsConstants
