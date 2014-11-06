local christmas = {}
christmas.Name = "Christmas"

if SERVER then
	eventsystem:RegisterEvent(christmas)
	return
end

christmas.RopeMat = Material("cable/rope")
christmas.GlowMat = Material("sprites/light_glow02_add")

christmas.RopeColor = Color(50, 255, 50)

christmas.Bulp = ents.CreateClientProp()
christmas.Bulp:SetModel("models/dav0r/hoverball.mdl")
christmas.Bulp:SetNoDraw(true)
christmas.Bulp:SetMaterial("models/shiny")
christmas.Bulp:SetModelScale(Vector(0.8, 0.8, 1) * 0.5)

christmas.BulpHolder = ents.CreateClientProp()
christmas.BulpHolder:SetModel("models/props_c17/pottery01a.mdl")
christmas.BulpHolder:SetNoDraw(true)
christmas.BulpHolder:SetMaterial("models/debug/debugwhite")
christmas.BulpHolder:SetModelScale(Vector() * 0.6)

christmas.Holder = ents.CreateClientProp()
christmas.Holder:SetModel("models/props_c17/TrapPropeller_Lever.mdl")
christmas.Holder:SetNoDraw(true)

christmas.Lights = {}
christmas.LastLightsUpdate = CurTime()

christmas.Directions = {
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
	local angle = Angle(0)
	
	for _, vector in pairs(christmas.Directions) do
		local trace = util.QuickTrace(point, vector*length)
		if trace.Hit then
			angle = trace.HitNormal:Angle()
		break end
	end
	
	return angle
end

function christmas:LightsDraw()
	if not christmas.Draw:GetBool() then return end

	if CurTime() - christmas.LastLightsUpdate >= 1 then
		christmas.LastLightsUpdate = CurTime()
		for k, v in ipairs(christmas.Lights) do
			if not LocalPlayer():GetPos():Distance(v.MiddlePos) <= 5000 then continue end

			for i, j in ipairs(v) do
				if i == 1 or i == #christmas.Lights[k] then continue end

				local hue = math.random(360)
				christmas.Lights[k][i].Col = HSVToColor(hue, 0.5, 1)
				christmas.Lights[k][i].ColFullSat = HSVToColor(hue, 1, 1)
			end
		end
	end

	for k, v in ipairs(christmas.Lights) do
		if not LocalPlayer():GetPos():Distance(v.MiddlePos) <= 5000 then continue end

		for i, j in ipairs(v) do
			local coord = christmas.Lights[k][1].Pos:DistToSqr(christmas.Lights[k][#christmas.Lights[k]].Pos) / #christmas.Lights[k] / 4
			if i == 1 then
				render.SetMaterial(christmas.RopeMat)
				render.StartBeam(#christmas.Lights[k])
				render.AddBeam(j.Pos, 0.6, coord * i, christmas.RopeColor)
			elseif i == #christmas.Lights[k] then
				render.AddBeam(j.Pos, 0.6, coord * i, christmas.RopeColor)
				render.EndBeam()
			else
				render.SetMaterial(christmas.RopeMat)
				render.AddBeam(j.Pos, 0.6, coord * i, j.ColFullSat)
			end
		end

		for i, j in ipairs(v) do
			if i == 1 or i == #christmas.Lights[k] then 
				christmas.Holder:SetRenderOrigin(j.Pos)
				christmas.Holder:SetRenderAngles(j.Ang)
				christmas.Holder:SetupBones()
				christmas.Holder:DrawModel()
				continue
			end

			local pos = j.ModelPos

			local visible = util.PixelVisible(j.ModelPos, 15, j.PixVis)
			if visible == 0 then
				continue
			end

			local sprite_pos = LerpVector(0.2, pos + j.Ang:Up() * -1.3, LocalPlayer():EyePos())

			render.SetBlend(1)
				render.SetColorModulation(j.ColFullSat.r * 0.002, j.ColFullSat.g * 0.002, j.ColFullSat.b * 0.002)	
					christmas.BulpHolder:SetRenderOrigin(pos)
					christmas.BulpHolder:SetRenderAngles(j.Ang)
					christmas.BulpHolder:SetupBones()
					christmas.BulpHolder:DrawModel()	
				render.SetColorModulation(1,1,1)
			render.SetBlend(0)
			
			render.SetMaterial(christmas.GlowMat)
			render.DrawSprite(sprite_pos, 40 * visible, 40 * visible, j.Col)
			render.DrawSprite(sprite_pos, 30 * visible, 30 * visible, j.Col)
			render.DrawSprite(sprite_pos, 20 * visible, 20 * visible, j.Col)

			render.SetBlend(0.8)
				render.SetColorModulation(j.ColFullSat.r, j.ColFullSat.g, j.ColFullSat.b)			
					christmas.Bulp:SetRenderOrigin(pos)
					christmas.Bulp:SetRenderAngles(j.Ang)
					christmas.Bulp:SetupBones()
					christmas.Bulp:DrawModel()
				render.SetColorModulation(1, 1, 1)
			render.SetBlend(1)
		end
	end
end

function christmas:AddLights(vec1, vec2, lights, addlength)
	local numlights = #christmas.Lights + 1
	local height = 180 / (lights + 1)
	local lerp = (vec1 - vec2) / (lights + 1)

	local tab = {}
	
	local angle = GetHitnormalFromPos(vec2, 5)
	
	angle:RotateAroundAxis(Angle(0, 180, 100):Forward(), -50)

	table.insert(tab, {["Pos"] = vec1, ["Ang"] = angle})

	for i = 1, lights do
		local pos = vec1 + lerp * -i
		pos.z = pos.z - (math.sin(math.Deg2Rad(height * i)) * addlength)
		local ang = AngleRand() * 0.05
		local offset = Vector(0, 0, -6)
		offset:Rotate(ang)
		local model_pos = pos + offset
		table.insert(tab, {
			["Pos"] = pos,
			["ModelPos"] = model_pos,
			["Ang"] = ang,
			["Col"] = HSVToColor(hue, 0.5, 1),
			["ColFullSat"] = HSVToColor(hue, 1, 1),
			["PixVis"] = util.GetPixelVisibleHandle()
		})
	end
	
	local angle = GetHitnormalFromPos(vec2, 5)
	
	angle:RotateAroundAxis(Angle(0, 180, 100):Forward(), -50)
	
	table.insert(tab, {["Pos"] = vec2, ["Ang"] = angle})

	local mid = vec1 - ((vec1 - vec2) / 2)
	mid.z = mid.z - addlength
	tab["MiddlePos"] = mid

	table.insert(christmas.Lights, tab)
end

function christmas:RemoveLights()
	christmas.Lights = {}
end

function christmas:EndEvent(forced)
	if IsValid(christmas.Bulp) then
		christmas.Bulp:Remove()
	end

	if IsValid(christmas.BulpHolder) then
		christmas.BulpHolder:Remove()
	end

	if IsValid(christmas.Holder) then
		christmas.Holder:Remove()
	end

	hook.Remove("PostDrawOpaqueRenderables", "christmas.LightsDraw")
end

local temp = {{Vector(14624, 258, 14556), Vector(-13568, 233, 14550)},
{Vector(-13568, -175, 14549), Vector(-14624, -175, 14552)},
{Vector(-13464, 183, 14547), Vector(-13131, -128, 14542)},
{Vector(-13137, -160, 14480), Vector(-13134, -752, 14485)},
{Vector(-13129, -794, 14518), Vector(-13113, -1690 14496)},
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
{Vector(10910, -121, -15082), Vector(11201, -983, -15074)}}

function christmas:StartEvent()
	for i = 1, #temp do
		christmas:AddLights(temp[i][1], temp[i][2], 10, 25)
	end

	hook.Add("PostDrawOpaqueRenderables", "christmas.LightsDraw", christmas.LightsDraw)
end

christmas.Draw = CreateClientConVar("christmas_lights", 1, true, false)

eventsystem:RegisterEvent(christmas)