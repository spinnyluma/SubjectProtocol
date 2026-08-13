const Trove = require("../../Utilities/Trove")

local PromptHandlerComponent = {}

export type PromptHandlerComponent = {
	handlersTrove: Trove.Trove
}

function PromptHandlerComponent.new()
	return {
		handlersTrove = Trove.new()
	}
end

return PromptHandlerComponent
