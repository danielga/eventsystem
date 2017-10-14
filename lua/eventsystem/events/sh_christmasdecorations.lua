EVENT.Name = "Christmas Decorations"
EVENT.Overlapable = false -- this is implied if not explicit

if SERVER then
	return
end

local ShouldDraw = true
CreateClientConVar("christmas_decorations", 1, true, false)
cvars.AddChangeCallback("christmas_decorations", function(name, old, new)
	local newbool = tonumber(new)
	if newbool then
		ShouldDraw = newbool ~= 0
	end
end)

local MaximumDistance = 2000 ^ 2
CreateClientConVar("christmas_drawdistance", 2000, true, false)
cvars.AddChangeCallback("christmas_drawdistance", function(name, old, new)
	local newdist = tonumber(new)
	if newdist then
		MaximumDistance = newdist ^ 2
	end
end)

local RopeMat = Material("cable/cable2")
local GlowMat = Material("sprites/light_glow02_add")

local RopeColor = Color(50, 255, 50)

local Lights, LightsDraw
local LastLightsUpdate = 0

local Bulp, BulpHolder, Holder

local math_random, HSVToColor, table_insert = math.random, HSVToColor, table.insert
function EVENT:LightsThink()
	if not ShouldDraw then
		return
	end

	local curtime = CurTime()
	local update = curtime - LastLightsUpdate >= 1
	if update then
		LastLightsUpdate = curtime
	end

	LightsDraw = {}
	local plypos = LocalPlayer():GetPos()
	for i = 1, #Lights do
		local lights = Lights[i]
		if plypos:DistToSqr(lights.MiddlePos) > MaximumDistance then
			continue
		end

		if update then
			for k = 2, #lights - 1 do
				local light = lights[k]
				local hue = math_random(360)
				light.Col = HSVToColor(hue, 0.5, 1)
				light.ColFullSat = HSVToColor(hue, 1, 1)
			end
		end

		table_insert(LightsDraw, lights)
	end
end

local util_PixelVisible = util.PixelVisible
local render_SetMaterial, render_StartBeam, render_AddBeam = render.SetMaterial, render.StartBeam, render.AddBeam
local render_EndBeam, render_SetBlend, render_SetColorModulation = render.EndBeam, render.SetBlend, render.SetColorModulation
local render_SetColorModulation, render_DrawSprite = render.SetColorModulation, render.DrawSprite
function EVENT:LightsDraw(depth, skybox)
	if depth or skybox or not ShouldDraw then
		return
	end

	local localplayer = LocalPlayer()
	local plypos = localplayer:GetPos()
	local eyepos = localplayer:EyePos()
	for i = 1, #LightsDraw do
		local lights = LightsDraw[i]
		local count = #lights

		local first = lights[1]
		local last = lights[count]

		render_SetMaterial(RopeMat)
		render_StartBeam(count)
		render_AddBeam(first.Pos, 0.6, 0, RopeColor)

		for k = 2, count - 1 do
			local light = lights[k]
			render_AddBeam(light.Pos, 0.6, 0, light.ColFullSat)
		end

		render_AddBeam(last.Pos, 0.6, 0, RopeColor)
		render_EndBeam()

		Holder:SetRenderOrigin(first.Pos)
		Holder:SetRenderAngles(first.Ang)
		Holder:SetupBones()
		Holder:DrawModel()

		for k = 2, count - 1 do
			local light = lights[k]
			local pos = light.ModelPos
			local visible = util_PixelVisible(pos, 15, light.PixVis)
			if visible == 0 then
				continue
			end

			local ang = light.Ang
			local colfullsat = light.ColFullSat
			local col = light.Col
			local spritepos = light.SpritePos

			render_SetBlend(1)
				render_SetColorModulation(colfullsat.r * 0.002, colfullsat.g * 0.002, colfullsat.b * 0.002)	
					BulpHolder:SetRenderOrigin(pos)
					BulpHolder:SetRenderAngles(ang)
					BulpHolder:SetupBones()
					BulpHolder:DrawModel()
				render_SetColorModulation(1, 1, 1)
			render_SetBlend(0)

			render_SetMaterial(GlowMat)
			local vis40 = 40 * visible
			render_DrawSprite(spritepos, vis40, vis40, col)
			local vis30 = 30 * visible
			render_DrawSprite(spritepos, vis30, vis30, col)
			local vis20 = 20 * visible
			render_DrawSprite(spritepos, vis20, vis20, col)

			render_SetBlend(0.8)
				render_SetColorModulation(colfullsat.r, colfullsat.g, colfullsat.b)
					Bulp:SetRenderOrigin(pos)
					Bulp:SetRenderAngles(ang)
					Bulp:SetupBones()
					Bulp:DrawModel()
				render_SetColorModulation(1, 1, 1)
			render_SetBlend(1)
		end

		Holder:SetRenderOrigin(last.Pos)
		Holder:SetRenderAngles(last.Ang)
		Holder:SetupBones()
		Holder:DrawModel()
	end
