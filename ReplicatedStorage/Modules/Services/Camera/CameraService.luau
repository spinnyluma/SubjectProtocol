--!native
--!optimize 2
--
-- CameraService
-- A utility module for managing camera behavior at runtime.
-- Provides validated helpers to set camera position (CFrame) and camera subject.
--
-- Dependencies:
--   - AssertHelper (../../Helpers/Debug/AssertHelper) — warning/assert utility
--   - t (../../Utilities/t) — runtime type checking library
--
-- Usage:
--   local CameraService = require(ReplicatedStorage.Modules.Services.Camera.CameraService)
--   CameraService.SetCameraCframe(workspace.CurrentCamera, CFrame.new(0, 50, 0))
--   CameraService.SetCameraSubject(workspace.CurrentCamera, somePart)

const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const t = require("../../Utilities/t")

const Camera = workspace.CurrentCamera

local CameraService = {}

--
-- Sets a camera's CFrame to the given value.
-- The camera is switched to Scriptable mode before applying the CFrame,
-- so the engine will not override the position with default camera logic.
--
-- @param camera  Camera  — the Camera instance to modify
-- @param cframe  CFrame  — the target CFrame to apply
-- @return void  — logs a warning via AssertHelper if validation fails
function CameraService.SetCameraCframe(camera: Camera, cframe: CFrame)
	const cameraIsValidFn = t.instanceIsA("Camera")
	const cameraIsValid, cameraInvalidReason = cameraIsValidFn(camera)
	if(not cameraIsValid) then
		AssertHelper.Warn(cameraInvalidReason)
		return
	end
	
	const cframeIsValid, cframeInvalidReason = t.CFrame(cframe)
	if(not cframeIsValid) then
		AssertHelper.Warn(cframeInvalidReason)
		return
	end
	
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cframe
end


--
-- Sets the camera's subject to the given Instance and switches the camera
-- to Custom mode so the engine follows the subject with default logic.
--
-- @param camera   Camera   — the Camera instance to modify
-- @param instance Instance  — the target subject (e.g. a Part, Model, or Humanoid)
-- @return void  — logs a warning via AssertHelper if validation fails
function CameraService.SetCameraSubject(camera: Camera, instance: Instance)
	const cameraIsValidFn = t.instanceIsA("Camera")
	const cameraIsValid, cameraInvalidReason = cameraIsValidFn(camera)
	if(not cameraIsValid) then
		AssertHelper.Warn(cameraInvalidReason)
		return
	end
	
	const instanceIsValidFn = t.instanceIsA("Instance")
	const instanceIsValid, instanceInvalidReason = instanceIsValidFn(instance)
	if(not instanceIsValid) then
		AssertHelper.Warn(instanceInvalidReason)
		return
	end
	
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = instance
end

return CameraService
