local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicateRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateRay
local CframeHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Cframe
	.CframeHelper)

local CombatService = require(ReplicatedStorage.Modules.Services.Combat.CombatService)

local CombatServiceConfig = require(ReplicatedStorage.Modules.Services.Combat.CombatService.Config)

local tracerTemplate = ReplicatedStorage.Assets.Ray.Templates.TracerTemplate

local TracerSystem = {}

function TracerSystem.Initialize()
	replicateRayRE.OnClientEvent:Connect(function(tracerStartPart: BasePart,
		endPosition: Vector3,
		config: CombatServiceConfig.TracerParams
	)
		if(not tracerStartPart) then return end
		if(not endPosition) then return end
		local tracerStartPosition: Vector3 = tracerStartPart.Position
	
		
		
		CombatService.GenerateRay(tracerTemplate, tracerStartPart.Position,
			endPosition, 
			config
		)
		
	
	end)
end

return TracerSystem
