AddCSLuaFile("sh_core.lua")
AddCSLuaFile("cl_core.lua")
include("sh_core.lua")

util.AddNetworkString("eventsystem_announce")
util.AddNetworkString("eventsystem_cleanup")
util.AddNetworkString("eventsystem_startevent")
util.AddNetworkString("eventsystem_endevent")
util.AddNetworkString("eventsystem_remove")

function eventsystem:Announce(recipients, message, duration)
	net.Start("eventsystem_announce", recipients)
		net.WriteString(message)
		net.WriteInt(duration, 16)
	net.Send(recipients)
end

function eventsystem:AnnounceEveryone(message, duration)
	self:Announce(player.GetAll(), message, duration)
end

function eventsystem:CleanupClient(player)
	net.Start("eventsystem_cleanup")
	net.Send(player)
end

function eventsystem:CleanupEveryone()
	net.Start("eventsystem_cleanup")
	net.Broadcast()
end

--There's 2 types of events as of now: string and event. Should be self explanatory.
function eventsystem:AddScheduledEvent(evtype, data, time)
	if evtype == "string" and #data >= 32672 then
		error("scheduled code string needs to be smaller than 32672 bytes", 2)
	end

	if istable(time) then
		if not time.year and not time.month and not time.day then
			error("required members year, month and day for the time table given to schedule event didn't exist", 2)
		end

		time = os.time(time)
	elseif not isnumber(time) then
		error("can't schedule event because provided time is not a valid type (type was " .. type(time) .. ")", 2)
	end

	sql.Query("INSERT INTO eventsystem_schedules (Type, Data, Time) VALUES (" .. SQLStr(evtype) .. ", " .. SQLStr(runstring) .. ", " .. time .. ")")
	return tonumber(sql.Query("SELECT LAST_INSERT_ID()"))
end

function eventsystem:RemoveScheduledEvent(number)
	sql.Query("DELETE FROM eventsystem_schedules WHERE Number = " .. number)
end

function eventsystem:RemoveScheduledEvents()
	MsgN("[Event System] Removing all scheduled events.")
	sql.Query("DELETE * FROM eventsystem_schedules")
end

timer.Create("eventsystem_SchedulesChecker", 1, 0, function()
	local tbl = sql.Query("SELECT * FROM eventsystem_schedules WHERE Time <= strftime('%s', 'now')")
	if not tbl then return end

	for _, v in pairs(tbl) do
		if v.EventType == "event" then
			self:StartEvent(v.Data)
		else
			RunStringEx(v.Data, "Event System Scheduled RunStringEx")
		end

		self:RemoveScheduledEvent(v.Number)
	end
end)

if not sql.TableExists("eventsystem_schedules") then
	sql.Query("CREATE TABLE eventsystem_schedules (Number INT NOT NULL AUTO_INCREMENT, Type VARCHAR(255) NOT NULL, Data TEXT NOT NULL, Time INT NOT NULL, PRIMARY KEY(Number))")
end