addCommand("say",function(ply,args)
	telltab(player.GetAll(),formatString({Color(0,200,0),"[SAY] ",ply,Color(255,255,255),": ",args},Color(255,125,0),true))
end,true)
addCommand("csay",function(ply,args)
	net.Start("csay")
	net.WriteString(args)
	net.Send(player.GetAll())
	telltab(player.GetAll(),formatString({Color(200,200,0),"[CSAY] ",ply,Color(255,255,255),": ",args},Color(255,125,0),true))
end,true)
addCommand("who",function(ply,args)
	local sply = getPlayers(ply,args[1])
	if !sply[1] or sply[2] then
		telltab(ply,"You must run this command on one player.")
		return
	end
	sply = sply[1]
	telltab(ply,formatString({"~",sply,":\n\tRank: ",sply:getGroup():getColor(),sply:getGroup():getName()},nil,true))
end,true)
addCommand("setrank",function(ply,args)
	local sply = getPlayers(ply,args[1])
	if !sply[1] or sply[2] then
		telltab(ply,"You must run this command on one player.")
		return
	end
	sply = sply[1]
	local gn = args[2]
	if !GROUP[gn] then tellctab(ply,"That rank does not exist") return end
	telltab(ply,formatcString{"You set the rank of ",sply," to ",GROUP[gn]:getColor(),GROUP[gn]:getName(),"."})
	telltab(sply,formatcString{"Your rank is now ",GROUP[gn]:getColor(),GROUP[gn]:getName(),"."})
	sply.group = gn
	sply:save(1)
end)
addCommand("kick",function(ply,args)
	local sply = getPlayers(ply,args[1])
	for i,p in pairs(sply) do
		p:Kick(args[2])
	end
	telltab(player.GetAll(),formatString{ply," has kicked ",sply,"."})
end)
-- addCommand("test",function(ply,args)
	-- PrintTable(args)
-- end,false)