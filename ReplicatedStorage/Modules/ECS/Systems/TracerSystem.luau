local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicateRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateRay
local CframeHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Cframe
	.CframeHelper)


local TracerSystem = {}

function TracerSystem.Initialize()
	replicateRayRE.OnClientEvent:Connect(function(originPart: BasePart,
		endPosition: Vector3
	)
		if(not originPart) then return end
		
		local originPartPosition: Vector3 = originPart.Position
		
		local cframe1: CFrame = CFrame.new(originPartPosition)
		local cframe2: CFrame = CFrame.new(endPosition)
		
		local midCframe: CFrame? = CframeHelper.GetMidCframe(cframe1, cframe2)
		if(not midCframe) then return end 
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 0.5
		part.Material = Enum.Material.Neon
		part.BrickColor = BrickColor.new("Bright red")
		part.Parent = workspace
		part.CFrame = CFrame.lookAt(midCframe.Position, endPosition)
		
		part.Size = Vector3.new(0.1, 0.1, (originPartPosition - endPosition).Magnitude)
		task.delay(0.1, function()
			part:Destroy()
		end)	
	end)
end

return TracerSystem
