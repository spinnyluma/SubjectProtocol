-- by Rylvns
-- Last edited on 6/6/25

return function(Emitter)
	local self = {};
	function self:Emit(Configs: {any})
		Emitter:Emit(Configs.Amount, {
			Texture = "",
			Velocity = {{-8, 8}, {6, 12}},
			Direction = {{-1, 1}, -1},
			Gravity = Vector2.new(0, 20),
			Drag = 0,
			LifeTime = 1,
			ZIndex = 100,
			Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 50, 0), NumberSequenceKeypoint.new(1, 50, 40)},
			Squash = 1,
			Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.4, 0.4)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))},
			Transparency = 0,
			Rotation = 0,
			RotationSpeed = 0,
			Properties = {
				Position = Configs.pos,
			},
		}, Configs.Parent);
	end;
	return self;
end; 