const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Teams = game:GetService("Teams")

const Modules = ReplicatedStorage.Modules

const Helpers = Modules.Helpers
const Shared = Modules.Shared

const DataModel = Helpers.DataModel
const Debug = Helpers.Debug
const Table = Helpers.Table

const Constants = Shared.Constants

const DictionaryHelper = require(Table.DictionaryHelper)
const DataModelHelper = require(DataModel.DataModelHelper)
const AssertHelper = require(Debug.AssertHelper)

const SearchableSystemConfig = require("@self/Config")

const ProximityPromptService = game:GetService("ProximityPromptService")
const Constants = Shared.Constants

const subjectsTeam = Teams.Subjects

const SearchableConfig = require(Constants.SearchableConfig)


local SearchableSystem = {}

local availableItems = {
	[SearchableSystemConfig.tools.Pipe.Name] = true,
	[SearchableSystemConfig.tools.SecurityDoorKeycard.Name] = true,
	[SearchableSystemConfig.tools.Pistol.Name] = true
}

local emptyContainers: {Instance?} = {}
local filledContainers: {[Instance]: Instance?} = {}

local totalNumberOfContainers = -1
local filledContainerRatio = 2/3

const CONTAINER_FILL_DELAY = 5

local function FillContainer(container: Model)
	const containerIsValid = AssertHelper.InvalidArgAssert(
		typeof(container) == "Instance"
			and container:IsA("Model"),
		container,
		"container",
		"SearchableSystem.FillContainer",
		"Model"
	)
	if(not containerIsValid) then return end
	
	local emptyContainerIndex = table.find(emptyContainers, container)
	if(not emptyContainerIndex) then return end
	
	const randomItemKeyString = DictionaryHelper.GetRandomKeyFromDict(availableItems)
	const randomItemEnum = SearchableSystemConfig.tools[randomItemKeyString]
	const randomItemEnumIsValid = AssertHelper.ExpectedValAssert(
		type(randomItemEnum) == "table",
		randomItemEnum,
		"randomItemEnum",
		"SearchableSystem.FillContainer",
		"Instance"
	)
	if(not randomItemEnumIsValid) then return end
	const randomItemInstance = randomItemEnum.Tool
	
	
	const emptyContainer = emptyContainers[emptyContainerIndex]

	filledContainers[emptyContainer] = randomItemInstance
	table.remove(emptyContainers, emptyContainerIndex)
	
end

local function InitializeEmptyContainers()
	emptyContainers = CollectionService:GetTagged(SearchableConfig.SEARCHABLE_TAG_NAME)
end

local function FillRandomContainer(random: Random)
	const randomIsValid = AssertHelper.InvalidArgAssert(
		typeof(random) == "Random",
		random,
		"random",
		"SearchableSystem.FillRandomContainer",
		"Random"
	)
	if(not randomIsValid) then return end
	const randomEmptyContainerIndex = random:NextInteger(1, #emptyContainers)
	local randomEmptyContainer = emptyContainers[randomEmptyContainerIndex]
	FillContainer(randomEmptyContainer)
end

local function FillRandomEmptyContainers()
	const nmbOfContainersToFill = math.floor(#emptyContainers * filledContainerRatio)
	
	const random = Random.new()
	for i = 1, nmbOfContainersToFill do
		FillRandomContainer(random)
	end

end

local function InitializeSearchableContainers()
	local searchableContainers = CollectionService:GetTagged(SearchableConfig.SEARCHABLE_TAG_NAME)
	totalNumberOfContainers = #searchableContainers
	
	InitializeEmptyContainers()
	FillRandomEmptyContainers()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		if(playerWhoTriggered.Team ~= subjectsTeam) then return end
		local searchableContainer = DataModelHelper.GetRootParentWithTag(prompt, SearchableConfig.SEARCHABLE_TAG_NAME)
		if(not searchableContainer) then return end
		
		local itemInstance = filledContainers[searchableContainer]
		print(itemInstance)
		if(not itemInstance) then return end
		
		local itemInstanceIsValid = AssertHelper.ExpectedValAssert(
			typeof(itemInstance) == "Instance",
			itemInstance,
			"itemInstance",
			"SearchableSystem.InitializeSearchableContainers",
			"Instance"
		)
		if(not itemInstanceIsValid) then return end
		
		local clonedInstance = itemInstance:Clone()
		clonedInstance.Parent = playerWhoTriggered.Backpack
		filledContainers[searchableContainer] = nil
		table.insert(emptyContainers, searchableContainer)
		task.delay(CONTAINER_FILL_DELAY, function()
			FillContainer(searchableContainer)
		end)
	end)
end

function SearchableSystem.Initialize()
	InitializeSearchableContainers()
end

return SearchableSystem
