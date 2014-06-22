for i,v in ipairs{"PlyTalk","table","ItemDrop","Eff","tablec","openinv","syncitems","seteffactive","diag","synctrade","csay"} do	
	util.AddNetworkString(v)
end

function player.GetFromGroup(n)
	local rt = {}
	for i,v in pairs(player.GetAll()) do
		if v.group == n then
			table.insert(rt,v)
		end
	end
	return rt
end

function player.getAlive(n)
	local rt = {}
	for i,v in pairs(player.GetAll()) do
		if !n and v:TTTAlive() or n and !v:TTTAlive() then
			table.insert(rt,v)
		end
	end
	return rt
end
concommand.Add("tradetest",function(ply,cmd,args)
	net.Start("synctrade")
	net.WriteString(args[1])
	net.WriteTable{1,2,3,4,5}
	net.Send(ply)
end)
function META_player:equipItem(f)
	local item = self:getItem(f);
	if item then
		if !item:hasFlag(EQUIPABLE) then print("Cannot equip "..item:getName()) return end
		self:getEquips()
		self.equips[item:getData("slot")] = "__ref"..f
	end
	self:save(2)
end
function META_player:unequipItem(f)
	if self:getEquips()[f] then 
		self.equips[f] = nil 
		self:save(2)
	end
end

-- local META_player = FindMetaTable("Player")
function META_player:namecolor()
	return self.col or Color(150,150,150)
end

local defaultvalues = {	"guest",	Color(150,150,150),	false,				false}
local values = {		"group",	"col", 				"hasBetaPackage", 	"disablePrefix"}
function META_player:save(n)
	if !SERVER then return end
	if n == 1 then
		print("Saved AData for "..gn(self).."...")
		for i,v in pairs(values) do
			self[v] = self[v] or defaultvalues[i]
			print(v,self[v])
		end
		self:SavePData("AData",values)
	elseif n == 2 then
		print("Saved items for "..gn(self).."...")
		self:SavePData("items",{"items","equips"})
	end
	file.flSave("beta"..self:UniqueID(),{"wow"})
end
function META_player:load()
	if !self:LoadPData("AData") then print("======================================================failed to load AData for "..gn(self)) end 
	if !self:LoadPData("items") then print("======================================================failed to load items for "..gn(self)) else
		for i,v in pairs(self:getItems()) do
			if type(v) == "table" then
				setmetatable(self.items[i], {__index = __ITEMMETATABLE})
			end
		end
	end 
	for i,v in pairs(values) do
		self[v] = self[v] or defaultvalues[i]
	end
	print("======================================================Loaded data for "..gn(self))
end

