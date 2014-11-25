AddCSLuaFile("sh_core.lua")
AddCSLuaFile("cl_core.lua")
include("sh_core.lua")

util.AddNetworkString("eventsystem_announce")
util.AddNetworkString("eventsystem_start")
util.AddNetworkString("eventsystem_end")

function eventsystem:Announce(message, duration, recipients)
	net.Start("eventsystem_announce")
		net.WriteString(message)
		net.WriteInt(duration, 16)

	if recipients then
		net.Send(recipients)
	else
		net.Broadcast()
	end
end

--There's 2 types of events as of now: string and event. Should be self explanatory.
function eventsystem:AddScheduled(evtype, data, time)
	if evtype == "string" and #data >= 32672 then
		error("scheduled code string needs to be smaller than 32672 bytes")
	end

	local timetype = type(time)
	if timetype == "table" then
		if not time.year and not time.month and not time.day then
			error("required members year, month and day for the time table given to schedule event didn't exist")
		end

		time = os.time(time)
	elseif timetype ~= "number" then
		error("can't schedule event because provided time is not a valid type (type was " .. timetype .. ")")
	end

	sql.Query("INSERT INTO eventsystem_schedules (Type, Data, Time) VALUES (" .. SQLStr(evtype) .. ", " .. SQLStr(runstring) .. ", " .. time .. ")")
	return tonumber(sql.Query("SELECT LAST_INSERT_ID()"))
end

function eventsystem:RemoveScheduled(number)
	if number then
		sql.Query("DELETE FROM eventsystem_schedules WHERE Number = " .. number)
	else
		MsgN("[Event System] Removing all scheduled events.")
		sql.Query("DELETE * FROM eventsystem_schedules")
	end
end

timer.Create("eventsystem_SchedulesChecker", 1, 0, function()
	local tbl = sql.Query("SELECT * FROM eventsystem_schedules WHERE Time <= strftime('%s', 'now')")
	if not tbl then
		return
	end

	for _, event in pairs(tbl) do
		if event.EventType == "event" then
			self:Start(event.Data)
		else
			RunStringEx(event.Data, "Event System scheduled RunStringEx")
		end

		self:RemoveScheduled(event.Number)
	end
end)

if not sql.TableExists("eventsystem_schedules") then
	sql.Query("CREATE TABLE eventsystem_schedules (Number INT NOT NULL AUTO_INCREMENT, Type VARCHAR(255) NOT NULL, Data TEXT NOT NULL, Time INT NOT NULL, PRIMARY KEY(Number))")
end