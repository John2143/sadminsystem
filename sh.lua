AddCSLuaFile()
META_player = FindMetaTable( "Player" )
gn = function(ply,dq)
	if !(ply) then 
		return "<something>"
	elseif ply == NULL then
		return "Console"
	elseif ply:IsWorld() then
		return "World"
	elseif ply:IsPlayer() then
		return ply:GetName()
	end
	if !dq then return "<???>" end
end
sp = function(st)
	return st and st.." " or ""
end
local NUMBERTHATISUNIQUE = 0
function nn()
	 NUMBERTHATISUNIQUE = NUMBERTHATISUNIQUE + 1
	return NUMBERTHATISUNIQUE
end

function formatcString(args,def,prefixes)
	return formatString(args,def,prefixes,{Color(155,255,255),"[CMD] "})
end

function formatString(args,def,prefixes,stab)
	local tab = stab or {}
	local lastwascolor = false
	def = def or Color(200,200,200)
	for i,v in pairs(args) do
		if v then
			-- print(type(v))
			if type(v) == "table" then
				if v.r and v.b and v.g then
					lastwascolor = true
					table.insert(tab,v)
				else
					local numplys = #v
					for k,x in ipairs(v) do
						if prefixes then
							table.insert(tab,x.prefixc)
							table.insert(tab,sp(x.prefix))
						end
						table.insert(tab,x:namecolor())
						table.insert(tab,gn(x))
						if numplys ~= k then 
							table.insert(tab,def)
							table.insert(tab,", ")
						end
					end
				end
			elseif type(v) == "string" then
				if !lastwascolor then table.insert(tab,def) end
				table.insert(tab,v)
				lastwascolor = false
			elseif type(v) == "Player" then
				if prefixes then
					table.insert(tab,v.prefixc)
					table.insert(tab,sp(v.prefix))
					table.insert(tab,v:namecolor())
					table.insert(tab,gn(v))
				else
					if !lastwascolor then table.insert(tab,v:namecolor()) end
					table.insert(tab,gn(v))
				end
				lastwascolor = false
			elseif v == NULL then
				table.insert(tab,Color(119,209,255))
				table.insert(tab,"<someone>")
			else
				if !lastwascolor then table.insert(tab,def) end
				table.insert(tab,tostring(v))
				lastwascolor = false
			end
		end
	end
	return tab
end
function hasflag(n,h)
	if !(n and h) then return false end
	return bit.band(n,h) == h
end
-- local META_player = FindMetaTable( "Player" )
-- local META_color = FindMetaTable("Color")

-- META_color.__add = META_color.__add or function(a,b) return Color(math.Clamp(a.r+b.r,0,255),math.Clamp(a.g+b.g,0,255),math.Clamp(a.b+b.b,0,255),math.Clamp(a.a+b.a,0,255)) end

OPENABLE = 1
DROPABLE = 2
EQUIPABLE = 4
USEABLE = 8
UNUSUAL = 16
UNTRADABLE = 32
VOLATILE = 64
ITERATE = 128
STRANGEPARTS = 256
USEOTHER = 512

SLOT = {
	"Holster", 		--1
	"Magneto Stick",--2
	"Crowbar",		--3
	"Primary",		--4
	"Secondary",	--5
	"Grenade",		--6
	"Hat",			--7
	"R Foot",		--8
	"L Foot",		--9
	"Body",			--10
	"Offhand",		--11
	"Slot7",		--12
	"Slot8",		--13
}
SLOTBONE = {
	"ValveBiped.Bip01_R_Thigh",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_Head",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Hand",
}

ROLE = {
	d={Color(0,60,200),"DET","Detective"},
	t={Color(200,60,0),"TRT","Traitor"},
	i={Color(0,200,60),"INN","Innocent"},
	s={Color(210,255,100),"SPC","Spectator"},
}


GROUP = {
	guest = {"Guest", nil, Color(150,150,150)},
	regular = {"Regular", "guest", Color(0,200,0)},
	admin = {"Admin", "regular", Color(200,0,0)}
}

RARITY = {
	Color(178,178,178),	--BASE		1
	Color(255,216,0),	--Normal	2
	Color(71,98,145),	--Vintage	3
	Color(77,116,85),	--Genuine	4
	Color(207,106,50),	--Strange	5
	Color(134,80,172),	--Unusual	6
	Color(112, 176, 74),	--Event		7
	Color(200,80,172),	--Unusual Strange8
}

local RARITYNAMES = {
	nil,
	nil,
	nil,
	nil,
	"Strange",
	"Unusual",
	nil,
	"Very Unusual",
}

__ITEMMETATABLE = {}
function __ITEMMETATABLE:getBase()
	return self[4].base and ITEM[self[4].base] or self
end
function __ITEMMETATABLE:getNameNT()
	return (self[1] or self:getBase()[1])
end
function __ITEMMETATABLE:getName()
	local prefix = (RARITYNAMES[self:getRarity()])
	return "The "..sp(prefix)..(self:getNameNT())
