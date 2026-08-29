const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules
const Assets = ReplicatedStorage.Assets

const ModulesShared = Modules.Shared
const Utilities = Modules.Utilities
const Helpers = Modules.Helpers

const Shared = Assets.Shared

const Constants = ModulesShared.Constants

const Debug = Helpers.Debug

const Remotes = Shared.Remotes

const Hint = Constants.Hint

const Events = Remotes.Events

const PurchaseItemRE = Events.PurchaseItem
const sendHintRE = Events.SendHint

const ClientShopConfig = require(ReplicatedStorage.Modules.ECS.Systems.ClientShopSystem.Config)
const AssertHelper = require(Debug.AssertHelper)
const HintConfig = require(Hint.HintConfig)
const t = require(Utilities.t)

const PlayerDataService = require("../../Services/PlayerData/PlayerDataService")
const PlayerStatsSystem = require("./PlayerStatsSystem")

local ItemPurchaseSystem = {}

local lastPurchaseTick: {[Player]: number} = {}

const function PurchaseItem(player: Player, itemType: string, itemName: string)
	local playerIsValidFn = t.instanceIsA("Player")
	local playerIsValid, playerInvalidReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return
	end

	local now = tick()
	local lastTick = lastPurchaseTick[player]
	if lastTick and now - lastTick < 0.5 then
		sendHintRE:FireClient(player, "You are doing this too much!", HintConfig.hintColors.Rejection.Name)
		return
	end
	lastPurchaseTick[player] = now

	const profile = PlayerDataService.GetProfile(player)
	local profileIsValid, profileInvalidReason = t.table(profile)
	if not profileIsValid then
		AssertHelper.Warn(profileInvalidReason or `[ItemPurchaseSystem] No profile for {player.Name}`)
		return
	end

	local dataIsValid, dataInvalidReason = t.table(profile.Data)
	if not dataIsValid then
		AssertHelper.Warn(dataInvalidReason)
		return
	end

	const catalog = ClientShopConfig.itemTypeToItemContents[itemType]
	

	local catalogIsValid, catalogInvalidReason = t.table(catalog)
	if not catalogIsValid then

		return
	end

	const item = catalog[itemName]
	const itemIsValid, _ = t.table(item)
	if not itemIsValid then
		return
	end


	local priceIsValid, priceInvalidReason = t.number(item.Price)
	if not priceIsValid then
		return
	end
	

	local tokensIsValid, tokensInvalidReason = t.number(profile.Data.Tokens)
	if not tokensIsValid then
		return
	end
	

	local items = profile.Data.Items
	local itemsIsValid, itemsInvalidReason = t.table(items)
	if not itemsIsValid then
		AssertHelper.Warn(itemsInvalidReason)
		return
	end

	local typeData = items[itemType]
	local typeDataIsValid, typeDataInvalidReason = t.table(typeData)
	if not typeDataIsValid then
		AssertHelper.Warn(typeDataInvalidReason)
		return
	end

	local owned = typeData.Owned
	local ownedIsValid, ownedInvalidReason = t.table(owned)
	if not ownedIsValid then
		AssertHelper.Warn(ownedInvalidReason)
		return
	end

	local itemOwned = owned[itemName]
	if itemOwned then
		sendHintRE:FireClient(player, "You already own this item!", HintConfig.hintColors.Info.Name)
		return
	end

	if profile.Data.Tokens < item.Price then
		const errorMsg = `You do not have enough tokens!`
		sendHintRE:FireClient(player, errorMsg, HintConfig.hintColors.Rejection.Name)
		return
	end

	local tokens = profile.Data.Tokens
	local price = item.Price
	profile.Data.Tokens = tokens - price
	owned[itemName] = true
	sendHintRE:FireClient(player, `Purchase successful!`, HintConfig.hintColors.Success.Name)

	const tokensUpdated = PlayerStatsSystem.SetTokens(player, profile.Data.Tokens)
	if not tokensUpdated then
		AssertHelper.Warn(`[ItemPurchaseSystem] Failed to sync tokens for {player.Name}`)
	end
	const ownedUpdated = PlayerStatsSystem.SetItemOwned(player, itemType, itemName)
	if not ownedUpdated then
		AssertHelper.Warn(`[ItemPurchaseSystem] Failed to sync owned for {player.Name}`)
	end
end

function ItemPurchaseSystem.Initialize()
	PurchaseItemRE.OnServerEvent:Connect(function(player: Player, itemType: string, itemName: string)
		local itemTypeIsValid, itemTypeInvalidReason = t.string(itemType)
		if not itemTypeIsValid then
			AssertHelper.Warn(itemTypeInvalidReason)
			return
		end
		local itemNameIsValid, itemNameInvalidReason = t.string(itemName)
		if not itemNameIsValid then
			AssertHelper.Warn(itemNameInvalidReason)
			return
		end
		PurchaseItem(player, itemType, itemName)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastPurchaseTick[player] = nil
	end)
end

return ItemPurchaseSystem
