eventsystem = eventsystem or {}

local events = {}
local running_events = {}

function eventsystem:Start(name, ...)
	assert(type(name) == "string", "bad argument #1 (string expected, got " .. type(name) .. ")")

	if self:IsRunning(name) then
		print("[Event System] The event '" .. name .. "' is already running.")
		return false
	end

	local event = self:Get(name)
	if not event then
		error("unknown event called '" .. name .. "'.")
	end

	if event.StartEvent then
		local success, errmsg = pcall(event.StartEvent, event, ...)
		if not success then
			ErrorNoHalt(errmsg)
		end
	end

	table.insert(running_events, event)

	if SERVER then
		net.Start("eventsystem_start")
			net.WriteString(name)
		net.Broadcast()
	end

	return true
end
if CLIENT then
	net.Receive("eventsystem_start", function(len)
		eventsystem:Start(net.ReadString())
	end)
end

function eventsystem:End(first, second, ...)
	local forced, name, skiptwo = false, first, false
	local nametype = type(name)
	if nametype == "boolean" then
		forced = first
		name = second
		skiptwo = true

		assert(type(name) == "string", "bad argument #2 (string expected, got " .. type(name) .. ")")
	else
		assert(nametype == "string", "bad argument #1 (string or boolean expected, got " .. nametype .. ")")
	end

	local event, key = self:GetRunning(name)
	if not event then
		print("the event '" .. name .. "' is not currently active")
		return false
	end

	if event.EndEvent then
		local success, errmsg
		if skiptwo then
			success, errmsg = pcall(event.EndEvent, event, forced, ...)
		else
			success, errmsg = pcall(event.EndEvent, event, forced, second, ...)
		end

		if not success then
			ErrorNoHalt(errmsg)
		end
	end

	table.remove(running_events, key)

	if SERVER then
		net.Start("eventsystem_end")
			net.WriteBit(forced)
			net.WriteString(name)
		net.Broadcast()
	end

	return true
end
if CLIENT then
	net.Receive("eventsystem_end", function(len)
		eventsystem:End(net.ReadBit() == 1, net.ReadString())
	end)
end

local EVENT_META = {}

function EVENT_META:Announce(message, time, recipients)
	eventsystem:Announce(message, time, recipients)
end

function eventsystem:Register(name, tbl)
	local typename, typetbl = type(name), type(tbl)
	assert(typename == "string", "bad argument #1 (string expected, got " .. typename .. ")")
	assert(typetbl == "table", "bad argument #2 (table expected, got " .. typetbl .. ")")

	tbl.EventName = name
	events[name] = setmetatable(tbl, EVENT_META)
end

function eventsystem:Remove(name)
	local event = self:Get(name)
	if event then
		eventsystem:End(true, name)
		events[name] = nil
		return true
	end

	return false
end

function eventsystem:Get(name)
	if name then
		return events[name]
	else
		return events
	end
end

function eventsystem:GetRunning(name)
	if name then
		for i = 1, #running_events do
			local event = running_events[i]
			if event.EventName == name then
				return event, i
			end
		end
	else
		return running_events
	end
end

function eventsystem:IsRunning(name)
	return self:GetRunning(name) ~= nil
end

local files = file.Find("eventsystem/events/*.lua", "LUA")
for _, f in pairs(files) do
	if SERVER then
		AddCSLuaFile("events/" .. f)
	end

	include("events/" .. f)
end