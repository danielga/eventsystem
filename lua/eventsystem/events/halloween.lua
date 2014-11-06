local halloween = {}
halloween.Name = "Halloween Hunt"

if CLIENT then
	eventsystem:RegisterEvent(halloween)
	return
end

local positions = {
	Vector(-863, -11234, -13824),
	Vector(616, 1274, -6649),
	Vector(511, 1055, -12864),
	Vector(515, 913, -13056),
	Vector(-689, 1676, -13696),
	Vector(12386, 1140, -13824),
	Vector(15084, 1148, -13056),
	Vector(-12337, 1125, -13824),
	Vector(-15088, 1150, -13056),
	Vector(-6271, 1940, -14944),
	Vector(-2064, -371, -14776),
	Vector(-860, 5767, -13816),
	Vector(1976, 6106, -14272),
	Vector(-2732, 8952, -13552),
	Vector(-979, 8913, -12920),
	Vector(-3418, 6768, -13184),
	Vector(-1039, 8817, 14656),
	Vector(-2079, 8440, 14528),
	Vector(-459, -1736, 12864),
	Vector(-2001, -8859, 13072),
	Vector(181, -1408, 12535),
	Vector(1334, 7190, 14880)
}

halloween.Gift = nil

function halloween:Think()
	if not IsValid(self.Gift) then
		return
	end

	for _, ply in pairs(player.GetAll()) do
		if ply:GetPos():Distance(self.Gift:GetPos()) <= 75 then
			eventsystem:EndEvent(self.Name, ply)
			break
		end
	end
end

function halloween:EndEvent(forced, ply)
	hook.Remove("Think", "halloween.Think")

	if IsValid(self.Gift) then
		self.Gift:Remove()
		self.Gift = nil
	end

	if forced then
		self:AnnounceEveryone("Halloween Gifts: The event was forced to end.", 5)
		return
	end

	ply:GiveCoins(1000)
	self:AnnounceEveryone(Format("Halloween Gifts: %s found the gift and got rewarded! Congratulations!", ply:GetName()), 15)
end

function halloween:StartEvent()
	if IsValid(self.Gift) then
		self.Gift:Remove()
		self.Gift = nil
	end

	local Pos = positions[math.random(1, #positions)]
	self.Gift = ents.Create("prop_physics")
	self.Gift:SetModel("models/props_halloween/pumpkin_loot.mdl")
	self.Gift:SetPos(Pos + Vector(0, 0, 15))
	self.Gift:Spawn()
	self.Gift:GetPhysicsObject():EnableMotion(false)
	self.Gift:SetNotSolid(true)

	hook.Add("Think", "halloween.Think", self.Think)
	self:AnnounceEveryone("Halloween Gifts: A gift has been spawned! Find it to get a reward!", -1)
end

eventsystem:RegisterEvent(halloween)