local assert = assert
local insert = assert(table.insert)
local remove = assert(table.remove)
local pairs = assert(pairs)

Callback = {}

local Callbacks = {
	["Load"] = {},
	["Tick"] = {},
	["Update"] = {},
	["Draw"] = {},
	["UpdateBuff"] = {},
	["RemoveBuff"] = {},
	["ProcessSpell"] = {},
	["CreateObject"] = {},
	["DeleteObject"] = {}
}

Callback.Add = function(type, cb)
	insert(Callbacks[type], cb)
end

Callback.Del = function(type, id)
	remove(Callbacks[type], id or 1)
end

function OnLoad()
	for i, cb in pairs(Callbacks["Load"]) do
		cb()
	end
end

function OnTick()
	for i, cb in pairs(Callbacks["Tick"]) do
		cb()
	end
end

function OnUpdate()
	for i, cb in pairs(Callbacks["Update"]) do
		cb()
	end
end

function OnDraw()
	for i, cb in pairs(Callbacks["Draw"]) do
		cb()
	end
end

function OnUpdateBuff(unit, buff, stacks)
	if unit and buff then
		for i, cb in pairs(Callbacks["UpdateBuff"]) do
			cb(unit, buff, stacks)
		end
	end
end

function OnRemoveBuff(unit, buff)
	if unit and buff then
		for i, cb in pairs(Callbacks["RemoveBuff"]) do
			cb(unit, buff)
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit and spell then
		for i, cb in pairs(Callbacks["ProcessSpell"]) do
			cb(unit, spell)
		end
	end
end

function OnCreateObject(unit)
	if unit then
		for i, cb in pairs(Callbacks["CreateObject"]) do
			cb(unit)
		end
	end
end

function OnDeleteObject(unit)	
	if unit then
		for i, cb in pairs(Callbacks["DeleteObject"]) do
			cb(unit)
		end
	end
end