-- by Rylvns
-- Last edited on 6/6/25

-- Version 2-ab

--!optimize 2

local self = {
	ShortTextures = {
		["your_texture_name_here"] = "your_texture_id_here",
	},

	DefaultConfigs = { -- Don't change any of these values. :)
		Texture = "",
		Velocity = Vector2.one,
		Direction = Vector2.one,
		Gravity = Vector2.one,
		Drag = 0,
		LifeTime = 5,
		ZIndex = 0,
		Size = 0,
		Squash = 0,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Rotation = 0,
		RotationSpeed = 0,
		Properties = {},
	},
};

local RunService = game:GetService("RunService");

local Camera = workspace.CurrentCamera or nil;

local function Or(Value: any, ...: any): boolean
	for _, _Value in {...} do
		if Value == _Value then
			return true;
		end;
	end;
	return false;
end;

local function RandomNumber(Min: number, Max: number): number
	if Min == Max then return Min end;
	if Min > Max then Min, Max = Max, Min end;
	return Min+(math.random()*(Max-Min));
end;

local function GetRotatedCornerPosition(Position: Vector2, CenterPosition: Vector2, RotationAngle: number): Vector2
	local AngleInRadians = math.rad(RotationAngle);
	local RelativeX = Position.X-CenterPosition.X;
	local RelativeY = Position.Y-CenterPosition.Y;
	return Vector2.new(
		CenterPosition.X+(RelativeX*math.cos(AngleInRadians)-RelativeY*math.sin(AngleInRadians)),
		CenterPosition.Y+(RelativeX*math.sin(AngleInRadians)+RelativeY*math.cos(AngleInRadians)));
end;
local function IsOffScreen(Frame: Frame, ContainerFrame: Frame?): boolean
	local Corners = {
		Frame.AbsolutePosition+Vector2.new(-Frame.AbsoluteSize.X/2, -Frame.AbsoluteSize.Y/2),
		Frame.AbsolutePosition+Vector2.new(Frame.AbsoluteSize.X/2, -Frame.AbsoluteSize.Y/2),
		Frame.AbsolutePosition+Vector2.new(Frame.AbsoluteSize.X/2, Frame.AbsoluteSize.Y/2),
		Frame.AbsolutePosition+Vector2.new(-Frame.AbsoluteSize.X/2, Frame.AbsoluteSize.Y/2),
	};
	for _, Corner in Corners do
		local Point = GetRotatedCornerPosition(Corner, Frame.AbsolutePosition, Frame.Rotation);
		if ContainerFrame and
			((Point.X <= ContainerFrame.AbsolutePosition.X or Point.X >= ContainerFrame.AbsolutePosition.X+ContainerFrame.AbsoluteSize.X)
				or (Point.Y <= ContainerFrame.AbsolutePosition.Y or Point.Y >= ContainerFrame.AbsolutePosition.Y+ContainerFrame.AbsoluteSize.Y))
			or ((Point.X <= 0 or Point.X >= Camera.ViewportSize.X) or (Point.Y <= -200 or Point.Y >= Camera.ViewportSize.Y)) then
			return true;
		end;
	end;
	return false;
end;

