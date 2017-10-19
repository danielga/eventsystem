AddCSLuaFile("shared.lua")
include("shared.lua")

local SpecialVector = function() end
if LMVector then
	SpecialVector = function(x, y, z, landmark, is_local)
		return LMVector(x, y, z, landmark, is_local):pos()
	end
end

local positions = {
	SpecialVector(-438, -356, 185, "armory", true),
	SpecialVector(-22, -213, 185, "armory", true),
	SpecialVector(-471, 593, 313, "armory", true),
	SpecialVector(-1055, 525, 313, "armory", true),
	SpecialVector(-1291, -281, -8, "minigame", true),
	SpecialVector(-467, 1679, -8, "lobby", true),
	SpecialVector(-734, 1317, -8, "lobby", true),
	SpecialVector(-469, 1267, -8, "lobby", true),
	SpecialVector(-416, 876, -8, "lobby", true),
	SpecialVector(24, 1141, -8, "lobby", true),
	SpecialVector(-204, 799, -8, "lobby", true),
	SpecialVector(-839, 789, -8, "lobby", true),
	SpecialVector(-850, 359, -8, "lobby", true),
	SpecialVector(-700, 885, -8, "lobby", true),
	SpecialVector(-1001, 124, -8, "lobby", true),
	SpecialVector(63, 1213, -41, "ccal", true),
	SpecialVector(-142, 1345, -41, "ccal", true),
	SpecialVector(55, 1486, -41, "ccal", true),
	SpecialVector(0, 51, -41, "ccal", true),
	SpecialVector(-190, -1787, -580, "reactor", true),
	SpecialVector(193, -1365, -580, "reactor", true),
	SpecialVector(-498, -898, -580, "reactor", true),
	SpecialVector(835, -578, -580, "reactor", true),
	SpecialVector(976, 169, -580, "reactor", true),
	SpecialVector(1025, 10, -388, "reactor", true),
	SpecialVector(-979, 162, -580, "reactor", true),
	SpecialVector(-90, -486, -1540, "reactor", true),
	SpecialVector(43, 447, -1540, "reactor", true),
	SpecialVector(145, 141, -388, "reactor", true),
	SpecialVector(-860, 264, 313, "armory", true),
	SpecialVector(-868, 430, 313, "armory", true),
	SpecialVector(250, -223, -8, "lobby", true),
	SpecialVector(-256, 593, 200, "land_theater", true),
	SpecialVector(-341, 281, -312, "land_theater", true),
	SpecialVector(13, -91, -152, "land_theater", true),
	SpecialVector(-653, 347, -56, "land_theater", true),
	SpecialVector(-277, -661, -8, "lobby", true),
	SpecialVector(-463, -673, -8, "lobby", true),
	SpecialVector(-924, -388, -8, "lobby", true),
	SpecialVector(167, -590, -8, "lobby", true),
	SpecialVector(527, 248, 41, "lobby", true),
	SpecialVector(688, -158, 72, "lobby", true),
	SpecialVector(-70, 147, 60, "sauna", true),
	SpecialVector(-310, -1153, -672, "blkbx", true),
	SpecialVector(1389, -259, 40, "land_theater", true),
	SpecialVector(947, 524, 40, "land_theater", true),
	SpecialVector(1174, -56, 40, "land_theater", true),
	SpecialVector(-41, 146, -520, "blkbx", true),
	SpecialVector(-1062, 1855, 128, "lobby", true),
	SpecialVector(-1522, 1184, -8, "lobby", true),
	SpecialVector(-1715, 553, -12, "lobby", true),
	SpecialVector(-1051, 1465, 135, "lobby", true),
	SpecialVector(-392, -491, 412, "lobby", true)
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
	
	-- Find one that actually is in world
	if table.shuffle then 
		table.shuffle(positions)
		for _,pos in next,positions do
			if util.IsInWorld(pos) then
				Pos = pos
				break
			end
		end
	end
	
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
