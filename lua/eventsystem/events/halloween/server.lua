AddCSLuaFile("shared.lua")
include("shared.lua")

local positions = {
	-- TODO: Add new locations and maybe use the landmark system
}

local punishment = 1
local nope = "Ah ah ah! You didn't say the magic word!"

function EVENT:CanPlyGoto(ply, ent)
	if ent == self.Gift then
		ply.GIFT_NOPE = CurTime()
		return false, nope
	end
end

function EVENT:AowlTargetCommand(ply, cmd, ent)
	if ent == self.Gift then
		ply.GIFT_NOPE = nil
		ply:ChatPrint(nope)
		ply:Spawn()
	end
end

function EVENT:OnEnd(ply)
	if IsValid(self.Gift) then
		self.Gift:Remove()
		self.Gift = nil
	end

	if IsValid(self.Message) then
		self.Message:Remove()
	end

	if not IsValid(ply) then
		self:Announce("Halloween Gifts: Nobody found the gift.", 5)
		return
	end

	ply:GiveCoins(1000, "halloween gifts event")
	self:Announce(Format("Halloween Gifts: %s found the gift and got rewarded! Congratulations!", ply:GetName()), 15)
end

function EVENT:OnStart()
	self:AddHook("CanPlyGoto", "CanPlyGoto", self.CanPlyGoto)
	self:AddHook("AowlTargetCommand", "AowlTargetCommand", self.AowlTargetCommand)

	local Pos = positions[math.random(1, #positions)]
	self.Gift = ents.Create("base_anim")
	self.Gift:SetModel("models/props_halloween/halloween_gift.mdl")
	self.Gift:SetPos(Pos + Vector(0, 0, 15))
	self.Gift:PhysicsInit(SOLID_VPHYSICS)
	self.Gift:Spawn()
	self.Gift:SetTrigger(true)

	local po = self.Gift:GetPhysicsObject()
	if IsValid(po) then
		po:EnableMotion(false)
	end

	local event = self
	function self.Gift:StartTouch(ent)
		if ent:IsPlayer() and (ent.GIFT_NOPE or 0) + punishment < CurTime() then
			self:Remove()
			event.Gift = nil
			event:End(ent)
		end
	end

	self.Message = self:Announce("Halloween Gifts: A gift has been spawned! Find it to get a reward!", 0)
end
