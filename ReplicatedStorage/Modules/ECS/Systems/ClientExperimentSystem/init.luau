local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local ClientExperimentHandlers = require(script.ClientExperimentHandlers)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local ExperimentConfig = require(ReplicatedStorage.Modules.Shared.Constants.ExperimentConfig)


local startClientExperimentRE = ReplicatedStorage.Assets.Shared.Remotes.Events.StartClientExperiment

local analysisTweenInfo = TweenInfo.new(
	1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	-1,
	true
)


local experimentMachineAnalysisTweens: {[Model]: Tween?} = {}

local ClientExperimentSystem = {}

local function TweenExperimentMachineAnalysis(experimentMachine: Model)
	local experimentMachineIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentMachine) == "Instance"
		and experimentMachine:IsA("Model"),
		experimentMachine,
		"experimentMachine",
		"TweenExperimentMachineAnalysis",
		"Model"
	)
	if not experimentMachineIsValid then return end
	
	Promise.try(function()
		local analysisTweenParts = experimentMachine:WaitForChild("AnalysisTweenParts")
		local analysisPart = analysisTweenParts:WaitForChild("AnalysisPart")
		local analysisStartPart = analysisTweenParts:WaitForChild("AnalysisStartPart")
		local analysisEndPart = analysisTweenParts:WaitForChild("AnalysisEndPart")
		
		
		analysisPart.Transparency = 0
		local tween = TweenService:Create(analysisPart, analysisTweenInfo, {
			CFrame = analysisEndPart.CFrame
		})
		tween:Play()
		experimentMachineAnalysisTweens[experimentMachine] = tween
	end)
		:catch(function(error)
			AssertHelper.Warn(tostring(error))
		end)
end

local function InitializeExperimentMachineTweens()
	local experimentMachines = CollectionService:GetTagged(ExperimentConfig.EXPERIMENT_MACHINE_TAG_NAME)
	
	for _, experimentMachine in experimentMachines do
		experimentMachine:GetAttributeChangedSignal(ExperimentConfig.EXPERIMENT_OPERATING_ATTR_NAME):Connect(function()
			local attribute = experimentMachine:GetAttribute(ExperimentConfig.EXPERIMENT_OPERATING_ATTR_NAME)
			local attributeIsValid = AssertHelper.ExpectedValAssert(
				type(attribute) == "boolean",
				attribute,
				"attribute",
				"boolean"
			)
			if not attributeIsValid then return end
			
			if(attribute) then
				TweenExperimentMachineAnalysis(experimentMachine)
			else
				local currentExperimentMachineAnalysisTween = experimentMachineAnalysisTweens[experimentMachine]
				if(not currentExperimentMachineAnalysisTween) then return end
				
				currentExperimentMachineAnalysisTween:Cancel()
				experimentMachineAnalysisTweens[experimentMachine] = nil
				
				Promise.try(function()
					local analysisTweenParts = experimentMachine:WaitForChild("AnalysisTweenParts")
					local analysisPart: BasePart = analysisTweenParts:WaitForChild("AnalysisPart")
					local analysisStartPart: BasePart = analysisTweenParts:WaitForChild("AnalysisStartPart")
					
					
					analysisPart.Transparency = 1
					analysisPart.Position = analysisStartPart.Position
				end)
					:catch(function(error)
						AssertHelper.Warn(tostring(error))
					end)
			end
		end)
		
	end		
end

function ClientExperimentSystem.Initialize()
	InitializeExperimentMachineTweens()
	
	startClientExperimentRE.OnClientEvent:Connect(function(experimentType: string)
		if(not experimentType) then return end
		
		ClientExperimentHandlers.ExecuteClientExperimentByType(experimentType)
	end)
end

return ClientExperimentSystem
