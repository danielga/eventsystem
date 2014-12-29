AddCSLuaFile("shared.lua")
include("shared.lua")

local positions = {
	Vector(2378, 8948, 13292),
	Vector(3528, 8767, 12264),
	Vector(2579, 9144, 12388),
	Vector(2493, 8946, 12652),
	Vector(2484, 8937, 12908),
	Vector(12800, 137, 12320),
	Vector(12449, -159, 12208),
	Vector(11434, -694, 12208),
	Vector(12545, -1032, 12272),
	Vector(12780, -582, 12208),
	Vector(11147, -540, 12208),
	Vector(9608, -1689, -15348),
	Vector(11128, -1297, -15322),
	Vector(11053, -899, -13298),
	Vector(10746, -1191, -13298),
	Vector(10434, -874, -13170),
	Vector(-2410, -8676, -11824),
	Vector(46, -12046, -11696),
	Vector(-7775, -11330 -8345),
	Vector(-6849, 3558, -10765),
	Vector(-8156, 4184, -12800),
	Vector(-5254, 2713, -133110),
	Vector(-5669, 2221, -14080),
	Vector(-5673, 1219, -13824),
	Vector(-4537, 3427, -15778),
	Vector(-5143, 4478, -15872),
	Vector(-7075, 3770, -15856),
	Vector(-7793, 3777, -15856),
	Vector(-8289, 2552, -15856),
	Vector(-8292, 3318, -15856),
	Vector(-5338, 3240, -15712),
	Vector(-5850, 3241, -15712),
	Vector(-5600, 3939, -15805),
	Vector(-9013, 12926, -13472),
	Vector(-10791, 14377, -13280),
	Vector(-11390, 14298, -13168),
	Vector(-12041, 13023, -13296),
	Vector(-12430, 11617, -13296),
	Vector(-7547, 9612, -2025),
	Vector(-14328, -2747, 13952),
	Vector(-15196, -172, 14320),
	Vector(10470, -8337, 2547),
	Vector(-14852, 92, 14144),
	Vector(-12930, 599, 14304),
	Vector(-14441, 807, 14304),
	Vector(-13663, 3100, 14304),
	Vector(-15150, 2125, 14304),
	Vector(-15805, -738, 14296),
	Vector(-15661, -3105, 14304)
}

function EVENT:OnEnd(ply)
	if IsValid(self.Gift) then
		self.Gift:Remove()
		self.Gift = nil
	end

	if IsValid(self.Message) then
		self.Message:Remove()
	end

	if not IsValid(ply) then
		self:Announce("Christmas Gifts: Nobody found the gift.", 5)
		return
	end

	ply:GiveCoins(1000)
	self:Announce(("Christmas Gifts: %s found the gift and got rewarded! Congratulations!"):format(ply:GetName()), 15)
end

function EVENT:OnStart()
	local Pos = positions[math.random(1, #positions)]
	self.Gift = ents.Create("base_anim")
	self.Gift:SetModel("models/props_halloween/halloween_gift.mdl")
	self.Gift:SetPos(Pos + Vector(0, 0, 15))
	self.Gift:PhysicsInit(SOLID_VPHYSICS)
	self.Gift:Spawn()
	self.Gift:GetPhysicsObject():EnableMotion(false)
	self.Gift:SetTrigger(true)

	function self.Gift.StartTouch(me, ent)
		if ent:IsPlayer() then
			self.Gift:Remove()
			self.Gift = nil
			self:End(ent)
		end
	end

	self.Message = self:Announce("Christmas Gifts: A gift has been spawned! Find it to get a reward!", 0)
end