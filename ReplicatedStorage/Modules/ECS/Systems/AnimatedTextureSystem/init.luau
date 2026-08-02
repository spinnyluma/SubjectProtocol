local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local AnimatedTextureConfig = require(script.Config)

local AnimatedTextureSystem = {}

function AnimatedTextureSystem.Initialize()
	local animatedTextures = CollectionService:GetTagged(AnimatedTextureConfig.SYSTEM_TAG_NAME)
	for _, texture in animatedTextures do
		RunService.PreRender:Connect(function(deltaTime)
			texture.OffsetStudsU = (texture.OffsetStudsU + (deltaTime)) % texture.StudsPerTileU 
		end)
	end
	
	CollectionService:GetInstanceAddedSignal(AnimatedTextureConfig.SYSTEM_TAG_NAME):Connect(function(texture: Texture)
		local animatedTextureSpeed = 0.25
		
		RunService.PreRender:Connect(function(deltaTime)
			texture.OffsetStudsU = (texture.OffsetStudsU + (deltaTime * animatedTextureSpeed))
		end)
	end)
	
end



return AnimatedTextureSystem
