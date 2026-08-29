const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets

const UI = Assets.UI

const Templates = UI.Templates

const Titles = Templates.Titles

local Config = {}

Config.itemTypes = {
	Titles = {
		Name = "Titles",
		Value = 0
	}
}

Config.titles = {
	OperationsDisruptor = {
		Name = "OperationsDisruptor",
		Value = 0,
		UserFriendlyName = "Operations Disruptor",
		ItemType = "Titles",
		Content = Titles.OperationsDisruptorTitle,
		Price = 3000
	},
	SystemError = {
		Name = "SystemError",
		Value = 1,
		UserFriendlyName = "System Error",
		ItemType = "Titles",
		Content = Titles.SystemErrorTitle,
		Price = 3000
	},
	Enforcer = {
		Name = "Enforcer",
		Value = 2,
		UserFriendlyName = "Enforcer",
		ItemType = "Titles",
		Content = Titles.EnforcerTitle,
		Price = 1500
	},
	Unit01 = {
		Name = "Unit01",
		Value = 3,
		UserFriendlyName = "Unit 01",
		ItemType = "Titles",
		Content = Titles.Unit01Title,
		Price = 3000
	},
	Delightful = {
		Name = "Delightful",
		Value = 4,
		UserFriendlyName = "Delightful",
		ItemType = "Titles",
		Content = Titles.DelightfulTitle,
		Price = 1500
	}
}


Config.itemTypeToItemContents = {
	[Config.itemTypes.Titles.Name] = Config.titles
}
return Config
