local messagefont = "eventsystem_notification"
local white = Color(255, 255, 255, 255)
local blue = Color(85, 85, 221, 200)
local green = Color(50, 255, 50, 255)
local red = Color(255, 50, 50, 255)

surface.CreateFont(messagefont,
{
	font = "Arial",
	size = ScreenScale(10),
	weight = 400,
	antialias = true,
	additive = false
})

local PANEL = {}

function PANEL:Init()
	self:SetPos(ScrW(), ScrH())
	self.TargetX = self.x
	self.TargetY = self.y
	self.Start = CurTime()
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
	if self.Duration == 0 or CurTime() < self.Start + self.Duration then
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

	if self.Duration == 0 then
		surface.SetDrawColor(red)
		surface.DrawRect(3, h - 3, w - 6, 2)
	else
		surface.SetDrawColor(green)
		surface.DrawRect(3, h - 3, w - w / self.Duration * (CurTime() - self.Start) - 6, 2)
	end

	surface.SetTextColor(white)
	surface.SetFont(messagefont)
	surface.SetTextPos(3, 2)
	surface.DrawText(self.Message)
end

vgui.Register("eventsystem_popup", PANEL)