local itemtiers = {
	USEABLE,
	EQUIPABLE,
	EQUIPABLE,
	EQUIPABLE + STRANGEPARTS,
	UNUSUAL + EQUIPABLE,
	EQUIPABLE + UNTRADABLE,
	EQUIPABLE + STRANGEPARTS + UNUSUAL
}
local function randomeffect()
	local effectname
	local reffect = {}
	for i,v in pairs(EFFECT) do
		table.insert(reffect,i)
	end
	effectname = reffect[math.random(#reffect)]
	return {baseeffect = effectname, effect = {color = Color(math.random(255),math.random(255),math.random(255))}}
end
local stuffoftier = {
	function(f)
		return {}
	end,
	function(f)
		return {}
	end,
	function(f)
		return {}
	end,
	function(f)
		return {strangekills = 0}
	end,
	function(f)
		return randomeffect()
	end,
	function(f)
		return {}
	end,
	function(f)
		local eff = randomeffect()
		eff.strangekills = 0
		return eff
	end,
}
concommand.AddC("csay",function(ply,cmd,args)
	telltab(player.GetAll(),{gn(ply),Color(255,255,255),": ",Color(100,255,255),table.concat(args," ")})
end)
concommand.Add("itemto",function(ply,cmd,args)
	local itemid = tonumber(args[2])
	local to
	if #args ~= 2 then ply:tell("Incorrect usage") end
	if args[1]:len() < 3 then ply:tell("Please enter more characters for the name") end
	if args[1]:sub(1,1) == "@" then
		local toname = args[1]:sub(2)
		for i,v in pairs(player.GetAll()) do
			if gn(v):find(toname) then to = v break end
		end
	else
		to = player.GetAll()[tonumber(args[1])]
	end
	local item = ply.items[itemid]
	if !item then ply:tell("You do not have that item.") return end
	if !to then ply:tell("Player not found.") return end
	if to == ply then ply:tell("Get some friends.") return end
	local iitem = ply:getItem(itemid)
	if iitem:hasFlag(UNTRADABLE) then
	if type(item) == "table" then ply:tell("You can not trade or gift this item.") return end
		if iitem:getData("strangekills") then 
			ply:setStrangeKills(itemid,0)
		end
		if iitem:getData("strangeparts") then 
			for i,v in pairs(iitem:getData("strangeparts")) do
				ply:setStrangeKills(itemid,0,i)
			end
		end
		iitem = ply:getItem(itemid)
		ply.items[itemid] = nil
		to:giveItem(iitem)
	else
		ply.items[itemid] = nil
		to:giveItem(item)
	end
	ply:save(2)
	to:save(2)
	ply:tell{"Gave item."}
	to:tell{Color(200,100,0),"Received gift from ",ply:namecolor(),gn(ply),Color(200,100,0),"."}
end)
function META_player:dropItem(n,r,extra,text)
	self.items = self.items or {}
	local a = Color(255,255,255)
	local nitem
	local isbase = false
	if (r) then
		local stf = stuffoftier[r-1](ITEM[n])
		stf.base = n
		
		if extra and extra._effectc then
			stf.effect.color = stf.effect.color or {}
			stf.effect.color = extra._effectc
		end
		
		for i,v in pairs(extra or {}) do
			stf[i] = v
		end
		
			
		nitem = ITEM.new(extra and extra._itemname,r,itemtiers[r-1],stf)
		telltab(player.GetAll(),{self:namecolor(), gn(self), a, text or " has found: ", nitem:getRarityColor(), nitem:getName()})
	else
		isbase = true
		nitem = n
		telltab(player.GetAll(),{self:namecolor(), gn(self), a, text or  " has found: ", ITEM[nitem]:getRarityColor(),ITEM[nitem]:getName()})
	end
	self:giveItem(nitem,text)
end
function META_player:giveItem(item,text)
	net.Start("ItemDrop")
	net.WriteString(self:SteamID())
	net.WriteTable(type(item) == "table" and item or {__ITEM = item})
	net.Send(player.GetAll())
	--table.insert(self.items,nitem)
	self.items = self.items or nil
	if !self.items[1] then
		self.items[1] = item
	else
		for i,v in pairs(self.items) do
			if !self.items[i+1] then
				self.items[i+1] = item
				break
			end
		end
	end
	self:save(2)	
end

hook.Add("PlayerInitialSpawn","load",function(ply)
	ply:load()
	local prefixc,prefix
	
	if file.Exists("beta"..ply:UniqueID()..".txt","DATA") then
		prefixc,prefix = Color(157,255,255),"Beta-tester"
		if !ply.hasBetaPackage then 
			ply:dropItem(33) 
			ply.hasBetaPackage = true
			ply:save(1)
			ply:save(2)
		end
		ply.wasBetaTester = true
	end
	
	if ply:SteamID() == "STEAM_0:1:33556338" then
		prefixc,prefix = Color(255,50,0),"Owner"
	-- elseif ply:SteamID() == "STEAM_0:1:16070175" then
		-- prefixc,prefix = Color(187,0,255),"Developer"
	elseif ply:SteamID() == "STEAM_0:1:50070392" then
		prefixc,prefix = Color(200,10,0),"Alpha-tester"
	end
	if ply.disablePrefix then prefixc,prefix = nil,nil end
	ply.prefixc = prefixc
	ply.prefix = prefix
	
	if initialspawntell then telltab(player.GetAll(),{prefixc, sp(prefix), ply:namecolor(), gn(ply), Color(200,200,200)," has joined the game."}) end
end)
local function dispgameinfo()
	local b = Color(0,155,255)
	tab = {b,(#player.GetAll()).."/32"," on map ",b,game.GetMap(),".\nPlayers: ",player.GetAll(),"."}
	tab = formatString(tab,nil,true)
	-- telltab(player.GetAll(),{prefixc,prefix and prefix.." ", ply:namecolor(), gn(ply), Color(200,200,200)," has joined the game."})
	telltab(player.GetAll(),tab)
end
concommand.AddC("disp",dispgameinfo)
hook.Add("TTTBeginRound","listplys",function()
	if !initalspawntell then 
		dispgameinfo()
	end
	initialspawntell = true
end)
function META_player:syncItems(callback)
	self.cbsync = callback
	net.Start("syncitems")
	net.WriteTable(self:getItems())
	net.WriteTable(self:getEquips())
	net.Send(self)
end
concommand.Add("requestitems",function(ply)
	ply:syncItems()
end)
concommand.Add("doneitemsync",function(ply)
	if ply.cbsync then ply.cbsync() end
	ply.cbsync = nil
end)
hook.Add("ShowSpare1","Menu",function(ply)
	ply:syncItems(function()
		net.Start("openinv")
		net.Send(ply)
	end)
end)
function META_player:GetRoleStr()
	return self:GetRole() == ROLE_TRAITOR and "t" or self:GetRole() == ROLE_DETECTIVE and "d" or self:GetRole() == ROLE_INNOCENT and "i" or self:Team() == TEAM_SPECTATOR and "s" or "?"
end
function META_player:DropRandomItem(n)
	-- local num = math.random(10000)
	-- local rarity = 0
	-- local total = 0
	-- for i,v in pairs(DROPCHANCES) do
		-- total = total + v
		-- if num < total then
			-- rarity = i
			-- break
		-- end
	-- end
	-- while(#DROPABLEITEM[rarity] == 0) do
		-- rarity = rarity - 1
	-- end
	
	self:dropItem(DROPABLEITEM[math.random(#DROPABLEITEM)])
end
local currenteffectid = 1
local function addeff(stuff, plys)
	plys = plys or player.GetAll()
		-- local add = net.ReadBit()
	
	-- local effid = net.ReadString()
	-- local stuff = net.ReadTable()
	stuff = stuff or {}
	stuff.add = true
	stuff.player = stuff.player:SteamID()
	net.Start("Eff")
	net.WriteString(tostring(currenteffectid))
	net.WriteTable(stuff)
	net.Send(plys)
	currenteffectid = currenteffectid + 1
	return currenteffectid - 1
end
local function remeff(effid, plys)
	plys = plys or player.GetAll()
		-- local add = net.ReadBit()
	
	-- local effid = net.ReadString()
	-- local stuff = net.ReadTable()
	net.Start("Eff")
	net.WriteString(tostring(effid))
	net.WriteTable({})
	net.Send(plys)
end
/*
simul: Number of simultaneous timers active
tspeed: timer speed
color: 
player: attached player
dev: deviance
effn: effect name (effects/freeze_unfreeze: circles, sprites/light_glow02_add: slightly more vingetted balls, )
bone: Bone to attach effect to (ValveBiped.Bip01_R_Hand ValveBiped.Bip01_Head1)
upvel: the speed that the particle goes up
startalpha/endalpha: starting and ending alpha
startwidth/endwidth/startheight/endheight: starting and ending width and height
lifetime: how long the particle exists
change: offset of particles
*/
hook.Add("PlayerSay","2hot4me",function(ply,text,teamonly)
	local dead = !ply:TTTAlive()
	local tab = {name = gn(ply), text = text, namecolor = ply:namecolor(), group = ply.group, dead = dead}
	local to = {}
	if dead then
		for i,v in pairs(player.GetAll()) do
			if !v:TTTAlive() then
				table.insert(to,v)
			end
		end
		tab.dead = true
		tab.role = ply:GetRoleStr()
	else
		if teamonly then
			if ply:GetRole() == ROLE_TRAITOR then
				tab.role = "t"
				tab.team = true
				for i,v in pairs(player.GetAll()) do
					if v:GetRole() == ROLE_TRAITOR or !v:TTTAlive() then
						table.insert(to,v)
					end
				end
			elseif ply:GetRole() == ROLE_DETECTIVE then
				tab.role = "d"
				tab.team = true
				for i,v in pairs(player.GetAll()) do
					if v:GetRole() == ROLE_DETECTIVE or !v:TTTAlive() then
						table.insert(to,v)
					end
				end
			else
				to = player.GetAll()
			end
		else
			if ply:GetRole() == ROLE_DETECTIVE then
				tab.role = "d"
			end
			to = player.GetAll()
		end
	end
	if GetRoundState() ~= ROUND_ACTIVE then to = player.GetAll() end
	local rcol, rname;
	local prefixc,prefix
	if ply:getGroup():getBaseName() ~= "guest" then
		prefixc,prefix = ply:getGroup():getColor(),ply:getGroup():getName()
	end
	if !ply.disablePrefix then
		prefixc,prefix = ply.prefixc, ply.prefix
	end
	if tab.role then
		rcol = ROLE[tab.role][1]
		rname = ROLE[tab.role][2]
	end
	local send = {Color(255,30,0),tab.dead and "(DEAD) ",Color(255,30,0), tab.team and "(TEAM) ", rcol, sp(rname), prefixc, sp(prefix), tab.namecolor, tab.name,Color(255,255,255),": "..text}
	telltab(to,send)
	-- PrintTable(send)
	-- telltab(to,{"wow"})
	print(sp(prefix)..gn(ply)..": "..text)
	return ""
end)
concommand.Add("disableprefix",function(ply,cmd,args)
	ply.disablePrefix = args[1] == "1" and true or false
	ply:save(1)
end)
concommand.Add("ded",function(ply)
	//if ply:SteamID() == "STEAM_0:1:16070175" then return false end
	ply:SpawnForRound()
end)
concommand.Add("usefirst",function(ply,cmd,args)
	local id = tonumber(args[1])
	for i,v in pairs(ply:getItems()) do
		if (type(v) == "table" and v:getData("base") or v) == id then
			-- ply:tell("Used item.")
			-- ply:tell(tostring(i))
			ply:ConCommand("useitem "..i)
			return
		end
	end
	ply:tell("None found.")
end)
hook.Add("DoPlayerDeath","Alert",function(ply,killer,dmginfo)

	local a = Color(200,200,200)
	local infs = util.WeaponFromDamage(dmginfo)
	-- print(infs:GetClass(),killer.wepitemids[infs:GetClass()])
	local weaponname,weaponcolor = "<something>", Color(200,0,0)
	if infs and infs:GetClass() then
		weaponname = infs:GetClass()
		if killer.wepitemids and killer.wepitemids[weaponname] then
			local itemid = killer.wepitemids[infs:GetClass()] 
			local item = killer:getItem(itemid)
			weaponname = item:getName()
			weaponcolor = item:getRarityColor()
			if item:getData("strangekills") then 
				weaponname = weaponname.."("..(item:getData("strangekills") + 1).." kills)"
			end
		elseif GUNPROPERNAME[weaponname] then
			weaponname =  GUNPROPERNAME[weaponname] 
		end
	end
	local killernamecol = killer ~= NULL and (killer:IsPlayer() and killer:namecolor() or killer:IsWorld() and Color(0,200,0) or Color(0,0,200)) or Color(200,0,0)
	local killername = gn(killer)
	-- ply:tell{gn(killer,true),"World","Something"}
	local killerclass = ply:GetRoleStr()
	local killerclassname, killerclasscol = ROLE[killerclass][3],ROLE[killerclass][1]
	net.Start("table")
	net.WriteTable{killernamecol, killername, a, " killed you with ", weaponcolor, weaponname, a,". He was a ",killerclasscol,killerclassname,"[",killerclass,"]",a,"."}
	net.Send{ply}
end)

-- concommand.Add("pls",function(ply)
	-- ply:DropRandomItem()
-- end)
concommand.Add("col",function(ply,cmd,args)
	ply.col = Color(args[1],args[2],args[3])
	ply:save(1)
end)
concommand.Add("aeff",function(ply,cmd,args)
	ply:setEffectActive(args[1], args[2] ~= "1")
end)
concommand.Add("deagle",function(ply,cmd,args)
	ply:Give("weapon_zm_revolver")
	ply:GiveAmmo(10000,"AlyxGun")
end)

concommand.Add("hat",function(ply,cmd,args)
	local hat = ents.Create("ttt_hat_deerstalker")
	if not IsValid(hat) then return end
	hat:SetModel("models/props_c17/oildrum001.mdl")
	hat:SetPos(ply:GetPos() + Vector(0,0,70))
	hat:SetAngles(ply:GetAngles())
	hat:SetParent(ply)

	ply.hat = hat
	//hat:SetModel("models/props_c17/oildrum001.mdl")
	hat:Spawn()
end)
-- concommand.Add("ttttt",function(ply,cmd,args)
-- local tab = {wow={[5] = 3}}
	-- file.flSave("test",tab)
	-- PrintTable(tab)
	-- e(file.flLoad("test"))
-- end)



concommand.Add("itemcount",function(ply)
	if ply.items then
		local t = {"Itenz: "}
		local itemz = {}
		for i,v in pairs(ply.items) do
			itemz[v] = itemz[v] and itemz[v] + 1 or 1
		end
		for i,v in pairs(itemz) do
			table.insert(t,RARITY[ITEM[i][2]])
			table.insert(t,v>1 and ITEM[i][1].." (x"..v.."), " or ITEM[i][1]..", ")
		end
		net.Start("table")
		net.WriteTable(t)
		net.Send(ply)
	else
		net.Start("table")
		net.WriteTable{Color(255,30,0),"No items"}
		net.Send(ply)
	end
end)
-- end)
function telltab(plys,n)
	if type(n) == "string" then 
		n = {Color(200,200,200),n} 
	end
	if plys == NULL then
		local str = ""
		for i,v in pairs(n) do
			if type(v) == "string" then
				str = str.." "..v
			elseif type(v) == "Player" then
				str = str.." "..gn(v)
			end
		end
		print(str)
	end
	net.Start("table")
	net.WriteTable(n)
	net.Send(plys)
end
function tellctab(plys,str)
	telltab(plys,formatcString{str})
end
function META_player:tell(f)
	telltab(self,f)
end
function tellconsoletab(plys,n)
	net.Start("tablec")
	net.WriteTable(n)
	net.Send(plys)
end
function META_player:tellconsole(f)
	tellconsoletab(self,f)
end
concommand.Add("items",function(ply)
	if ply.items then
		local t = {"Items:\nIndex\tItemID\tName\n"}
		for i,v in pairs(ply:getItems()) do
			table.insert(t,Color(150,150,150))
			table.insert(t,tostring(i).."\t")
			-- PrintTable(type(v) == "table" and v or {})
			-- PrintTable(getmetatable(v))
			-- print(v:getData().base)
			-- print(v:getRarity())
			-- print(v:getName())
			local it = type(v) == "table" and v or ITEM[v]
			table.insert(t,(it:getData("base") or v).."\t")
			table.insert(t,it:getRarityColor())
			table.insert(t,it:getName())
			if it:hasFlag(UNUSUAL) then
				local color = it:getData("effect").color
				table.insert(t,Color(150,150,150))
				table.insert(t,"\t(")
				table.insert(t,color)
				table.insert(t,it:getData("baseeffect").." ("..color.r..","..color.g..","..color.b..")")
				table.insert(t,")")
			end
			if it:getData("strangekills") then
				local kills = it:getData("strangekills")
				table.insert(t,RARITY[5])
				table.insert(t,"\t(Kills: "..kills..")")
			end
			table.insert(t,"\n")
		end
		ply:tell(t)
	else
		ply:tell{Color(255,30,0),"No items"}
	end
end)
concommand.Add("equips",function(ply)
	if ply.equips then
		local t = {"Equips:\nSlot\tName\tReference to\n"}
		for i,v in pairs(ply.equips) do
			table.insert(t,Color(150,150,150))
			table.insert(t,tostring(i).."\t")
			table.insert(t,v)
			if v:sub(1,5) == "__ref" then
				local item = ply:getItem(tonumber(v:sub(6)));
				if item then
					table.insert(t,item:getRarityColor())
					table.insert(t,"\t("..item:getName()..")")
				else
					table.insert(t,"\t(REFERENCE ERROR: ITEM IS INVALID OR USED)")
				end
			end
			table.insert(t,"\n")
		end
		ply:tell(t)
	else
		ply:tell{Color(255,30,0),"No items"}
	end
end)

hook.Add("TTTEndRound","Item drops",function()
	local living = player.getAlive()
	for i,v in pairs(living) do
		v:DropRandomItem()
	end
	for i,v in pairs(player.GetAll()) do
		if math.random(2) == 1 then v:DropRandomItem() end
	end
	
	if #living > 5 then
		timer.Simple(29,function()
			for i,v in pairs(player.getAlive()) do
				v:DropRandomItem(1)
			end
		end)
	end
end)

concommand.Add("effect",function()
	addeff({simul = 4, dev = 10, upvel = 30, player = player.GetHumans()[1], color = Color(255,150,0)}, player.GetAll())//Blue fire
	-- addeff({simul = 3, tspeed = .01, lifetime = .3, color = Color(100,100,100), player = player.GetHumans()[1], dev = 20, bone = "ValveBiped.Bip01_R_Hand", upvel = 5, startalpha = 255, endalpha = 0, startwidth = 15,endwidth = 15, startheight = 15, endheight = 15, change = Vector(0,0,-5)}, player.GetAll())//Smoky
	-- addeff({simul = 3, tspeed = .1, lifetime = .05, color = Color(255,255,255), player = player.GetHumans()[1], bone = "ValveBiped.Bip01_L_Hand", dev = 15, upvel = -25, startalpha = 255, endalpha = 255, startwidth = 5,endwidth = 15, startheight = 5, endheight = 15, change = Vector(0,0,15)}, player.GetAll())//Blinkenlights
	-- addeff({simul = 9, tspeed = .01, lifetime = .1, color = Color(255,100,100), player = player.GetHumans()[1], dev = 10, bone = "ValveBiped.Bip01_R_Foot", upvel = 30, startalpha = 255, endalpha = 255, startwidth = 6,endwidth = 0, startheight = 6, endheight = 0, change = Vector(0,0,0)}, player.GetAll())//Glitter
	-- addeff({simul = 1, tspeed = .5, lifetime = 1, color = Color(255,255,0), player = player.GetHumans()[1], dev = 10, bone = "ValveBiped.Bip01_L_Foot", upvel = 6, startalpha = 100, endalpha = 255, startwidth = 6,endwidth = 0, startheight = 6, endheight = 0, change = Vector(0,0,0)}, player.GetAll())//Sparkle
end)
concommand.Add("effectra",function(ply)
	for i = 1, currenteffectid + 1 do
		remeff(i, ply)
	end
end)
-- concommand.Add("firstpersonunusuals",function(ply,cmd,args)
	-- ply.disableFirstPersonUnusuals = args[1] == "0"
	-- ply:save(1)
-- end)
-- concommand.Add("unusuals",function(ply,cmd,args)
	-- ply.disableUnusuals = args[1] == "0"
	-- if ply.disableUnusuals then ply:ConCommand("effectra") end
	-- ply:save(1)
-- end)

concommand.Add("equip",function(ply,cmd,args)
	ply:equipItem(tonumber(args[1]))
end)
concommand.Add("swapitem",function(ply,cmd,args)
	ply:swapItem(tonumber(args[1]),tonumber(args[2]))
end)
concommand.Add("unequipall",function(ply,cmd,args)
	ply.equips = nul
	ply:getEquips()
end)
concommand.Add("unequip",function(ply,cmd,args)
	ply:unequipItem(tonumber(args[1]))
end)

concommand.Add("useitem",function(ply,cmd,args)
	if !ply:canUseItem(ply:getItem(tonumber(args[1]))) then ply:tell("You can not use this item.") return end
	ply:tell("Using item..")
	ply:useItem(tonumber(args[1]))
end)
concommand.Add("item",function(ply,cmd,args)
	local a
	if args[3] then
		a = {}
		for i,v in pairs(string.Explode("||",args[3])) do
			local ex = string.Explode("//",v)
			if string.find(ex[2],"~~") then
				local aex = string.Explode("~~",ex[2])
				a[ex[1]] = {}
				for i,v in ipairs(aex) do
					local arg = string.Explode("=",v)
					-- print(arg[1],arg[2])
					-- PrintTable(arg[1],arg[2])
					a[ex[1]][arg[1]] = arg[2]:sub(1,1) == "#" and tonumber(arg[2]:sub(2)) or arg[2]
				end
			else
				a[ex[1]] = ex[2]:sub(1,1) == "#" and tonumber(ex[2]:sub(2)) or ex[2]
			end
		end
	end
	ply:dropItem(tonumber(args[1]),args[2] and tonumber(args[2]),a," has spawned: ")
end)

concommand.Add("startvote",function(ply,cmd,args)
	net.Start("diag")
	net.WriteString(args[1])
	net.WriteTable(string.Explode("||",args[2]))
	local voteid = nn()
	net.WriteString(tostring(voteid))
	net.Send(player.GetAll())
end)

concommand.Add("vote",function(ply,cmd,args)
	telltab(player.GetAll(),{ply:namecolor(),gn(ply),Color(100,100,100), " has voted for option ", Color(200,0,0), args[2]})
end)

concommand.Add("useitemon",function(ply,cmd,args)
	local keyid = tonumber(args[1])
	local chestid = tonumber(args[2])
	local key = ply:getItem(keyid)
	local chest = ply:getItem(chestid)
	if !ply:canUseItemOn(key,chest) then return end
	if key and chest then
		if key:getData("qualities") or chest:getData("qualities") then
				ply:dropItem(items[math.random(#items)],nil,nil," has unboxed: ")
			local items = chest:getData("items")
		elseif chest:getData("items") then
			local items = chest:getData("items")
			
			local rarity = 6
			local strange
			if math.random(100) < 90 then
				rarity = 3
			end
			if math.random(100) < 65 then
				rarity = rarity == 6 and 8 or 5
			end
			ply.items[keyid] = nil
			ply.items[chestid] = nil
			ply:dropItem(items[math.random(#items)],rarity,nil," has unboxed: ")
		elseif key:getData("strangepartname") then
			ply.items[keyid] = nil
			ply.items[chestid][4].strangeparts = ply.items[chestid][4].strangeparts or {}
			ply.items[chestid][4].strangeparts[key:getData("strangepartname")] = 0
			ply:save(2)
		elseif chest:getData("openfunc") then
			local f = key:getData("openfunc")
			f(ply,chest,keyid,chestid)
		end
	end
end)
	
concommand.Add("delitem",function(ply,cmd,args)
	ply.items[tonumber(args[1])] = nil
	ply:save(2)
end)
concommand.Add("debug",function(ply,cmd,args)
	PrintTable(ply:getItems())
	PrintTable(ply:getEquips())
end)

concommand.Add("clearinv",function(ply,cmd,args)
	ply.items = nil
end)

-- concommand.Add("heal",function(ply,cmd,args)
	-- ply:SetHealth(100)
-- end)
local function removeEffects(ply)
	for i,v in pairs(ply.activeEffects or {}) do
		remeff(v,player.GetAll())
	end
	ply.activeEffects = {}
	ply.wepeffects = {}
end
function META_player:setEffectActive(gun,b,force)
	if !force and (!self.wepeffects or (!self.wepeffects[gun])) then return end
	net.Start("seteffactive")
	net.WriteString(b and "1" or "0")
	if force then
		net.WriteString(self.wepeffects and self.wepeffects[gun] or gun)
	else
		net.WriteString(self.wepeffects[gun])
	end
	net.Send(player.GetAll())
end

hook.Add("PlayerSwitchWeapon","edit effects",function(ply,old,new)
	if IsValid(old) then ply:setEffectActive(old:GetClass(),false) end
	if IsValid(new) then ply:setEffectActive(new:GetClass(),true) end
end)
concommand.Add("sort",function(ply)
	if ply:TTTAlive() then ply:tell{"You may not sort while you are alive"} end
	local newitems = {}
	for i,v in pairs(ply.items) do
		table.insert(newitems,v)
	end
	table.sort(newitems,function(a,b) 
		local x = (type(a) == "table" and a or ITEM[a])
		local y = (type(b) == "table" and b or ITEM[b])
		local rarx,rary = x:getRarity(),y:getRarity()
		if rarx == rary then return x:getName() < y:getName() end
		return x:getRarity() > y:getRarity()
	end)
	ply.items = newitems
end)
function META_player:setStrangeKills(id,f,part)
	if part then
		local newstranges = self.items[id]:getData("strangeparts")
		newstranges[part] = f
		self.items[id]:setData("strangeparts",newstranges)
	else
		self.items[id]:setData("strangekills",f)
		self:SetNWInt("kills"..(self:getItem(id):getData("gun")),f)
		print(gn(self).." got a kill on his "..self:getItem(id):getData("gun"))
	end
	self:save(2)
end
function META_player:addStrangeKills(id,f,part)
	self:setStrangeKills(id, (part and self.items[id]:getData("strangeparts")[part] or self.items[id]:getData("strangekills")) + f)
end
concommand.Add("t",function(ply,cmd,args)
	ply:addStrangeKills(tonumber(args[1]),tonumber(args[2]))
end)
hook.Add("DoPlayerDeath","Stranges",function(ply,killer,dmginfo)
	local infs = util.WeaponFromDamage(dmginfo)
	-- print(infs:GetClass(),killer.wepitemids[infs:GetClass()])
	if infs and killer.wepitemids and killer.wepitemids[infs:GetClass()] and killer ~= ply then
		local itemid = killer.wepitemids[infs:GetClass()] 
		local item = killer:getItem(itemid)
		if item:getData("strangekills") then killer:addStrangeKills(itemid, 1) end
		if item:getData("strangeparts") then 
			for i,v in pairs(item:getData("strangeparts")) do
				if STRANGEPARTFUNCTION[i](killer,ply,infs,itemid) then
					killer:setStrangeKills(itemid,v + 1,i)
				end
			end
		end
		
	end
	removeEffects(ply)
	
	for i,id in pairs(ply.wepitemids or {}) do
		ply:SetNWBool("killson"..(i),false)
	end
	ply.wepitemids = {}
end)
-- hook.Remove("DoPlayerDeath","Stranges")
hook.Add("PlayerSpawn","giveloadout",function(ply)
	
	ply.equiped = nil
	timer.Simple(.1,function()
	ply:StripWeapons()
	if !ply:TTTAlive() then return end
	removeEffects(ply)
	ply.wepitemids = {}
	ply.wepeffects = {}
	for i,v in pairs(ply:getEquips()) do
		if v:sub(1,5) == "__ref" then
			local itemid = tonumber(v:sub(6))
			local item = ply:getItem(itemid)
			if item then
				local gunname = item:getData("gun")
				if gunname then 
					if !item:getData("nogive") then ply:Give(gunname) end
					if item:getData("strangekills") then
						print(item:getData("strangekills"))
						ply:SetNWInt("kills"..gunname,item:getData("strangekills"))
						ply:SetNWBool("killson"..(gunname),true)
					end
					ply.wepitemids[gunname] = itemid
					print(gn(ply).."'s "..gunname.." is id "..itemid)
					-- PrintTable(ply.wepitemids or {"uwot"})
				end
				if item:hasFlag(UNUSUAL) then
					ply.activeEffects = ply.activeEffects or {}
					ply.wepeffects = ply.wepeffects or {}
					
					local effect = {}
					for i,v in pairs(item:getBase():getData("effect") or {}) do
						effect[i] = v
					end
					for i,v in pairs(item:getData("effect") or {}) do
						effect[i] = v
					end
					effect.base = item:getData("baseeffect")
					effect.bone = effect.bone or SLOTBONE[item:getData("slot")]
					effect.player = ply
					--PrintTable(effect)
					local effiid = addeff(effect, player.GetAll())
					table.insert(ply.activeEffects, effiid)
					--PrintTable(ply.activeEffects)
					print(gn(ply).." has effect baseeffect='"..item:getData("baseeffect").."' on his "..item:getName().." in his slot"..i.." using bone model "..(effect.bone or SLOTBONE[item:getData("slot")]))
					if gunname then
						ply.wepeffects[gunname] = effiid
						ply:setEffectActive(gunname, false)
					end
				end
				
			end
		else
			ply:Give(v)
		end
	end
	end)
end)
-- ply:StripWeapons()
	-- ply.equiped = nil
	-- timer.Simple(.1,function()
	-- if !ply:TTTAlive() then return end
	-- removeEffects(ply)
	-- for i,v in pairs(ply:getEquips()) do
		-- if v:sub(1,5) == "__ref" then
			-- local item = ply:getItems(tonumber(v:sub(6)));
			-- print((item:getName()) .. " is a reference")
			-- local baseitem = nil
			-- if type(item) == "table" then
				-- baseitem = ITEM[item.base]
				-- if hasflag(baseitem[3],UNUSUAL) then
					-- print((item.name or baseitem[1]) .. " is unusual")
					-- ply.activeEffects = ply.activeEffects or {}
					-- local effect = baseitem.baseeffect
					-- for i,v in pairs(baseitem.effect) do
						-- effect[i] = v
					-- end
					-- for i,v in pairs(item.effect or {}) do
						-- effect[i] = v
					-- end
					-- effect.player = ply
					-- table.insert(ply.activeEffects, addeff(effect, player.GetAll()))
				-- end
				-- if item.gun then
					-- ply:Give(item.gun)
				-- else
					-- ply:Give(baseitem[4].gun)
				-- end
			-- else
				-- item = ITEM[item]
				-- if hasflag(item[3],UNUSUAL) then
					-- print(item[1] .. " is unusual")
					-- ply.activeEffects = ply.activeEffects or {}
					-- if item[4].baseeffect then
						-- print(item[1] .. " has base")
						-- local effect = item[4].baseeffect
						-- for i,v in pairs(item[4].effect or {}) do
							-- effect[i] = v
						-- end
						-- effect.player = ply
						-- table.insert(ply.activeEffects, addeff(effect, player.GetAll()))
					-- end
				-- end
				-- if item[4].gun then ply:Give(item[4].gun) end
			-- end
			
		-- else
			-- ply:Give(v)
		-- end
	-- end
	-- end)
concommand.Add("bring",function(ply,cmd,args)
	local function playerSend( from, to, force )
		if not to:IsInWorld() and not force then return false end

		local yawForward = to:EyeAngles().yaw
		local directions = {
			math.NormalizeAngle( yawForward - 180 ), -- Behind
			math.NormalizeAngle( yawForward + 90 ), -- Right
			math.NormalizeAngle( yawForward - 90 ), -- Left
			yawForward,
		}

		local t = {}
		t.start = to:GetPos() + Vector( 0, 0, 32 )
		t.filter = { to, from }

		local i = 1
		t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47
		local tr = util.TraceEntity( t, from )
		while tr.Hit do
			i = i + 1
			if i > #directions then
				if force then
					return to:GetPos() + Angle( 0, directions[ 1 ], 0 ):Forward() * 47
				else
					return false
				end
			end

			t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47

			tr = util.TraceEntity( t, from )
		end

		return tr.HitPos
	end
	local target_ply
	for i,v in pairs(player.GetAll()) do
		if string.find(gn(v),(args[1])) then target_ply = v break end
	end
	if !target_ply then return end
	local newpos = playerSend( target_ply, ply, target_ply:GetMoveType() == MOVETYPE_NOCLIP )
	local newang = (ply:GetPos() - newpos):Angle()
	target_ply:SetPos( newpos )
	target_ply:SetEyeAngles( newang )
	target_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

end)


-- local maxspeedcvar = CreateConVar("sv_maxhspeed", 350, FCVAR_NOTIFY + FCVAR_REPLICATED, "The maximum forward speed of a player")
-- --local maxspeedcvar = GetConVar("sv_maxhspeed")
-- local maxspeed = maxspeedcvar:GetInt()
-- local function setmaxhspeed()
	 -- maxspeed = maxspeedcvar:GetInt()
	 -- if maxspeed == 0 then
		-- maxspeed = 400
	 -- end
	 -- Msg("Max speed is "..maxspeed)
-- end
-- setmaxhspeed()
-- timer.Create("Check convar",60,0, setmaxhspeed)
-- hook.Add("Think","maxspeed",function()
	-- for i,ply in pairs(player.GetAll()) do
		-- local v = ply:GetVelocity()
		-- local len = math.sqrt(math.pow(v.x,2) + math.pow(v.z,2))
		-- if len > maxspeed then
			-- ply:SetVelocity(Vector(v.x,0,v.z):Normalize() + Vector(0,v.y,0))
		-- end
	-- end
-- end)
-- hook.Remove("Think","maxspeed")