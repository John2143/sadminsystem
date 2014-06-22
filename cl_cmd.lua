print([[
	Admin plugin developed for use in John2143658709's TTT server
	~Unusuals, Stat tracking, Active Admins and no models!~
]])
for i,v,d in pairs(file.Find("lua/commands/*","GAME")) do
	include("commands/"..v)
end

local csay
local csayalpha = 0
hook.Add("HUDPaint","csay",function()
	if !csay then return end
	draw.SimpleText(csay,"HealthAmmo", ScrW()/2,2*ScrH()/5, Color(255,255,255,csayalpha*255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end)
net.Receive("csay",function()
	csay = net.ReadString()
	print("csaid ",csay)
	-- timer.Destroy("csayalpha")
	-- timer.Destroy("csaywait")
	csayalpha = 0
	timer.Create("csayawit",5,1,function()
		timer.Create("csayalpha",.03,30,function()
			csayalpha = csayalpha - 1/30
		end)
	end)
	timer.Create("csaydestroy",6,1,function() csay = nil end)
	timer.Create("csayalpha",.03,30,function()
		csayalpha = csayalpha + 1/30
	end)
	
end)