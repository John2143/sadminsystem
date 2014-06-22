addCommand("say",function(ply,args,silent)
	telltab(player.GetAll(),formatString({Color(0,200,0),"[SAY] ",silent and NULL or ply,Color(255,255,255),": ",args},Color(255,125,0),true))
end,true)
addCommand("csay",function(ply,args,silent)
	net.Start("csay")
	net.WriteString(args)
	net.Send(player.GetAll())
	telltab(player.GetAll(),formatString({Color(200,200,0),"[CSAY] ",silent and NULL or ply,Color(255,255,255),": ",args},Color(255,125,0),true))
end,true)
addCommand("who",function(ply,args,silent)
	local sply = getPlayers(ply,args[1])
	if !sply[1] or sply[2] then
		telltab(ply,"You must run this command on one player.")
		return
	end
	sply = sply[1]
	telltab(ply,formatString({"~",sply,":\n\tRank: ",sply:getGroup():getColor(),sply:getGroup():getName()},nil,true))
end,true)
addCommand("setrank",function(ply,args,silent)
	local sply = getPlayers(ply,args[1])
	if !sply[1] or sply[2] then
		telltab(ply,"You must run this command on one player.")
		return
	end
	sply = sply[1]
	local gn = args[2]
	if !GROUP[gn] then tellctab(ply,"That rank does not exist") return end
	telltab(ply,formatcString{"You set the rank of ",sply," to ",GROUP[gn]:getColor(),GROUP[gn]:getName(),"."})
	telltab(sply,formatcString{silent and NULL or ply, "has set your rank to ",GROUP[gn]:getColor(),GROUP[gn]:getName(),"."})
	sply.group = gn
	sply:save(1)
end)
addCommand("kick",function(ply,args,silent)
	local sply = getPlayers(ply,args[1])
	for i,p in pairs(sply) do
		p:Kick(args[2] and "Kicked: "..args[2] or "Kicked.")
	end
	telltab(player.GetAll(),formatString{silent and NULL or ply," has kicked ",sply,"."})
end)
addCommand("rcon",function(ply,args,silent)
	RunConsoleCommand(unpack(args))
end)
-- addCommand("test",function(ply,args)
	-- PrintTable(args)
-- end,false)