local function EvalNumberSequence(NumberSequence: NumberSequence, Time: number): number
	if Or(Time, 0, 1) then
		return NumberSequence.Keypoints[Time == 0 and 1 or #NumberSequence.Keypoints].Value;
	end;
	for Index = 1, #NumberSequence.Keypoints-1 do
		local Keypoint = NumberSequence.Keypoints[Index];
		local NextKeypoint = NumberSequence.Keypoints[Index+1];
		if Time >= Keypoint.Time and Time < NextKeypoint.Time then
			return (Keypoint.Value+(NextKeypoint.Value-Keypoint.Value)*(Time-Keypoint.Time)/(NextKeypoint.Time-Keypoint.Time));
		end;
	end;
end;
local function EvalColorSequence(ColorSequence: ColorSequence, Time: number): Color3
	if Or(Time, 0, 1) then
		return ColorSequence.Keypoints[Time == 0 and 1 or #ColorSequence.Keypoints].Value;
	end;
	for Index = 1, #ColorSequence.Keypoints-1 do
		local Keypoint = ColorSequence.Keypoints[Index];
		local NextKeypoint = ColorSequence.Keypoints[Index+1];
		if Time >= Keypoint.Time and Time < NextKeypoint.Time then
			local Alpha = (Time-Keypoint.Time)/(NextKeypoint.Time-Keypoint.Time);
			local R = Keypoint.Value.R+(NextKeypoint.Value.R-Keypoint.Value.R)*Alpha;
			local G = Keypoint.Value.G+(NextKeypoint.Value.G-Keypoint.Value.G)*Alpha;
			local B = Keypoint.Value.B+(NextKeypoint.Value.B-Keypoint.Value.B)*Alpha;
			return Color3.new(R, G, B);
		end;
	end;
end;

local function EmitParticle(Configs: {any}, Parent: GuiObject): GuiObject
	local SequenceValues = {};
	for Index, Value in Configs do
		if Or(typeof(Value), "NumberSequence", "ColorSequence") then
			SequenceValues[Index] = Value;
		end;
	end;
	
	local HasTexture = not Or(Configs.Texture, "", nil);

	local Particle = Instance.new(HasTexture and "ImageLabel" or "Frame");
	Particle.Name = "";
	Particle.Selectable = false;
	Particle.AnchorPoint = Vector2.new(0.5, 0.5);
	Particle.BorderSizePixel = 0;
	Particle.BackgroundTransparency = HasTexture and 1 or 0;
	if HasTexture then
		Particle.Image = Configs.Texture:match("rbxassetid://(%d+)") and Configs.Texture or (self.ShortTextures[Configs.Texture] or "rbxassetid://1");
	end;
	for Property, Value in Configs.Properties do
		Particle[Property] = Value;
	end;
	Particle.Parent = Parent;

	local Velocity = Configs.Direction.Unit*Configs.Velocity;

	local StartTime = os.clock();
	local Simulation = nil;
	Simulation = RunService.Heartbeat:Connect(function(DeltaTime: number)
		if Particle.Parent then
			for Index, Value in SequenceValues do
				if typeof(Value) == "NumberSequence" then
					Configs[Index] = EvalNumberSequence(Value, (os.clock()-StartTime)/Configs.LifeTime);
				elseif typeof(Value) == "ColorSequence" then
					Configs[Index] = EvalColorSequence(Value, (os.clock()-StartTime)/Configs.LifeTime);
				end;
			end;

			Velocity += Configs.Gravity*DeltaTime;
			Velocity *= (1-Configs.Drag*DeltaTime);

			xpcall(function()
				Particle.Position += UDim2.fromOffset(Velocity.X, Velocity.Y);
				Particle.ZIndex = Configs.ZIndex;
				Particle.Size = UDim2.new(0, Configs.Size*Configs.Squash, 0, Configs.Size/Configs.Squash);
				Particle[Particle.ClassName == "Frame" and "BackgroundColor3" or "ImageColor3"] = Configs.Color;
				Particle[Particle.ClassName == "Frame" and "BackgroundTransparency" or "ImageTransparency"] = Configs.Transparency;
				Particle.Rotation = Configs.Rotation+(Configs.RotationSpeed*DeltaTime);
			end, function()
				Simulation:Disconnect();
			end);

			if os.clock()-StartTime >= Configs.LifeTime-0.01 or IsOffScreen(Particle, Parent.ClassName ~= "ScreenGui" and Parent or nil) then
				Particle:Destroy();
				Simulation:Disconnect();
			end;
		else
			Simulation:Disconnect();
		end;
	end);

	return Particle;
end;

function self:GetPreset(Preset: string): {any}
	assert(typeof(Preset) == "string", ":GetPreset ; Preset argument isn't a string type.");
	local PresetModule = script.Presets:FindFirstChild(Preset);
	assert(PresetModule and PresetModule.ClassName == "ModuleScript", ":GetPreset ; Preset argument isn't located inside the 'Presets' folder.");
	return (require(PresetModule)::()->())(self);
end;

function self:Emit(Amount: number, Configs: {any}, Parent: GuiObject): {any}
	assert(typeof(Amount) == "number", ":Emit ; Amount argument isn't a 'number'.");
	assert(typeof(Configs) == "table", ":Emit ; Configs argument isn't a 'table'.");
	assert(typeof(Parent) == "Instance", ":Emit ; Parent argument isn't a 'Instance'.");

	local Particles = {};
	for _ = 1, Amount do
		local _Configs = table.clone(Configs);
		for Index, Value in _Configs do
			if typeof(Value) == "table" and #Value == 2 then
				if typeof(self.DefaultConfigs[Index]) == "Vector2" then
					local NewValue = {};
					for _Index, _Value in Value do
						if typeof(_Value) == "table" and #_Value == 2 then
							NewValue[_Index] = RandomNumber(_Value[1], _Value[2]);
						else
							NewValue[_Index] = (typeof(_Value) == "number" and _Value)
								or (typeof(_Value) == "table" and _Value[1]) or 1;
						end;
					end;
					_Configs[Index] = Vector2.new(NewValue[1], NewValue[2]);
				elseif Or(typeof(self.DefaultConfigs[Index]), "number", "NumberSequence") then
					_Configs[Index] = RandomNumber(Value[1], Value[2]);
				end;
			end;
			if typeof(Value) == "NumberSequence" then
				local Keypoints = {};
				for _Index, Keypoint in Value.Keypoints do
					Keypoints[_Index] = NumberSequenceKeypoint.new(Keypoint.Time, Keypoint.Value+RandomNumber(-Keypoint.Envelope, Keypoint.Envelope), 0);
				end;
				_Configs[Index] = NumberSequence.new(Keypoints);
			end;
		end;
		table.insert(Particles, EmitParticle(_Configs, Parent));
	end;
	return Particles;
end;

return self;