end

local Directions = {
	Vector(-1, -1, -1), Vector(-1, -1, 0), Vector(-1, -1, 1),
	Vector(-1, 0, -1), Vector(-1, 0, 0), Vector(-1, 0, 1),
	Vector(-1, 1, -1), Vector(-1, 1, 0), Vector(-1, 1, 1),
	Vector(0, -1, -1), Vector(0, -1, 0), Vector(0, -1, 1),
	Vector(0, 0, -1), Vector(0, 0, 0), Vector(0, 0, 1),
	Vector(0, 1, -1), Vector(0, 1, 0), Vector(0, 1, 1),
	Vector(1, -1, -1), Vector(1, -1, 0), Vector(1, -1, 1),
	Vector(1, 0, -1), Vector(1, 0, 0), Vector(1, 0, 1),
	Vector(1, 1, -1), Vector(1, 1, 0), Vector(1, 1, 1)
}

local function GetHitnormalFromPos(point, length)
	local angle = Angle(0, 0, 0)
	
	for _, vector in pairs(Directions) do
		local trace = util.QuickTrace(point, vector * length)
		if trace.Hit then
			angle = trace.HitNormal:Angle()
			break
		end
	end
	
	return angle
end

local function AddLights(vec1, vec2, lights, addlength)
	local height = 180 / (lights + 1)
	local lerp = (vec1 - vec2) / (lights + 1)

	local tab = {}

	local angle = GetHitnormalFromPos(vec2, 5)

	angle:RotateAroundAxis(Angle(0, 180, 100):Forward(), -50)

	table.insert(tab, {Pos = vec1, Ang = angle})

	for i = 1, lights do
		local pos = vec1 + lerp * -i
		pos.z = pos.z - (math.sin(math.rad(height * i)) * addlength)
		local ang = AngleRand() * 0.05
		local offset = Vector(0, 0, -6)
		offset:Rotate(ang)
		local model_pos = pos + offset
		local hue = math.random(360)
		table.insert(tab, {
			Pos = pos,
			ModelPos = model_pos,
			SpritePos = model_pos + ang:Up() * -1.3,
			Ang = ang,
			Col = HSVToColor(hue, 0.5, 1),
			ColFullSat = HSVToColor(hue, 1, 1),
			PixVis = util.GetPixelVisibleHandle()
		})
	end

	local angle = GetHitnormalFromPos(vec2, 5)

	angle:RotateAroundAxis(Angle(0, 180, 100):Forward(), -50)

	table.insert(tab, {Pos = vec2, Ang = angle})

	local mid = vec1 - (vec1 - vec2) / 2
	mid.z = mid.z - addlength
	tab.MiddlePos = mid

	table.insert(Lights, tab)
end

