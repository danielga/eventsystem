include("sh_core.lua")

local current_popups = {}

local function popup_ordering(a, b)
	if a.Duration == -1 and b.Duration == -1 then
		return a.Start < b.Start
	elseif a.Duration == -1 or b.Duration == -1 then
		return b.Duration == -1
	end

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

local function popup_create(message, duration)
	local popup = vgui.Create("eventsystem_popup")
	popup:SetMessage(message)
	popup:SetDuration(duration)

	table.insert(current_popups, popup)

	popup_invalidate()
end

function eventsystem:Announce(message, duration)
	popup_create(message, duration)
end

net.Receive("eventsystem_announce", function(len)
	popup_create(net.ReadString(), net.ReadInt(16))
end)

local function popup_removed(panel)
	for i = 1, #current_popups do
		if current_popups[i] == panel then
			table.remove(current_popups, i)
			popup_invalidate()
			return
		end
	end
end

----------------------------------------------------------------------------------------

surface.CreateFont("eventsystem_notification",
{
	font = "Arial",
	size = ScreenScale(12),
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

PANEL.OnRemove = popup_removed

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
	if self.Duration == -1 or RealTime() < self.Start + self.Duration then
		if self.x ~= self.TargetX or self.y ~= self.TargetY then
			self:SetPos(Approach(self.x, self.TargetX), Approach(self.y, self.TargetY))
		end
	else
		if self.x ~= self.TargetX then
			self:SetPos(Approach(self.x, self.TargetX), Approach(self.y, self.TargetY))

			if self.x >= self.TargetX then
				self:Remove()
			end
		else
			self.TargetX = ScrW()
		end
	end
end

function PANEL:PerformLayout(w, h)
	surface.SetFont(messagefont)
	local w, h = surface.GetTextSize(self.Message)
	self:SetSize(w + 4, h + 6)
	self.TargetX = ScrW() - self:GetWide()
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(blue)
	surface.DrawRect(0, 0, w, h)

	if self.Duration == -1 then
		surface.SetDrawColor(red)
		surface.DrawRect(2, h - 3, w - 4, 2)
	else
		surface.SetDrawColor(green)
		surface.DrawRect(2, h - 3, w - w / self.Duration * (RealTime() - self.Start) - 4, 2)
	end

	surface.SetTextColor(white)
	surface.SetFont(messagefont)
	surface.SetTextPos(2, 2)
	surface.DrawText(self.Message)
end

vgui.Register("eventsystem_popup", PANEL)