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

function TableHelper.JoinTables(baseTable: {any?}, ...: {any?})
	local baseTableIsValid = AssertHelper.InvalidArgAssert(
		type(baseTable) == "table",
		baseTable,
		"baseTable",
		"TableHelper.JoinTables",
		"table"
	)
	if(not baseTableIsValid) then return end
	local varArgsTable = {...}
	
	for _, tableToJoin in varArgsTable do
		local tableToJoinIsValid = AssertHelper.ExpectedValAssert(
			type(tableToJoin) == "table",
			tableToJoin,
			"tableToJoin",
			"table"
		)
		if(not tableToJoinIsValid) then continue end
		for _, element in tableToJoin do
			table.insert(baseTable, element)
		end
	end
	return baseTable
end

return TableHelper