local temp = {
	{Vector(-14624, 258, 14556), Vector(-13568, 233, 14550)},
	{Vector(-13568, -175, 14549), Vector(-14624, -175, 14552)},
	{Vector(-13464, 183, 14547), Vector(-13131, -128, 14542)},
	{Vector(-13137, -160, 14480), Vector(-13134, -752, 14485)},
	{Vector(-13129, -794, 14518), Vector(-13113, -1690, 14496)},
	{Vector(-12305, -1536, 14425), Vector(-12512, -1433, 14421)},
	{Vector(-12310, -1792, 14429), Vector(-12512, -2033, 14428)},
	{Vector(-15040, -1660, 14552), Vector(-13888, -1645, 14618)},
	{Vector(-13888, -1129, 14643), Vector(-15040, -1181, 14589)},
	{Vector(-13888, -1427, 14629), Vector(-15040, -1411, 14589)},
	{Vector(-14324, -2018, 14411), Vector(-14321, -2672, 14380)},
	{Vector(-14000, -1960, 14475), Vector(-15040, -1972, 14482)},
	{Vector(-15840, -1647, 14420), Vector(-15568, -1635, 14405)},
	{Vector(-15539, -1312, 14496), Vector(-15056, -1539, 14492)},
	{Vector(-13568, 39, 14545), Vector(-14624, 53, 14544)},
	{Vector(-13392, -1536, 14540), Vector(-13888, -1551, 14549)},
	{Vector(-3318, 6786, 369), Vector(-3311, 6048, 240)},
	{Vector(-3809, 6208, 193), Vector(-3803, 5712, 201)},
	{Vector(-2752, 5319, 176), Vector(-4096, 5320, 181)},
	{Vector(-2835, 5000, 123), Vector(-2801, 4160, 121)},
	{Vector(-2787, 3392, 105), Vector(-2774, 4128, 103)},
	{Vector(-3712, 3636, 117), Vector(-2992, 3622, 169)},
	{Vector(-2816, 3112, 231), Vector(-4160, 3119, 230)},
	{Vector(-2930, 2240, 172), Vector(-2949.375, 3264, 180)},
	{Vector(-4096, 2599, 184), Vector(-2880, 2601, 167)},
	{Vector(-3911, 2240, 196), Vector(-3973, 3264, 171)},
	{Vector(-2720, 1435, 227), Vector(-3776, 1497, 248)},
	{Vector(-3156, 1920, 241), Vector(-3099, 1408, 201.15625)},
	{Vector(-4006, 2232, 148), Vector(-3961, 1344, 143)},
	{Vector(-3280, 4273, 111), Vector(-4167, 4259, 147)},
	{Vector(10852, -1211, -15073), Vector(10287, -485, -15058)},
	{Vector(10287, -461, -15060), Vector(10903, -119, -15079)},
	{Vector(10910, -121, -15082), Vector(11201, -983, -15074)}
}

function EVENT:OnStart()
	Bulp = ClientsideModel("models/dav0r/hoverball.mdl")
	Bulp:SetMaterial("models/shiny")
	Bulp:SetModelScale(0.4, 0)
	Bulp:SetNoDraw(true)

	BulpHolder = ClientsideModel("models/props_c17/pottery01a.mdl")
	BulpHolder:SetMaterial("models/debug/debugwhite")
	BulpHolder:SetModelScale(0.6, 0)
	BulpHolder:SetNoDraw(true)

	Holder = ClientsideModel("models/props_c17/trappropeller_lever.mdl")
	Holder:SetNoDraw(true)

	Lights = {}
	LightsDraw = {}
	for i = 1, #temp do
		AddLights(temp[i][1], temp[i][2], 10, 25)
	end

	self:AddHook("Think", "christmas.LightsThink", self.LightsThink)
	self:AddHook("PostDrawOpaqueRenderables", "christmas.LightsDraw", self.LightsDraw)
end

function EVENT:OnEnd()
	self:RemoveHooks()

	Lights = nil
	LightsDraw = nil

	if IsValid(Bulp) then
		Bulp:Remove()
		Bulp = nil
	end

	if IsValid(BulpHolder) then
		BulpHolder:Remove()
		BulpHolder = nil
	end

	if IsValid(Holder) then
		Holder:Remove()
		Holder = nil
	end
end
