include("sh_core.lua")

local eventsystem = eventsystem
local current_popups = {}

local function popup_ordering(a, b)
	--[[if a.Duration == 0 and b.Duration == 0 then
		return a.Start < b.Start
	elseif a.Duration == 0 or b.Duration == 0 then
		return b.Duration == 0
	end]]

	return a.Start + a.Duration < b.Start + b.Duration
end

local function popup_invalidate()
	table.sort(current_popups, popup_ordering)

	local w = ScrW()

	-- 0.9 is the result of 432 / 480, 432 is the ammo y pos
	-- which is divided by 480, the lowest y resolution supported
	local CurY = 0.9 * ScrH() - 20

	for i = 1, #current_popups do
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

	if duration == 0 then
		return -- no sense showing these messages right now
	end

	local popup = vgui.Create("eventsystem_popup")
	popup:SetMessage(message)
	popup:SetDuration(duration)

	table.insert(current_popups, popup)

	popup_invalidate()

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

----------------------------------------------------------------------------------------

surface.CreateFont("eventsystem_notification",
{
	font = "Arial",
	size = ScreenScale(10),
	weight = 400,
	antialias = true,
	additive = false
})

local messagefont = "eventsystem_notification"
local white = Color(255, 255, 255, 255)
local blue = Color(85, 85, 221, 200)
local green = Color(50, 255, 50, 255)
local red = Color(255, 50, 50, 255)

local PANEL = {}

function PANEL:Init()
	self:SetPos(ScrW(), ScrH())
	self.TargetX = self.x
	self.TargetY = self.y
	self.Start = RealTime()
end

PANEL._Remove = FindMetaTable("Panel").Remove

function PANEL:Remove()
	self:SetDuration(0.001)
end

function PANEL:OnRemove()
	for i = 1, #current_popups do
		if current_popups[i] == self then
			table.remove(current_popups, i)
			popup_invalidate()
			return
		end
	end
end

function PANEL:GetIdentifier()
	return self.Identifier
end

function PANEL:SetIdentifier(id)
	self.Identifier = id
end

function PANEL:SetMessage(message)
	self.Message = message
	self:InvalidateLayout()
end

function PANEL:SetDuration(duration)
	self.Duration = duration
end

local function Approach(cur, target)
    if cur < target then
		return math.Clamp(math.ceil(cur + (target - cur + 1) * FrameTime()), cur, target)
	elseif cur > target then
		return math.Clamp(math.floor(cur - (cur - target + 1) * FrameTime()), target, cur)
	end

	return target
end

function PANEL:Think()
	if --[[self.Duration == 0 or]] RealTime() < self.Start + self.Duration then
		if self.x ~= self.TargetX or self.y ~= self.TargetY then
			self:SetPos(Approach(self.x, self.TargetX), Approach(self.y, self.TargetY))
		end
	else
		if self.x ~= self.TargetX then
			self:SetPos(Approach(self.x, self.TargetX), Approach(self.y, self.TargetY))

			if self.x >= self.TargetX then
				self:_Remove()
			end
		else
			self.TargetX = ScrW()
		end
	end
end

function PANEL:PerformLayout(w, h)
	surface.SetFont(messagefont)
	local w, h = surface.GetTextSize(self.Message)
	self:SetSize(w + 6, h + 6)
	self.TargetX = ScrW() - self:GetWide()
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(blue)
	surface.DrawRect(0, 0, w, h)

	--[[if self.Duration == 0 then
		surface.SetDrawColor(red)
		surface.DrawRect(3, h - 3, w - 6, 2)
	else]]
		surface.SetDrawColor(green)
		surface.DrawRect(3, h - 3, w - w / self.Duration * (RealTime() - self.Start) - 6, 2)
	--end

	surface.SetTextColor(white)
	surface.SetFont(messagefont)
	surface.SetTextPos(3, 2)
	surface.DrawText(self.Message)
end

vgui.Register("eventsystem_popup", PANEL)