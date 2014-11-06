local hunterhunted = {}
hunterhunted.Name = "Hunter & Hunted"

if CLIENT then
	eventsystem:RegisterEvent(hunterhunted)
	return
end

hunterhunted.Succeeded = {}
hunterhunted.PlayerQuarry = {}
hunterhunted.UnassignedQuarries = {}
hunterhunted.Players = {}

function hunterhunted:QuarriesUnassigned()
	return #self.UnassignedQuarries - table.Count(self.PlayerQuarry)
end

function hunterhunted:IsQuarryAssigned(quarry)
	return table.HasValue(self.PlayerQuarry, quarry)
end

function hunterhunted:AssignQuarry(killer)
	local killer, quarry = table.Random(self.UnassignedQuarries)
	table.RemoveByValue(self.UnassignedQuarries, killer)
	self.PlayerQuarry[killer] = quarry
end

function hunterhunted:Think()

end

function hunterhunted:PlayerDeath(victim, inflictor, killer)

end

function hunterhunted:EndEvent(forced)
	if forced then
		self:AnnounceEveryone("The Hunter & Hunted event was forced to end.", 5)
		return
	end

	for _, ply in pairs(player.GetAll()) do
		if table.HasValue(self.Succeeded, ply) then
			ply:GiveCoins(1000)
			self:Announce(ply, "Hunter & Hunted: You successfully killed your quarry!", 15)
		else
			self:Announce(ply, "Hunter & Hunted: You failed to kill your quarry!", 15)
		end
	end
end

function hunterhunted:StartEvent()
	self:AddHook("Think", "H&HThink", self.Think)
	self:AddHook("PlayerDeath", "H&HPlayerDeath", self.PlayerDeath)
	self:AnnounceEveryone("Hunter & Hunted: A target has been assigned for you to assassinate!", 15)
end

eventsystem:RegisterEvent(hunterhunted)