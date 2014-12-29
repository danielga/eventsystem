eventsystem = eventsystem or {
	Events = {},
	ActiveEvents = {}
}

local eventsystem = eventsystem
local events = eventsystem.Events
local active_events = eventsystem.ActiveEvents

local function eventsystem_Start(name, id, ...)
	local event = eventsystem.Get(name)
	if not event then
		error("unknown event called '" .. name .. "'.")
	end

	if not event.Overlapable and eventsystem.IsActive(name) then
		return
	end

	event = table.Copy(event)
	event.Identifier = id
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
			eventsystem_Start(net.ReadString(), net.ReadUInt(32))
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

local EVENT_META = {}
EVENT_META.__index = EVENT_META

if SERVER then
	function EVENT_META:End(...)
		return eventsystem.End(self.Identifier, ...)
	end
end

function EVENT_META:GetEventName()
	return self.EventName
end

function EVENT_META:GetName()
	return self.Name
end

function EVENT_META:GetIdentifier()
	return self.Identifier
end

function EVENT_META:Announce(message, time, recipients)
	return eventsystem.Announce(message, time, recipients)
end

function EVENT_META:AddHook(name, unique, func)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Hooks[name] then
		self.Hooks[name] = {}
	end

	self.Hooks[name][unique] = true
	hook.Add(name, unique, function(...)
		return func(self, ...)
	end)
end

function EVENT_META:RemoveHook(name, unique)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Hooks[name] or not self.Hooks[name][unique] then
		return
	end

	self.Hooks[name][unique] = nil
	hook.Remove(name, unique)
end

function EVENT_META:RemoveHooks(name)
	if name and not self.Hooks[name] then
		return
	end

	if name then
		for unique, _ in pairs(self.Hooks[name]) do
			hook.Remove(name, unique)
		end

		self.Hooks[name] = nil
	else
		for name, list in pairs(self.Hooks) do
			for unique, _ in pairs(list) do
				hook.Remove(name, unique)
			end
		end

		self.Hooks = {}
	end
end

function EVENT_META:AddTimerSimple(delay, func)
	timer.Simple(delay, function()
		func(self)
	end)
end

function EVENT_META:AddTimer(unique, delay, reps, func)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)

	self.Timers[unique] = true
	timer.Create(unique, delay, reps, function()
		func(self)
	end)
end

function EVENT_META:RemoveTimer(unique)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Timers[unique] then
		return
	end

	self.Timers[unique] = nil
	timer.Remove(unique)
end

function EVENT_META:RemoveTimers()
	for unique, _ in pairs(self.Timers) do
		timer.Remove(unique)
	end

	self.Timers = {}
end

function eventsystem.Register(name, tbl)
	assert(type(name) == "string", "bad argument #1 to 'Register' (string expected, got " .. type(name) .. ")")
	assert(type(tbl) == "table", "bad argument #2 to 'Register' (table expected, got " .. type(tbl) .. ")")

	tbl.EventName = name
	events[name] = setmetatable(tbl, EVENT_META)
end

function eventsystem.Get(name)
	if name then
		return events[name]
	else
		return events
	end
end

function eventsystem.GetActive(arg)
	if type(arg) == "string" then
		local tbl = {}
		for i = 1, #active_events do
			local event = active_events[i]
			if event:GetEventName() == arg then
				table.insert(tbl, event)
			end
		end

		return tbl
	elseif type(arg) == "number" then
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