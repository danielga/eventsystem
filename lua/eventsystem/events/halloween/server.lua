AddCSLuaFile("shared.lua")
include("shared.lua")

local LMVector = LMVector
if not LMVector then
	LMVector = function() end
end

local positions = {
	LMVector(-438, -356, 185, "armory", true),
	LMVector(-22, -213, 185, "armory", true),
	LMVector(-471, 593, 313, "armory", true),
	LMVector(-1055, 525, 313, "armory", true),
	LMVector(-1291, -281, -8, "minigame", true),
	LMVector(-467, 1679, -8, "lobby", true),
	LMVector(-734, 1317, -8, "lobby", true),
	LMVector(-469, 1267, -8, "lobby", true),
	LMVector(-416, 876, -8, "lobby", true),
	LMVector(24, 1141, -8, "lobby", true),
	LMVector(-204, 799, -8, "lobby", true),
	LMVector(-839, 789, -8, "lobby", true),
	LMVector(-850, 359, -8, "lobby", true),
	LMVector(-700, 885, -8, "lobby", true),
	LMVector(-1001, 124, -8, "lobby", true),
	LMVector(63, 1213, -41, "ccal", true),
	LMVector(-142, 1345, -41, "ccal", true),
	LMVector(55, 1486, -41, "ccal", true),
	LMVector(0, 51, -41, "ccal", true),
	LMVector(-190, -1787, -580, "reactor", true),
	LMVector(193, -1365, -580, "reactor", true),
	LMVector(-498, -898, -580, "reactor", true),
	LMVector(835, -578, -580, "reactor", true),
	LMVector(976, 169, -580, "reactor", true),
	LMVector(1025, 10, -388, "reactor", true),
	LMVector(-979, 162, -580, "reactor", true),
	LMVector(-90, -486, -1540, "reactor", true),
	LMVector(43, 447, -1540, "reactor", true),
	LMVector(145, 141, -388, "reactor", true),
	LMVector(-860, 264, 313, "armory", true),
	LMVector(-868, 430, 313, "armory", true),
	LMVector(250, -223, -8, "lobby", true),
	LMVector(-256, 593, 200, "land_theater", true),
	LMVector(-341, 281, -312, "land_theater", true),
	LMVector(13, -91, -152, "land_theater", true),
	LMVector(-653, 347, -56, "land_theater", true),
	LMVector(-277, -661, -8, "lobby", true),
	LMVector(-463, -673, -8, "lobby", true),
	LMVector(-924, -388, -8, "lobby", true),
	LMVector(167, -590, -8, "lobby", true),
	LMVector(527, 248, 41, "lobby", true),
	LMVector(688, -158, 72, "lobby", true),
	LMVector(-70, 147, 60, "sauna", true),
	LMVector(-310, -1153, -672, "blkbx", true),
	LMVector(1389, -259, 40, "land_theater", true),
	LMVector(947, 524, 40, "land_theater", true),
	LMVector(1174, -56, 40, "land_theater", true),
	LMVector(-41, 146, -520, "blkbx", true),
	LMVector(-1062, 1855, 128, "lobby", true),
	LMVector(-1522, 1184, -8, "lobby", true),
	LMVector(-1715, 553, -12, "lobby", true),
	LMVector(-1051, 1465, 135, "lobby", true)
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
