const Trove = require("../../Utilities/Trove")

local PromptHandlerComponent = {}

export type PromptHandlerComponent = {
	globalPromptTrove: Trove.Trove,
	handlersTrove: {[Player]: Trove.Trove},
	onDeathCleanupHandlersTroves: {[Player]: Trove.Trove}
}

function PromptHandlerComponent.new()
	return {
		globalPromptTrove = Trove.new(),
		handlersTrove = {},
		onDeathCleanupHandlersTroves = {}
	}
end

return PromptHandlerComponent
