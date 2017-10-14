eventsystem = eventsystem or {
	Events = {},
	ActiveEvents = {}
}

include("sh_eventmeta.lua")

local eventsystem = eventsystem
local events = eventsystem.Events
local active_events = eventsystem.ActiveEvents

local function eventsystem_Start(name, id, ...)
	if eventsystem.GetActive(id) then
		return
	end

	local event = eventsystem.Get(name)
	if not event then
		error("unknown event called '" .. name .. "'")
	end

	if not event.Overlapable and eventsystem.IsActive(name) then
		return
	end

	event = eventsystem.Wrap(table.Copy(event))
	event.Identifier = id
	event.Start = CurTime()
	event.Hooks = {}
	event.Timers = {}

	if event.OnStart then
		event:OnStart(...)
	end

	table.insert(active_events, event)

	return event
end

if SERVER then
	local current_event = 0
	function eventsystem.Start(name, ...)
		assert(type(name) == "string", "bad argument #1 to 'Start' (string expected, got " .. type(name) .. ")")

		local event = eventsystem_Start(name, current_event, ...)
		if not event then
			return
		end

		net.Start("eventsystem_start")
		net.WriteString(name)
		net.WriteUInt(current_event, 32)
		net.WriteTable({...})
		net.Broadcast()

		current_event = current_event + 1
		if current_event >= 4294967296 then
			current_event = 0
		end

		return event
	end
else
	net.Receive("eventsystem_start", function(len)
		eventsystem_Start(net.ReadString(), net.ReadUInt(32), unpack(net.ReadTable()))
	end)

	net.Receive("eventsystem_sync", function(len)
		local num = net.ReadUInt(16)
		for i = 1, num do
			local event = eventsystem_Start(net.ReadString(), net.ReadUInt(32))
			if event then
				event.Start = net.ReadFloat()
			end
		end
	end)
end

local function eventsystem_End(id, ...)
	local event, key = eventsystem.GetActive(id)
	if not event then
		return false
	end

	if event.OnEnd then
		local success, errmsg = pcall(event.OnEnd, event, ...)
		if not success then
			ErrorNoHalt(errmsg)
		end
	end

	event:RemoveHooks()

	table.remove(active_events, key)

	return true
end

if SERVER then
	function eventsystem.End(id, ...)
		assert(type(id) == "number", "bad argument #1 to 'End' (number expected, got " .. type(id) .. ")")

		local success = eventsystem_End(id, ...)
		if success then
			net.Start("eventsystem_end")
			net.WriteUInt(id, 32)
			net.WriteTable({...})
			net.Broadcast()
		end

		return success
	end
else
	net.Receive("eventsystem_end", function(len)
		eventsystem_End(net.ReadUInt(32), unpack(net.ReadTable()))
	end)
end

function eventsystem.Register(name, tbl)
	assert(type(name) == "string", "bad argument #1 to 'Register' (string expected, got " .. type(name) .. ")")
	assert(type(tbl) == "table", "bad argument #2 to 'Register' (table expected, got " .. type(tbl) .. ")")

	tbl.EventName = name
	events[name] = tbl
end

function eventsystem.Get(name)
	if name then
		return events[name]
	else
		return events
	end
end

function eventsystem.GetActive(arg)
	local argtype = type(arg)
	if argtype == "string" then
		local tbl = {}
		for i = 1, #active_events do
			local event = active_events[i]
			if event:GetEventName() == arg then
				table.insert(tbl, event)
			end
		end

		return tbl
	elseif argtype == "number" then
		for i = 1, #active_events do
			local event = active_events[i]
			if event:GetIdentifier() == arg then
				return event, i
			end
		end
	else
		return active_events
	end
end

function eventsystem.IsActive(name)
	for i = 1, #active_events do
		local event = active_events[i]
		if event:GetEventName() == name then
			return true
		end
	end
end

function eventsystem.Load(name, isdir)
	if name then
		if isdir then
			local sv_file = ("eventsystem/events/%s/server.lua"):format(name)
			local sh_file = ("eventsystem/events/%s/shared.lua"):format(name)
			local cl_file = ("eventsystem/events/%s/client.lua"):format(name)

			EVENT = {}

			if SERVER and file.Exists(sv_file, "LUA") then
				include(sv_file)
			elseif CLIENT and file.Exists(cl_file, "LUA") then
				include(cl_file)
			elseif file.Exists(sh_file, "LUA") then
				include(sh_file)
			end

			eventsystem.Register(name, EVENT)
			EVENT = nil
		else
			local sh_file = ("eventsystem/events/sh_%s.lua"):format(name)
			local sv_file = ("eventsystem/events/sv_%s.lua"):format(name)
			local cl_file = ("eventsystem/events/cl_%s.lua"):format(name)

			EVENT = {}

			if file.Exists(sh_file, "LUA") then
				if SERVER then
					AddCSLuaFile(sh_file)
				end

				include(sh_file)
			end

			if SERVER and file.Exists(sv_file, "LUA") then
				include(sv_file)
			end

			if file.Exists(cl_file, "LUA") then
				if CLIENT then
					include(cl_file)
				else
					AddCSLuaFile(cl_file)
				end
			end

			eventsystem.Register(name, EVENT)
			EVENT = nil
		end
	else
		local included_events = {}
		local files, directories = file.Find("eventsystem/events/*", "LUA")
		for _, v in pairs(files) do
			local match = v:match("^%a%a_(%w+)%.lua$")
			if not included_events[match] then
				included_events[match] = true
				eventsystem.Load(match, false)
			end
		end

		for _, v in pairs(directories) do
			if not included_events[v] then
				included_events[v] = true
				eventsystem.Load(v, true)
			end
		end
	end
end

eventsystem.Load()
