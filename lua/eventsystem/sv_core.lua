AddCSLuaFile("sh_core.lua")
AddCSLuaFile("sh_eventmeta.lua")
AddCSLuaFile("cl_core.lua")
AddCSLuaFile("cl_popups.lua")
include("sh_core.lua")

-- fix stupid unannounce name

util.AddNetworkString("eventsystem_sync")
util.AddNetworkString("eventsystem_announce")
util.AddNetworkString("eventsystem_unannounce")
util.AddNetworkString("eventsystem_start")
util.AddNetworkString("eventsystem_end")

local eventsystem = eventsystem
eventsystem.CurrentAnnouncement = eventsystem.CurrentAnnouncement or 0

local active_events = eventsystem.ActiveEvents

local ANNOUNCE_META = {}
ANNOUNCE_META.__index = ANNOUNCE_META

function ANNOUNCE_META:IsValid()
	return self.Valid
end

function ANNOUNCE_META:Remove()
	if not self:IsValid() then
		return
	end

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

	local id = eventsystem.CurrentAnnouncement

	net.Start("eventsystem_announce")
	net.WriteString(message)
	net.WriteUInt(duration, 16)
	net.WriteUInt(id, 32)

	if recipients then
		net.Send(recipients)
	else
		net.Broadcast()
	end

	eventsystem.CurrentAnnouncement = eventsystem.CurrentAnnouncement + 1
	if eventsystem.CurrentAnnouncement >= 4294967296 then
		eventsystem.CurrentAnnouncement = 0
	end

	return setmetatable({Valid = true, Identifier = id, Recipients = recipients}, ANNOUNCE_META)
end

local now = os.time()
local difftime = os.difftime(now, os.time(os.date("!*t", now)))
function eventsystem.LocalTimeToUTC(time)
	return time - difftime
end

function eventsystem.UTCToLocalTime(time)
	return time + difftime
end

function eventsystem.Schedule(evtype, data, time)
	assert(evtype == "string" or evtype == "event", "bad argument #1 to 'Schedule' (string 'event' or 'string' expected, got '" .. tostring(evtype) .. "' of type " .. type(evtype) .. ")")
	assert(type(data) == "string" and (event == "string" and #data <= 32766 or true), "bad argument #2 to 'Schedule' (string with less than 32766 bytes expected, got " .. type(data) .. ")")

	local timetype = type(time)
	if timetype == "table" then
		time = os.time(time)
	elseif timetype ~= "number" then
		error("bad argument #3 to 'Schedule' (table or number expected, got " .. timetype .. ")")
	end

	return tonumber(sql.Query("INSERT INTO 'eventsystem_schedules' ('Type', 'Data', 'Time') VALUES (" .. SQLStr(evtype) .. ", " .. SQLStr(data) .. ", " .. time .. "); SELECT last_insert_rowid() AS LastNumber")[1].LastNumber)
end

function eventsystem.Unschedule(number)
	assert(number == nil or type(number) == "number", "bad argument #1 to 'Unschedule' (nil or number expected, got " .. type(number) .. ")")

	if number then
		sql.Query("DELETE FROM 'eventsystem_schedules' WHERE 'Number' = " .. number)
	else
		MsgN("[Event System] Removing all scheduled events.")
		sql.Query("DELETE * FROM 'eventsystem_schedules'")
	end
end

local last_check = RealTime()
hook.Add("Think", "eventsystem.SchedulesHandler", function()
	if RealTime() < last_check + 1 then
		return
	end

	last_check = RealTime()

	local tbl = sql.Query("SELECT * FROM 'eventsystem_schedules' WHERE Time <= strftime('%s', 'now')")
	if not tbl then
		return
	end

	for i = 1, #tbl do
		local event = tbl[i]
		if event.Type == "event" then
			eventsystem.Start(event.Data)
		else
			RunStringEx(event.Data, "Event System schedule")
		end

		eventsystem.Unschedule(tonumber(event.Number))
	end
end)

if not sql.TableExists("eventsystem_schedules") then
	sql.Query("CREATE TABLE 'eventsystem_schedules' ('Number' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE, 'Type' VARCHAR(255) NOT NULL, 'Data' TEXT NOT NULL, 'Time' INTEGER NOT NULL)")
end

hook.Add("PlayerInitialSpawn", "eventsystem.Synchronize", function(ply)
	net.Start("eventsystem_sync")
	local num = #active_events
	net.WriteUInt(num, 16)
	for i = 1, num do
		local event = active_events[i]
		net.WriteString(event:GetEventName())
		net.WriteUInt(event:GetIdentifier(), 32)
		net.WriteFloat(event:GetStart())
	end
	net.Send(ply)
end)