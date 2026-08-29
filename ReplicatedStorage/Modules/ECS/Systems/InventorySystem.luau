const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const assets = ReplicatedStorage.Assets
const ui = assets.UI
const templates = ui.Templates
const buttons = templates.Buttons
const inventoryFolder = buttons.Inventory
const inventoryItemFrame = inventoryFolder.InventoryItemFrame

const Replica = require("../../Utilities/ReplicaClient")
const clientReplicaConfig = require("../../Shared/Constants/ClientReplicaConfig")
const ClientShopConfig = require("./ClientShopSystem/Config")
const iconModule = require("../../Utilities/TopbarPlus/Icon")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const Promise = require("../../Utilities/Promise")
const t = require("../../Utilities/t")

local InventorySystem = {}

local inventoryUi: ScreenGui? = nil
local playerStatsReplica: any = nil
local inventoryClones: {[string]: Frame} = {}

local checkString = t.string
local checkTable = t.table
local checkInstance = t.instanceIsA("Instance")

const equippedColorSequence: ColorSequence = ColorSequence.new(
	Color3.fromHex("#5A5A5A"),
	Color3.fromHex("#B6B6B6")
)

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

local function IsEquipped(itemType: string, itemName: string): boolean
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
	local equipped = typeData.Equipped
	return equipped == itemName
end

local function ApplyEquippedState(equippedName: string?)
	for _, clone in inventoryClones do
		local preview = clone:FindFirstChild("PreviewContainer")
		if not preview then
			continue
		end
		local titlePrev = preview:FindFirstChild("TitlePreview")
		if not titlePrev then
			continue
		end
		local overlay = titlePrev:FindFirstChild("EquippedOverlayContainer")
		if overlay then
			overlay.Visible = false
		end
	end
	if equippedName ~= nil then
		local checkValid, _ = checkString(equippedName)
		if not checkValid then
			return
		end
		local equippedClone = inventoryClones[equippedName]
		if equippedClone then
			local preview = equippedClone:FindFirstChild("PreviewContainer")
			local titlePrev = nil
			if preview then
				titlePrev = preview:FindFirstChild("TitlePreview")
			end
			local overlay = nil
			if titlePrev then
				overlay = titlePrev:FindFirstChild("EquippedOverlayContainer")
			end
			if overlay then
				overlay.Visible = true
			end
		end
	end
end

local function ClearInventoryItems()
	if not inventoryUi then
		return
	end
	local container = inventoryUi.Container
	local contentPanel = container.ContentPanel
	local itemsContainer = contentPanel.ItemsContainer
	local itemsGrid = itemsContainer.ItemsGrid
	local scrollFrame = itemsGrid.ScrollFrame
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") and child ~= inventoryItemFrame then
			child:Destroy()
		end
	end
	table.clear(inventoryClones)
end

const function SetEquippedOverlayVisible(equippedOverlayFrame: Frame, visible: boolean)
	const frameIsValidFn = t.instanceIsA("Frame")
	const equippedOverlayFrameIsValid, overlayFrameInvalidReason = frameIsValidFn(equippedOverlayFrame)
	if(not equippedOverlayFrameIsValid) then
		AssertHelper.Warn(overlayFrameInvalidReason)
		return
	end
	
	const visibleIsValid, visibleInvalidReason = t.boolean(visible)
	if(not visibleIsValid) then
		AssertHelper.Warn(visibleInvalidReason)
		return
			
	end
	
end

