AddCSLuaFile("autorun/client/clinit.lua")
-- AddCSLuaFile("sh.lua")
AddCSLuaFile("cl.lua")
-- AddCSLuaFile("sh_cmd.lua")
AddCSLuaFile("cl_cmd.lua")


function concommand.AddC(name,cfunc)
	concommand.Add(name,function(ply,cmd,args)
		if ply ~= NULL then
			ply:tell({Color(200,0,0),"This is a server only command."})
			return
		end	
		cfunc(ply,cmd,args)
	end)
end


-- resource.AddFile("materials/johns/maineffect.vmt")
-- resource.AddFile("models/johns/v_knife_karam.mdl")

-- resource.AddFile("materials/effects/glow02.vtf")
-- resource.AddFile("materials/effects/countdown_timer_num_05.vtf")
resource.AddFile("sound/johns/cratestart.wav")
resource.AddFile("sound/johns/cratecomplete.wav")
resource.AddFile("sound/johns/notify.wav")
--resource.AddWorkshop("272116853")
-- include("preinit.lua")
print "CS Lua added"
print "Starting filesystem..."
include("fp.lua")
print "Starting Scripts..."
include("sh.lua")
include("sv.lua")
include("sv_cmd.lua")
include("sh_cmd.lua")
