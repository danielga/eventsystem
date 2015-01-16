AddCSLuaFile("shared.lua")
include("shared.lua")

function EVENT:Think()

end

function EVENT:PlayerDeath(victim, inflictor, killer)

end

function EVENT:OnEnd()
	self:RemoveHooks()

	for _, ply in pairs(player.GetAll()) do
		if table.HasValue(self.Succeeded, ply) then
			ply:GiveCoins(1000, "hunter and hunted event")
			self:Announce("Hunter & Hunted: You successfully killed your quarry!", 15, ply)
		else
			self:Announce("Hunter & Hunted: You failed to kill your quarry!", 15, ply)
		end
	end
end

function EVENT:OnStart()
	self:AddHook("Think", "H&HThink", self.Think)
	self:AddHook("PlayerDeath", "H&HPlayerDeath", self.PlayerDeath)
	self:Announce("Hunter & Hunted: A target has been assigned for you to assassinate!", 15)
end