const ServerStorage = game:GetService("ServerStorage")

const ClientReplicaConfig = require("../../Shared/Constants/ClientReplicaConfig")
const NumberFormatter = require("../../Utilities/NumberFormatter")
const InputSystem = require("./InputSystem")
const Replica = require("../../Utilities/ReplicaClient")
const Icon = require("../../Utilities/TopbarPlus/Icon")

local CurrencyUiSystem = {}

local icon: Icon.Icon? = nil
const formatter = NumberFormatter.new({
	decimalPlaces = 1,
	liveUpdate = true
})

const function InitializeCurrencyUiTopBarElement()
	icon = Icon.new()
	
	icon:align("Right")
		:lock()
		:setLabel("0")
		:setImage(72403663699485)
		:modifyTheme({
		--[[
			Allow the icon button's descendants to clip over the icon button's border
			because we want the token icon to clip out
		]]
		{"Menu", "ClipsDescendants", false},
		{"IconButton", "ClipsDescendants", false},
		
		{"Widget", "ClipsDescendants", false},
		--[[
			Allow the label to be placed first in the icon
			because we want the label to be on the left
		]]
		{"IconLabelContainer", "LayoutOrder", 1},
		{"ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Left},
		{"ContentsList", "Padding", UDim.new(0.075, 0)},
		})
		:call(function(icon: Icon.Icon)
			--[[
				Set the padding of the contents list
				because :modifyTheme cannot change the padding of the contentsList
			]]
			const iconButton = icon:getInstance("IconButton")
			const grayBorder = Instance.new("UIStroke")
			const blackBorder = Instance.new("UIStroke")
			grayBorder.Color = Color3.fromRGB(80, 80, 80)
			blackBorder.Color = Color3.fromRGB(10, 10, 10)
			grayBorder.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
			blackBorder.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
			grayBorder.Thickness = 0.08
			blackBorder.Thickness = 0.03
			blackBorder.BorderStrokePosition = Enum.BorderStrokePosition.Outer
			grayBorder.BorderStrokePosition = Enum.BorderStrokePosition.Inner
			blackBorder.Parent = iconButton
			grayBorder.Parent = iconButton
				
				
			const rightAlignmentHolder: ScrollingFrame = icon.alignmentHolder
			rightAlignmentHolder.ClipsDescendants = false
			
			
			
		end)
		:setImageScale(1.4)
end

const function InitializeCurrencyUiHandler()
	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.PlayerStats.Name, function(replica: Replica.Replica)
		const data = replica.Data
		const tokens = data.Tokens
		
		local formattedTokens = formatter:formatNumber(tokens)
		icon:setLabel(formattedTokens)

		replica:OnChange(function(action: string, path: {any}, value: any)
			if action == "Set" and path[1] == "Tokens" then
				formattedTokens = formatter:formatNumber(value)
				icon:setLabel(formattedTokens)
			end
		end)
	end)
end

function CurrencyUiSystem.Initialize()
	InitializeCurrencyUiTopBarElement()
	InitializeCurrencyUiHandler()
end

return CurrencyUiSystem