end
function __ITEMMETATABLE:getRarity()
	return self[2] or self:getBase()[2]
end
function __ITEMMETATABLE:getRarityColor()
	return RARITY[self:getRarity()]
end
function __ITEMMETATABLE:getFlags()
	return self[3] or self:getBase()[3]
end
function __ITEMMETATABLE:hasFlag(f)
	return hasflag(self:getFlags(), f)
end
local function ___gd(self,f)
	if f then
		return self[4] and self[4][f] or self:getBase()[4][f]
	else
		return self[4] or self:getBase()[4]
	end
end
__ITEMMETATABLE.getData = ___gd
function __ITEMMETATABLE:setData(f,val)
	if self[4] then
		self[4][f] = val
		return true
	else
		return false
	end
end

EFFECT = {
	sparkle = {simul = 4, tspeed = .5, lifetime = .1, dev = 10, upvel = 6, startalpha = 100, endalpha = 255, startwidth = 6,endwidth = 20, startheight = 6, endheight = 20, change = Vector(0,0,0)},
	glitter = {simul = 9, tspeed = .01, lifetime = .1, dev = 10, upvel = 30, startalpha = 255, endalpha = 255, startwidth = 6,endwidth = 0, startheight = 6, endheight = 0, change = Vector(0,0,0)},
	smokey = {simul = 3, tspeed = .01, lifetime = .3, dev = 20, upvel = 5, startalpha = 255, endalpha = 0, startwidth = 15,endwidth = 15, startheight = 15, endheight = 15, change = Vector(0,0,-5)},
	glowflame = {simul = 7, dev = 10, upvel = 50, lifetime = .25},--effn = "effects/counterdown_timer_num_05"
	blinkenlights = {simul = 3, tspeed = .1, lifetime = .05, dev = 15, upvel = -25, startalpha = 255, endalpha = 255, startwidth = 5,endwidth = 15, startheight = 5, endheight = 15, change = Vector(0,0,15)}
}

STRANGEPARTNAME = {
	tkill = "Traitor Kills",
	dkill = "Detective Kills",
}
STRANGEPARTFUNCTION = {
	tkill = function(killer,ply,wep,itemid)
		return !killer:IsTraitor() and ply:IsTraitor()
	end,
	dkill = function(killer,ply,wep)
		return killer:IsTraitor() and ply:IsDetective()
	end,
}

ITEM = {
	{"Crate #1",1,OPENABLE + DROPABLE,{items = {7,8,9}, keyid = 1}},
	{"Pistol Ammo",1,USEABLE + DROPABLE,{ammo = {"Pistol",60}}},
	{"Shotgun Ammo",1,USEABLE + DROPABLE,{ammo = {"buckshot",8}}},
	{"Rifle Ammo",1,USEABLE + DROPABLE,{ammo = {"357",10}}},
	{"Deagle Ammo",1,USEABLE + DROPABLE,{ammo = {"AlyxGun",36}}},
	{"SMG Ammo",1,USEABLE + DROPABLE,{ammo = {"smg1",60}}},
	
	{"M4A1-S",2, USEABLE + DROPABLE, {gun = "weapon_ttt_m16", slot = 4}}, --7
	{"Deagle",2, USEABLE + DROPABLE, {gun = "weapon_zm_revolver", slot = 5, effect = {changey = -5,changef = 5}}},
	{"Rifle",2, USEABLE + DROPABLE, {gun = "weapon_zm_rifle", slot = 4}},

	{"Crowbar",1,EQUIPABLE, {gun = "weapon_zm_improvised", slot = 3}},
	{"Holster",1,EQUIPABLE, {gun = "weapon_ttt_unarmed", slot = 1,effect = {dev = 30,simul = 10}}},
	{"Magneto Stick",1,EQUIPABLE, {gun = "weapon_zm_carry", slot = 2}},
	
	{"XM0401",2, USEABLE + DROPABLE, {gun = "weapon_zm_shotgun", slot = 4}},
	{"Mac 10",2, USEABLE + DROPABLE, {gun = "weapon_zm_mac10", slot = 4, bone = "ValveBiped.Bip01_R_Hand"}},
	{"HUGE249",2, USEABLE + DROPABLE, {gun = "weapon_zm_sledge", slot = 4}},
	{"Pistol",2, USEABLE + DROPABLE, {gun = "weapon_zm_pistol", slot = 5, effect = {changey = -5,changef = 5}}},
	{"Glock",2, USEABLE + DROPABLE, {gun = "weapon_ttt_glock", slot = 5, effect = {changey = -5,changef = 5}}}, --bone = 17
	
	{"Cool hat",2,0, {slot = 7, effect = {changey = 6}}}, --bone = 
	{"Cool boot1",2,0, {slot = 8, effect = {changey = -5,changef = 2, dev = -10}}}, --bone = 
	{"Cool boot2",2,0, {slot = 9, effect = {changey = -5,changef = 2, dev = 10}}}, --bone = 
	{"Cool boot3",2,0, {slot = 10, effect = {changey = -5,changef = 2, dev = 10}}}, --bone = 
	
	{"HUGE Ammo",1,USEABLE + DROPABLE,{ammo = {"AirboatGun",150}}},
	{"Key",4,USEOTHER,{iskey = 1}},
	{"Crate #2",1,OPENABLE + DROPABLE,{items = {10,11,12}, keyid = 1}},
	{"Crate #3",1,OPENABLE + DROPABLE,{items = {13,14,15,16,17}, keyid = 1}},
	{"SP: Traitor kills",4,USEOTHER,{strangepartname = "tkill"}},
	{"SP: Detective kills",4,USEOTHER,{strangepartname = "dkill"}},
	{"Strange Part Crate",1,OPENABLE + DROPABLE,{items = {26,27}, keyid = 2}},
	{"Strange Part Key",4,USEOTHER,{iskey = 2,qualities = true}},
	{"P90",2, USEABLE + DROPABLE, {gun = "weapon_ttt_p90", slot = 5}},
	{"Silenced Pistol",2, 0, {gun = "weapon_ttt_sipistol",nogive = true, slot = 12}},
	{"Clickclickclick",2, USEABLE, {gun = "weapon_ttt_clicker", slot = 5}},
	{"Beta Tester Package",7,USEABLE, {desc = "Thanks for helping out!",event = "The Server Beta", autograph = "≛1st 🕓 John2143658709≛",usefunc = function(ply) 
		ply:dropItem(math.random(10)+7,7,{event = "The Server Beta", autograph = "≛1st 🕓 John2143658709≛",strangekills = 0}," has received: ")
	end}}
	-- {"Strange Part: Traitor kills",4,USEOTHER,{strangepartname = "tkill"}},
}
setmetatable(ITEM,{
	__index = {
		new = function(a,b,c,d)
			local ntab = {a,b,c,d}
			setmetatable(ntab, {__index = __ITEMMETATABLE})
			return ntab
		end
	}
})

