local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local TableHelper = {}

function TableHelper.GetRandomValueFromTable(tableToGetValueFrom: {any?}): any?
	local tableToGetValueFromIsValid = AssertHelper.InvalidArgAssert(
		type(tableToGetValueFrom) == "table",
		tableToGetValueFrom,
		"tableToGetValueFrom",
		"TableHelper.GetRandomValueFromTable",
		"table"
	)
	if(not tableToGetValueFromIsValid) then return nil end
	
	if(#tableToGetValueFrom == 0) then return nil end
	
	local random = Random.new()
	local nextInt = random:NextInteger(1, #tableToGetValueFrom)
	
	return tableToGetValueFrom[nextInt]
end

return TableHelper
