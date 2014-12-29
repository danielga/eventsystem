AddCSLuaFile("sh_core.lua")
AddCSLuaFile("cl_core.lua")
include("sh_core.lua")

-- fix stupid unannounce name

util.AddNetworkString("eventsystem_sync")
util.AddNetworkString("eventsystem_announce")
util.AddNetworkString("eventsystem_unannounce")
util.AddNetworkString("eventsystem_start")
util.AddNetworkString("eventsystem_end")

local eventsystem = eventsystem
local current_announce = 0

local ANNOUNCE_META = {}
ANNOUNCE_META.__index = ANNOUNCE_META

function ANNOUNCE_META:IsValid()
	return self.Valid
end

function ANNOUNCE_META:Remove()
	net.Start("eventsystem_unannounce")
	net.WriteUInt(self.Identifier, 32)

	if self.Recipients then
		net.Send(self.Recipients)
	else
		net.Broadcast()
	end

	self.Valid = false
end

function eventsystem.Announce(message, duration, recipients)
	assert(type(message) == "string", "bad argument #1 to 'Announce' (string expected, got " .. type(message) .. ")")
	assert(type(duration) == "number" and duration >= 0 and duration <= 65535, "bad argument #2 to 'Announce' (number between 0 and 65535 expected, got " .. tostring(duration) .. ", " .. type(duration) .. ")")
	local recipientstype = type(recipients)
	assert(recipientstype == "nil" or recipientstype == "Player" or recipientstype == "table", "bad argument #3 to 'Announce' (nil, Player or table expected, got " .. recipientstype .. ")")

	local id = current_announce

	net.Start("eventsystem_announce")
	net.WriteString(message)
	net.WriteUInt(duration, 16)
	net.WriteUInt(id, 32)

	if recipients then
		net.Send(recipients)
	else
		net.Broadcast()
	end

	current_announce = current_announce + 1
	if current_announce >= 4294967296 then
		current_announce = 0
	end

	return setmetatable({Valid = true, Identifier = id, Recipients = recipients}, ANNOUNCE_META)
end

function eventsystem.Schedule(event, data, time)
	assert(event == "string" or event == "event", "bad argument #1 to 'Schedule' (string 'event' or 'string' expected, got '" .. tostring(event) .. "' of type " .. type(event) .. ")")
	assert(type(data) == "string" and (event == "string" and #data <= 32766 or true), "bad argument #2 to 'Schedule' (string with less than 32766 bytes expected, got " .. type(data) .. ")")

	local timetype = type(time)
	if timetype == "table" then
		assert(time.year and time.month and time.day, "table doesn't have the required members year, month and day")
		time = os.time(time)
	elseif timetype ~= "number" then
		error("bad argument #3 to 'Schedule' (table or number expected, got " .. timetype .. ")")
	end

	sql.Query("INSERT INTO eventsystem_schedules (Type, Data, Time) VALUES (" .. SQLStr(evtype) .. ", " .. SQLStr(data) .. ", " .. time .. ")")
	return tonumber(sql.Query("SELECT LAST_INSERT_ID()"))
end

function eventsystem.Unschedule(number)
	assert(number == nil or type(number) == "number", "bad argument #1 to 'Unschedule' (nil or number expected, got " .. type(number) .. ")")

	if number then
		sql.Query("DELETE FROM eventsystem_schedules WHERE Number = " .. number)
	else
		MsgN("[Event System] Removing all scheduled events.")
		sql.Query("DELETE * FROM eventsystem_schedules")
	end
end

timer.Create("eventsystem.SchedulesHandler", 1, 0, function()
	local tbl = sql.Query("SELECT * FROM eventsystem_schedules WHERE Time <= strftime('%s', 'now')")
	if not tbl then
		return
	end

	for _, event in pairs(tbl) do
		if event.EventType == "event" then
			eventsystem.Start(event.Data)
		else
			RunStringEx(event.Data, "Event System schedule")
		end

		eventsystem.Unschedule(event.Number)
	end
end)

if not sql.TableExists("eventsystem_schedules") then
	sql.Query("CREATE TABLE eventsystem_schedules (Number INT NOT NULL AUTO_INCREMENT, Type VARCHAR(255) NOT NULL, Data TEXT NOT NULL, Time INT NOT NULL, PRIMARY KEY(Number))")
end

local active_events = eventsystem.ActiveEvents
hook.Add("PlayerInitialSpawn", "eventsystem.Synchronize", function(ply)
	net.Start("eventsystem_sync")
	local num = #active_events
	net.WriteUInt(num, 16)
	for i = 1, num do
		local event = active_events[i]
		net.WriteString(event:GetEventName())
		net.WriteUInt(event:GetIdentifier(), 32)
	end
	net.Send(ply)
end)