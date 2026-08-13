local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

const AnimationHelper = require("../../Helpers/Animation/AnimationHelper")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const AssetConfig = require("./AssetConfig")

local rigTemplate = ReplicatedStorage.Assets.Character.Templates.Rig
local animator = rigTemplate:QueryDescendants("Animator")[1]




local ToolConfig = {}

ToolConfig.ALTERNATIVE_ACTION_PAUSE_ATTR_NAME = "A_AlternativeActionPause"

ToolConfig.toolTypes = {
	TwoHandedTool = {
		Name = "TwoHandedTool",
		Value = 0,
		Tag = "T_TwoHandedTool"
	},
	OneHandedTool = {
		Name = "OneHandedTool",
		Value = 0,
		Tag = "T_OneHandedTool"
	}
}

ToolConfig.activatableTools = {
	Pipe = {
		Name = "Pipe",
		Value = 0,
		Tag = "A_Pipe"
	}
}

ToolConfig.promptTools = {
	Handcuffs = {
		Name = "Handcuffs",
		Value = 0
	}
}

ToolConfig.toolAnimationConfigs = {
	Pipe = {
		Name = "Pipe",
		Value = 0,
		WeaponId = "Pipe",
		AttackAnimationId = "79944951544093",
		EquipAnimationId = "121442098089402"
	}
}

ToolConfig.toolCombatConfigs = {
	Pipe = {
		Name = "Pipe",
		AttackAnimationHitboxSpawnMult = 0.533,
		HitboxOffset = Vector3.new(0, 0, -1.875),
		HitboxSize = Vector3.new(3.5, 6.5, 3.5),
		DamageValue = 35,
		Value = 0,
	}
}

local function InitializeAnimationLengths()
	for _, config in ToolConfig.toolAnimationConfigs do
		local attackAnimation = AnimationHelper.LoadAnimation(animator,
			AssetConfig.assetIdPrefix 
				.. config.AttackAnimationId)
		local attackAnimationIsValid = AssertHelper.ExpectedValAssert(
			typeof(attackAnimation) == "Instance"
				and attackAnimation:IsA("AnimationTrack"),
			"AttackAnimation",
			"InitializeAnimationLengths",
			"AnimationTrack"
		)
		if(not attackAnimationIsValid) then return end
		
		local equipAnimation = AnimationHelper.LoadAnimation(animator,
			AssetConfig.assetIdPrefix 
				.. config.EquipAnimationId)
		local equipAnimationIsValid = AssertHelper.ExpectedValAssert(
			typeof(equipAnimation) == "Instance"
				and equipAnimation:IsA("AnimationTrack"),
			"EquipAnimation",
			"InitializeAnimationLengths",
			"AnimationTrack"
		)
		if(not equipAnimationIsValid) then return end
		
		if(attackAnimation) then
			config.AttackAnimationLength = attackAnimation.Length
		end
		if(equipAnimation) then
			config.EquipAnimationLength = equipAnimation.Length
		end
	end
end



InitializeAnimationLengths()
return ToolConfig
