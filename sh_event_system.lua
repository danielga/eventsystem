eventsystem = eventsystem or {}

local events = {}
local running_events = {}

function eventsystem:StartEvent(name, ...)
	if self:IsEventRunning(name) then
		print("[Event System] The event '" .. name .. "' is already running.")
		return false
	end

	local event = self:GetEvent(name)
	if event == nil then
		error("unknown event called '" .. name .. "'.", 2)
	end

	if isfunction(event.StartEvent) then
		local success, errmsg = pcall(event.StartEvent, event, ...)
		if not success then
			ErrorNoHalt(errmsg)
		end
	end

	table.insert(running_events, event)

	if SERVER then
		net.Start("eventsystem_startevent")
			net.WriteString(event.Name)
		net.Broadcast()
	end

	return true
end
if CLIENT then
	net.Receive("eventsystem_startevent", function(len)
		eventsystem:StartEvent(net.ReadString())
	end)
end

function eventsystem:EndEvent(name, ...)
	local forced = false
	local args = {...}
	if isbool(name) then
		forced = name
		name = args[1]
		table.remove(args, 1)
	end
	
	if not isstring(name) then
		error("an event name to end wasn't provided (as a string)", 2)
	end

	local event, key = self:GetRunningEvent(name)
	if event == nil then
		print("the event '" .. name .. "' is not currently active")
		return false
	end
	
	if isfunction(event.EndEvent) then
		local success, errmsg = pcall(event.EndEvent, event, forced, unpack(args))
		if not success then
			ErrorNoHalt(errmsg)
		end
	end

	event:RemoveHooks()
	table.remove(running_events, key)

	if SERVER then
		net.Start("eventsystem_endevent")
			net.WriteBit(forced)
			net.WriteString(event.Name)
		net.Broadcast()
	end

	return true
end
if CLIENT then
	net.Receive("eventsystem_endevent", function(len)
		eventsystem:EndEvent(net.ReadBit(), net.ReadString())
	end)
end

local EVENT_META = {}

if SERVER then
	function EVENT_META:Announce(recipients, message, time)
		eventsystem:Announce(recipients, message, time)
	end

	function EVENT_META:AnnounceEveryone(message, time)
		eventsystem:AnnounceEveryone(message, time)
	end
else
	function EVENT_META:Announce(message, time)
		eventsystem:Announce(message, time)
	end
end

function eventsystem:RegisterEvent(tbl)
	if not isstring(tbl.Name) then
		error("couldn't register event because table member Name wasn't a string (type was " .. type(tbl.Name) .. ")", 2)
	end

	if tbl.Name == "eventsystem" then
		error("use of forbidden event name 'eventsystem' to register a new event", 2)
	end

	setmetatable(tbl, EVENT_META)
	table.insert(events, tbl)
end

function eventsystem:RemoveEvent(name)
	for k, ev in pairs(events) do
		if ev.Name == name then
			self:EndEvent(true, name)
			table.remove(events, k)
			return true
		end
	end

	return false
end

function eventsystem:GetEvents()
	return events
end

function eventsystem:GetEvent(name)
	for _, event in pairs(events) do
		if event.Name == name then
			return event
		end
	end
end

function eventsystem:GetRunningEvents()
	return running_events
end

function eventsystem:GetRunningEvent(name)
	for k, ev in pairs(running_events) do
		if ev.Name == name then
			return ev, k
		end
	end
end

function eventsystem:IsEventRunning(name)
	for _, event in pairs(running_events) do
		if event.Name == name then
			return true
		end
	end

	return false
end

function eventsystem:SelfDestruct()
	MsgN("[Event System] Destroying Event System.")

	for _, event in pairs(running_events) do
		self:EndEvent(true, event.Name)
	end

	if SERVER then
		net.Start("eventsystem_remove")
		net.Broadcast()
	end

	eventsystem = nil
end
if CLIENT then
	net.Receive("eventsystem_remove", function(len)
		eventsystem:SelfDestruct()
	end)
end

local files = file.Find("metastruct/eventsystem/events/*.lua", "LUA")
for _, f in pairs(files) do
	if SERVER then
		AddCSLuaFile("events/" .. f)
	end

	include("events/" .. f)
end