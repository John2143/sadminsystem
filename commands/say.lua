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
	local equips = {"\tEquips:\n"}
	for i,v in pairs(sply:getEquips()) do
		table.insert(equips,"\t\t"..tostring(i).."\t")
		if v:sub(1,5) == "__ref" then
			local iid = tonumber(v:sub(6))
			local item = ply:getItem(iid)
			table.insert(equips,item:getRarityColor())
			table.insert(equips,item:getName())
			if item:getData("strangekills") then
				table.insert(equips,RARITY[5])
				table.insert(equips," (Kills: "..item:getData("strangekills")..")")
			end
			if item:getData("strangeparts") then
				for i,v in pairs(item:getData("strangeparts")) do
					table.insert(equips,RARITY[5])
					table.insert(equips," ("..STRANGEPARTNAME[i]..": "..v..")")
				end
			end
			if item:getData("baseeffect") then
				table.insert(equips,RARITY[6])
				local c = item:getData("effect").color or {r=-1,b=-1,g=-1}
				table.insert(equips," ("..item:getData("baseeffect")..": ")
				table.insert(equips,c)
				table.insert(equips,c.r..", "..c.g..", "..c.b)
				table.insert(equips,RARITY[6])
				table.insert(equips,")")
			end
		else
			table.insert(equips,Color(150,150,150))
			table.insert(equips,v)
		end
		table.insert(equips,"\n")
	end
	telltab(ply,formatString(equips))
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
	telltab(sply,formatcString{silent and NULL or ply, " has set your rank to ",GROUP[gn]:getColor(),GROUP[gn]:getName(),"."})
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