local function InitializeInventoryItem(itemContent: {[string]: any?})
	local contentIsTable, contentInvalid = checkTable(itemContent)
	if not contentIsTable then
		AssertHelper.Warn(contentInvalid)
		return
	end
	local clonedFrame = inventoryItemFrame:Clone()
	local instanceValid, instanceInvalid = checkInstance(itemContent.Content)
	if not instanceValid then
		AssertHelper.Warn(instanceInvalid)
		return
	end
	clonedFrame.Size = UDim2.new(0, 100, 0, 100)
	local clonedTitle = itemContent.Content:Clone()
	clonedTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	clonedTitle.Position = UDim2.new(0.5, 0, 0.5, 0)
	local previewContainer = clonedFrame:WaitForChild("PreviewContainer")
	local titlePreview = previewContainer:WaitForChild("TitlePreview")
	clonedTitle.Parent = titlePreview
	local itemTitle = clonedFrame:WaitForChild("ItemTitle")
	local userFriendly = itemContent.UserFriendlyName
	itemTitle.Text = userFriendly
	
	local equipped = IsEquipped(itemContent.ItemType, itemContent.Name)
	local overlay = titlePreview:FindFirstChild("EquippedOverlayContainer")
	if overlay then
		overlay.Visible = equipped
	end
	
	const function InitializeEquipButton()
		const itemActionButton = previewContainer:WaitForChild("ItemActionButton")
		
		if(not equipped) then
			itemActionButton.Activated:Connect(function()
				print("activated")
			end)	
			return
		end
		
		itemActionButton.Active = not equipped
	end
	Promise.try(function()
		InitializeEquipButton()
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
	local container = inventoryUi.Container
	local contentPanel = container.ContentPanel
	local itemsContainer = contentPanel.ItemsContainer
	local itemsGrid = itemsContainer.ItemsGrid
	local scrollFrame = itemsGrid.ScrollFrame
	clonedFrame.Parent = scrollFrame
	inventoryClones[itemContent.Name] = clonedFrame
end

local function InitializeInventoryElements(itemType: string)
	local typeValid, typeInvalid = checkString(itemType)
	if not typeValid then
		AssertHelper.Warn(typeInvalid)
		return
	end
	ClearInventoryItems()
	local catalog = ClientShopConfig.itemTypeToItemContents[itemType]
	if not catalog then
		return
	end
	local catalogValid, catalogInvalid = checkTable(catalog)
	if not catalogValid then
		AssertHelper.Warn(catalogInvalid)
		return
	end
	for _, itemContent in catalog do
		local name = itemContent.Name
		local typeName = itemContent.ItemType
		local owned = IsOwned(typeName, name)
		if owned then
			InitializeInventoryItem(itemContent)
		end
	end
end

const function InitializeInventoryTopBarButton()
	local topIcon = iconModule.new()
	topIcon:setLabel("Inventory")
	topIcon:setImage(106349093509538)
	topIcon:align("Left")
	topIcon:bindToggleItem(inventoryUi)
	topIcon:setImage(132459917371689)
end

function InventorySystem.Initialize()
	Promise.try(function()
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local uiInstance = playerGui:WaitForChild("Inventory")
		inventoryUi = uiInstance
		inventoryUi.Enabled = false
		InitializeInventoryTopBarButton()

		local container = inventoryUi.Container
		local contentPanel = container.ContentPanel
		local header = contentPanel.ContentHeader
		local titleLabel = header:WaitForChild("TitleLabel")
		local sidebar = container.CategorySidebar
		local titlesButton = sidebar:WaitForChild("TitlesButton")
		
		const function InitializeInventoryCloseButton()
			const inventoryIsValidFn = t.instanceIsA("ScreenGui")
			const inventoryIsValid, inventoryInvalidReason = inventoryIsValidFn(inventoryUi)
			if not inventoryIsValid then
				AssertHelper.Warn(inventoryInvalidReason)
				return
			end

			const contentHeader: Frame = contentPanel:WaitForChild("ContentHeader")
			const closeButton: TextButton = contentHeader:WaitForChild("CloseButton")
			
			closeButton.Activated:Connect(function(_, _)
				inventoryUi.Enabled = false
			end)
		end
		Promise.try(function()
			InitializeInventoryCloseButton()
		end)
			:catch(function(err)
				AssertHelper.Warn(err)
			end)
		
	
		Replica.OnNew(clientReplicaConfig.replicaTokenNames.PlayerStats.Name, function(replica)
			playerStatsReplica = replica
			InitializeInventoryElements("Titles")
			local replicaData = replica.Data
			local replicaItems = nil
			if replicaData then
				replicaItems = replicaData.Items
			end
			local replicaTitles = nil
			if replicaItems then
				replicaTitles = replicaItems.Titles
			end
			local initialEquipped = nil
			if replicaTitles then
				initialEquipped = replicaTitles.Equipped
			end
			ApplyEquippedState(initialEquipped)
			for itemName in ClientShopConfig.titles do
				local path = {"Items", "Titles", "Owned", itemName}
				replica:OnSet(path, function(newValue)
					if newValue == true then
						local cfg = ClientShopConfig.titles[itemName]
						if cfg then
							InitializeInventoryItem(cfg)
						end
					else
						local clone = inventoryClones[itemName]
						if clone then
							clone:Destroy()
							inventoryClones[itemName] = nil
						end
					end
				end)
			end
			local equippedPath = {"Items", "Titles", "Equipped"}
			replica:OnSet(equippedPath, function(newValue)
				ApplyEquippedState(newValue)
			end)
		end)

		titlesButton.Activated:Connect(function()
			titleLabel.Text = "Titles"
			InitializeInventoryElements("Titles")
		end)
	end):catch(function(err)
		AssertHelper.Warn(tostring(err))
	end)
end

return InventorySystem
