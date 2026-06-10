local DoorConfig = {}

DoorConfig.DOOR_IS_OPEN_ATTR_NAME = "A_DoorIsOpen"
DoorConfig.SECURITY_DOOR_TAG_NAME = "T_SecurityDoor"
DoorConfig.OPEN_DOOR_OFFSET_ATTR_NAME = "A_OpenDoorOffset"

DoorConfig.doorStates = {
	Closed = {
		Name = "Closed",
		Value = 0
	},
	Closing = {
		Name = "Closing",
		Value = 1
	},
	Open = {
		Name = "Open",
		Value = 2
	},
	Opening = {
		Name = "Opening",
		Value = 3
	}
	
}
DoorConfig.DOOR_STATE_ATTR_NAME = "A_DoorState"
DoorConfig.CLOSING_DURATION_ATTR_NAME = "A_ClosingDuration"
return DoorConfig
