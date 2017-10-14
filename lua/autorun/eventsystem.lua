if SERVER then
	AddCSLuaFile()
	include("eventsystem/sv_core.lua")
else
	include("eventsystem/cl_core.lua")
end
