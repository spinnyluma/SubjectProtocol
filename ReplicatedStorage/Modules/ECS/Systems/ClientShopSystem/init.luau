const ProximityPromptService = game:GetService("ProximityPromptService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Assets = ReplicatedStorage.Assets

const Shared = Assets.Shared
const UI = Assets.UI

const Remotes = Shared.Remotes

const Templates = UI.Templates

const Events = Remotes.Events

const Buttons = Templates.Buttons

const PurchaseItem = Events.PurchaseItem

const Shop = Buttons.Shop

const ShopItemFrame = Shop.ShopItemFrame

const Replica = require("../../Utilities/ReplicaClient")
const ClientReplicaConfig = require("../../Shared/Constants/ClientReplicaConfig")
const ProximityInteractionSignals = require("./ProximityInteractionSystem/Signals")
const ClientShopSystemSignals = require("@self/Signals")
const ClientShopSystemConfig = require("@self/Config")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const Promise = require("../../Utilities/Promise")
const t = require("../../Utilities/t")

local ClientShopSystem = {}

local shopUi: ScreenGui? = nil
local purchaseModal: ScreenGui? = nil
local selectedItemContent: {[string]: any?} = nil
local playerStatsReplica: any = nil
local shopClones: {[string]: Frame} = {}

local function IsOwned(itemType: string, itemName: string): boolean
	if not playerStatsReplica then
		return false
	end
	local data = playerStatsReplica.Data
	if not data then
		return false
	end
	local items = data.Items
	if not items then
		return false
	end
	local typeData = items[itemType]
	if not typeData then
		return false
	end
	local owned = typeData.Owned
	if not owned then
		return false
	end
	return owned[itemName] == true
end

const function DetermineShopUiState(proximityObjectsFound: {[Instance]: Instance?})
	const proximityObjectsFoundIsValid, proximityObjectsFoundInvalidReason = t.table(proximityObjectsFound)
	if not proximityObjectsFoundIsValid then
		AssertHelper.Warn(proximityObjectsFoundInvalidReason)
		return
	end
	if(not shopUi) then
		return
	end
	for shop, objectsFound in proximityObjectsFound do
		for _, character in objectsFound do
			const player = Players:GetPlayerFromCharacter(character)
			if(not player) then
				continue
			end
			
			if(player ~= Players.LocalPlayer) then
				continue
			end
			
			shopUi.Enabled = true
			break
		end
	end
end

const function InitializeUiElements()
	const localPlayer = Players.LocalPlayer
	const playerGui = localPlayer:WaitForChild("PlayerGui")
	shopUi = playerGui:WaitForChild("Shop")
end

const function ClearModalContent()
	if not purchaseModal then return end
	const content = purchaseModal.ModalContainer.Content
	for _, child in content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

const function OpenPurchaseModal(itemContent: {[string]: any?})
	if not purchaseModal then return end
	selectedItemContent = itemContent
	const clonedTitle = itemContent.Content:Clone()
	clonedTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	clonedTitle.Position = UDim2.new(0.5, 0, 0.5, 0)
	clonedTitle.Size = UDim2.new(1, -20, 1, -20)
	clonedTitle.Parent = purchaseModal.ModalContainer.Content
	purchaseModal.Enabled = true
end

const function ClosePurchaseModal()
	if not purchaseModal then return end
	ClearModalContent()
	selectedItemContent = nil
	purchaseModal.Enabled = false
end

const function InitializeShopItemButtonFromItemContent(itemContent: {[string]: any?})
	const itemContentIsValid, itemContentInvalidReason = t.table(itemContent)
	if not itemContentIsValid then
		AssertHelper.Warn(itemContentInvalidReason)
		return
	end
	const clonedShopItemFrame = ShopItemFrame:Clone()
	const instanceIsValid = t.instanceIsA("Instance")
	const contentIsValid, contentInvalidReason = instanceIsValid(itemContent.Content)
	if not contentIsValid then
		AssertHelper.Warn(contentInvalidReason)
		return
	end
	
	clonedShopItemFrame.Size = UDim2.new(0, 200, 0, 80)
	
	const clonedTitle = itemContent.Content:Clone()
	clonedTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	clonedTitle.Position = UDim2.new(0.5, 0, 0.5, 0)
	const shopItemButton = clonedShopItemFrame:WaitForChild("ShopItemButton")
	clonedTitle.Parent = shopItemButton

	const owned = IsOwned(itemContent.ItemType, itemContent.Name)
	const overlay = shopItemButton:WaitForChild("OwnedOverlayContainer")
	overlay.Visible = owned
	shopItemButton.Active = not owned
	shopClones[itemContent.Name] = clonedShopItemFrame
	
	shopItemButton.Activated:Connect(function()
		OpenPurchaseModal(itemContent)
	end)
	
	const itemTitle = clonedShopItemFrame:WaitForChild("ItemTitle")
	itemTitle.Text = itemContent.UserFriendlyName
	const scrollFrame = shopUi.Container.ContentPanel.ItemsContainer.ItemsGrid.ScrollFrame
	clonedShopItemFrame.Parent = scrollFrame
end
const function ClearShopItems()
	const scrollFrame = shopUi.Container.ContentPanel.ItemsContainer.ItemsGrid.ScrollFrame
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") and child ~= ShopItemFrame then
			child:Destroy()
		end
	end
	table.clear(shopClones)
end
const function InitializeShopElements(itemType: string)
	const itemTypeIsValid, itemTypeInvalidReason = t.string(itemType)
	
	if not itemTypeIsValid then
		AssertHelper.Warn(itemTypeInvalidReason)
		return
	end
	
	ClearShopItems()
	
	const itemContents = ClientShopSystemConfig.itemTypeToItemContents[itemType]
	if not itemContents then return end
	
	for _, itemContent in itemContents do
		InitializeShopItemButtonFromItemContent(itemContent)
	end
end

function ClientShopSystem.Initialize()
	Promise.try(function()
		InitializeUiElements()
		
		const localPlayer = Players.LocalPlayer
		const playerGui = localPlayer:WaitForChild("PlayerGui")
		purchaseModal = playerGui:WaitForChild("PurchaseModal")
		purchaseModal.Enabled = false
		
		shopUi.Enabled = false
		
		const closeButton = shopUi.Container.ContentPanel.ContentHeader.CloseButton
		const titlesButton = shopUi.Container.CategorySidebar.TitlesButton
		const titleLabel = shopUi.Container.ContentPanel.ContentHeader.TitleLabel
		
		const modalCloseButton = purchaseModal.ModalContainer.Header.CloseButton
		const purchaseButton = purchaseModal.ModalContainer.PurchaseButton
		
		Replica.OnNew(ClientReplicaConfig.replicaTokenNames.PlayerStats.Name, function(replica)
			playerStatsReplica = replica
			local headerLabel = titleLabel
			headerLabel.Text = "Titles"
			InitializeShopElements("Titles")

			for itemName in ClientShopSystemConfig.titles do
				local path = {"Items", "Titles", "Owned", itemName}
				replica:OnSet(path, function(newValue)
					local clone = shopClones[itemName]
					if not clone then
						return
					end
					local btn = clone:FindFirstChild("ShopItemButton")
					if not btn then
						return
					end
					local overlay = btn:FindFirstChild("OwnedOverlayContainer")
					if overlay then
						overlay.Visible = newValue == true
					end
					btn.Active = newValue ~= true
				end)
			end
		end)
		
		titlesButton.Activated:Connect(function()
			titleLabel.Text = "Titles"
			InitializeShopElements("Titles")
		end)
		
		closeButton.Activated:Connect(function()
			shopUi.Enabled = false
		end)
		
		modalCloseButton.Activated:Connect(function()
			ClosePurchaseModal()
		end)
		
		purchaseButton.Activated:Connect(function()
			if selectedItemContent then
				const itemName = selectedItemContent.Name
				const itemNameIsValid, itemNameInvalidReason = t.string(itemName)
				if not itemNameIsValid then
					AssertHelper.Warn(itemNameInvalidReason)
					return
				end
				const itemType = selectedItemContent.ItemType
				const itemTypeIsValid, itemTypeInvalidReason = t.string(itemType)
				if not itemTypeIsValid then
					AssertHelper.Warn(itemTypeInvalidReason)
					return
				end
				PurchaseItem:FireServer(itemType, itemName)
			end
			ClosePurchaseModal()
		end)
		
		ProximityInteractionSignals.ProximityObjectsFound:Connect(function(interactionType: string,
			proximityObjects: {[Instance]: {Instance}?})
			if interactionType == "T_Shop" then
				DetermineShopUiState(proximityObjects)
			end
		end)
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
end

return ClientShopSystem