DROPABLEITEM = {}
KEYNAMES = {}
GUNPROPERNAME  = {}
for i,v in ipairs(ITEM) do
	setmetatable(ITEM[i], {__index = __ITEMMETATABLE})
	if hasflag(v[3],DROPABLE) then
		table.insert(DROPABLEITEM,i)
		print(v[1] .. " is DROPABLE")
	end
	if v[4].iskey then
		KEYNAMES[v[4].iskey] = i
	end
	if v:getData("gun") then
		GUNPROPERNAME[v:getData("gun")] = v:getNameNT()
		print(v:getData("gun") .. " is named "..v:getNameNT())
	end
end



hook.Add("TTTPlayerSpeed","speed",function(ply, slowed)
	return slowed and 1 or 1.2
end)


function META_player:getItem(m)
	local item = self:getItems()[m];
	if not item then return nil end
	if type(item) == "table" then
		setmetatable(item, {__index = __ITEMMETATABLE})
		return item
	else
		return ITEM[item]
	end
end
function META_player:useItem(itemind)
	local item = self:getItem(itemind);
	if item then
		if item:hasFlag(USEABLE) then 
			print("Using "..item:getName()) 
		else
			print("Cannot use "..item:getName()) 
			return 
		end
		self.items[itemind] = nil
		if !SERVER then return end
		if item:getData("gun") then
			self:Give(item:getData("gun"))
		end
		if item:getData("ammo") then
			self:GiveAmmo(item:getData("ammo")[2],item:getData("ammo")[1])
		end
		if item:getData("usefunc") then
			item:getData("usefunc")(self)
		end
		self:save(2)
	end
end
function META_player:getEquips()
	if !self.equips then
		self.equips = {"weapon_ttt_unarmed","weapon_zm_carry","weapon_zm_improvised"}
		self:save(2)
	end
	return self.equips
end
function META_player:getItems()
	return self.items or {}
end
function META_player:getEquipItem(n)
	local v = self:getEquips()[n]
	if v:sub(1,5) == "__ref" then
		return ply:getItem(tonumber(v:sub(6)))
	else
		return v
	end
	self:save(2)
end
function META_player:TTTAlive()
	return self:Alive() and self:Team() ~= TEAM_SPECTATOR
end
function META_player:canUseItem(item)
	return item and item:hasFlag(USEABLE)
end
function META_player:canUseItemOn(item,on,crit)
	if !item or !on then return false end
	local cr = crit or item:getData("criteria") 
	if cr then 
		return cr(on)
	else
		if item:getData("strangepartname") then return on:hasFlag(STRANGEPARTS) end
		return item:getData("iskey") == on:getData("keyid") 
	end
end
function META_player:swapItem(a,b)
	for i,v in pairs(self:getEquips()) do
		if v:sub(1,5) == "__ref" then
			local ref = tonumber(v:sub(6))
			if ref == a then
				self.equips[i] = "__ref"..b
			elseif ref == b then
				self.equips[i] = "__ref"..a
			end
		end
	end
	local ic = self.items[a]
	self.items[a] = self.items[b]
	self.items[b] = ic
	self:save(2)
end
