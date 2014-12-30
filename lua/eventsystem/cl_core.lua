include("sh_core.lua")
include("cl_popups.lua")

local eventsystem = eventsystem
eventsystem.CurrentPopups = eventsystem.CurrentPopups or {}

local current_popups = eventsystem.CurrentPopups

local function popup_ordering(a, b)
	if a.Duration == 0 and b.Duration == 0 then
		return a.Start < b.Start
	elseif a.Duration == 0 or b.Duration == 0 then
		return b.Duration == 0
	end

	return a.Start + a.Duration < b.Start + b.Duration
end

function eventsystem.InvalidatePopups(panel)
	local panelvalid = IsValid(panel)
	local num = #current_popups
	for i = 1, num do
		if not IsValid(current_popups[i]) or (panelvalid and current_popups[i] == panel) then
			table.remove(current_popups, i)
			i = i - 1
			num = num - 1
		end
	end

	table.sort(current_popups, popup_ordering)

	local w = ScrW()

	-- 0.9 is the result of 432 / 480, 432 is the ammo y pos
	-- which is divided by 480, the lowest y resolution supported
	local CurY = 0.9 * ScrH() - 20

	for i = 1, num do
		local curpopup = current_popups[i]
		if curpopup.x == w then
			curpopup.y = CurY
		end

		curpopup.TargetY = CurY
		CurY = CurY - curpopup:GetTall() - 4
	end
end

function eventsystem.Announce(message, duration)
	assert(type(message) == "string", "bad argument #1 to 'Announce' (string expected, got " .. type(message) .. ")")
	assert(type(duration) == "number" and duration >= 0 and duration <= 65535, "bad argument #2 to 'Announce' (number between 0 and 65535 expected, got " .. tostring(duration) .. ", " .. type(duration) .. ")")

	local popup = vgui.Create("eventsystem_popup")
	popup:SetMessage(message)
	popup:SetDuration(duration)

	table.insert(current_popups, popup)

	eventsystem.InvalidatePopups()

	return popup
end

net.Receive("eventsystem_announce", function(len)
	local announce = eventsystem.Announce(net.ReadString(), net.ReadUInt(16))
	if announce then
		announce:SetIdentifier(net.ReadUInt(32))
	end
end)

net.Receive("eventsystem_unannounce", function(len)
	local id = net.ReadUInt(32)
	for i = 1, #current_popups do
		local announce = current_popups[i]
		if announce:GetIdentifier() == id then
			announce:Remove()
			return
		end
	end
end)