local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local CharacterConfig = require(ReplicatedStorage.Modules.Shared.Constants.CharacterConfig)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local CharacterSystem = {}

local function AddCharacterTag(child: Instance)
	local childIsValid = AssertHelper.InvalidArgAssert(
		typeof(child) == "Instance",
		child,
		"child",
		"AddCharacterTag",
		"Instance"
	)
	if not childIsValid then return end
	
	
	local humanoid = child:FindFirstChildWhichIsA("Humanoid")
	if(not humanoid) then
		return
	end

	local characterTagExists = CollectionService:HasTag(child, CharacterConfig.CHARACTER_TAG_NAME)
	if(characterTagExists) then
		return
	end

	CollectionService:AddTag(child, CharacterConfig.CHARACTER_TAG_NAME)
end
function CharacterSystem.Initialize()
	workspace.DescendantAdded:Connect(AddCharacterTag)
	
	local characterSelector = ":has(Humanoid)"
	local descendants = workspace:QueryDescendants(characterSelector)
	for _, child in descendants do
		AddCharacterTag(child)
	end
end
return CharacterSystem
