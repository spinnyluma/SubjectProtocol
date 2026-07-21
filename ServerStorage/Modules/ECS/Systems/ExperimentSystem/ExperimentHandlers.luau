local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local remoteEventsFolder = ReplicatedStorage.Assets.Shared.Remotes.Events

local startClientExperimentRE = remoteEventsFolder.StartClientExperiment


local ExperimentHandlers = {}

local function ApplySlide(player: Player)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"ApplySlide",
		"Player"
	)
	if not playerIsValid then return end
	
	startClientExperimentRE:FireClient(player, "Slide")
end

local function ApplyStumble(player: Player)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"ApplyStumble",
		"Player"
	)
	if not playerIsValid then return end
	
	startClientExperimentRE:FireClient(player, "Stumble")
end

local experimentHandlers = {
	["Slide"] = ApplySlide,
	["Stumble"] = ApplyStumble
}

function ExperimentHandlers.ExecuteExperimentByType(player: Player, experimentType: string)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"ExecuteExperimentByType",
		"Player"
	)
	if not playerIsValid then return end
	
	local experimentTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentType) == "string",
		experimentType,
		"experimentType",
		"ExecuteExperimentByType",
		"string"
	)
	if(not experimentTypeIsValid) then return end
	
	local experimentHandler: (Player) -> ()? = experimentHandlers[experimentType]
	local handlerIsValid = AssertHelper.ExpectedValAssert(
		type(experimentHandler) == "function",
		experimentHandler,
		"experimentHandler",
		"function"
	)
	if not handlerIsValid then return end
	
	
	experimentHandler(player)
end

return ExperimentHandlers
