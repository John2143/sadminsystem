local itemsnew = 0
local mainpanel

function invIsOpen()
	return mainpanel and IsValid(mainpanel) and mainpanel ~= NULL
end

local parsetext = function(text)
	return {text}
end
draw.ShadowedText = function(text,font,x,y,col,ta1,ta2)
	draw.SimpleText(text,font,x+2,y+2,Color(0,0,0,200),ta1,ta2)
	draw.SimpleText(text,font,x,y,col,ta1,ta2)
end	
net.Receive("PlyTalk",function()
	local tab = net.ReadTable()
	chat.AddText(Color(),tab.name,Color(255,255,255),": ",unpack(parsetext(tab.text)))
	PrintTable(tab)
end)

net.Receive("syncitems",function()
	LocalPlayer().items = net.ReadTable()
	LocalPlayer().equips = net.ReadTable()
	for i,v in pairs(LocalPlayer().items) do
		if type(v) == "table" then setmetatable(LocalPlayer().items[i],{__index = __ITEMMETATABLE}) end
	end
	RunConsoleCommand("doneitemsync")
end)

net.Receive("table",function()
	local tab = net.ReadTable()
	chat.AddText(unpack(tab))
end)
net.Receive("tablec",function()
	local tab = net.ReadTable()
	local ntab = {}
	for i,v in pairs(tab) do
		if type(v) == "table" then
			ntab[i] = Color(v.r,v.g,v.b,v.a)
		else
			ntab[i] = v
		end
	end
	MsgC(unpack(ntab))
end)
local activeitems = 0
net.Receive("ItemDrop",function()
	local steam = net.ReadString()
	local ply
	local loc = false
	if steam == LocalPlayer():SteamID() then
		ply = LocalPlayer()
		loc = true
	else
		for i,v in pairs(player.GetAll()) do
			if v:SteamID() == steam then ply = v break end
		end
	end
	if loc then
		print("You got an item!")
		local num = nn()
		local lactive = activeitems
		if invIsOpen() then return end
		activeitems = activeitems + 1
		itemsnew = itemsnew + 1
		hook.Add("HUDPaint","item"..num,function()
			local width = 250
			local height = 40
			local sw, sh = ScrW(), ScrH()
			local margin = 10
			
			local x = sw-margin-width
			local y = sh-height-100 - lactive*(height+margin)
			
			draw.RoundedBox(8, x, y, width, height, Color(200,100,0))
			draw.ShadowedText("You got an item!", "HealthAmmo", x + width/2, y + 2, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Press F3 to view your inventory", "TabLarge", x + width/2, y + height - 2, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end)
		timer.Simple(10,function()
			hook.Remove("HUDPaint","item"..num)
			activeitems = activeitems - 1
		end)
		surface.PlaySound( "johns/notify.wav" )
	else
		print("<"..gn(ply).."> got an item")
	end
end)

hook.Add("HUDPaint","itemsnew",function()
	if itemsnew == 0 then return end
	local width = 50
	local height = 50
	local sw, sh = ScrW(), ScrH()
	local margin = 30
	
	local x = sw-width-margin
	local y = margin
	
	draw.RoundedBox(8, x, y, width, height, Color(100,100,100))
	--draw.SimpleText("!!!!!!", "HealthAmmo", x + width/2, y + 2, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	draw.ShadowedText(tostring(itemsnew), "HealthAmmo", x+width-5, y, Color(200,200,200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
	--draw.SimpleText("!!!!!!!!!", "TabLarge", x + width/2, y + height - 2, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

concommand.Add("+lookleft",function()
	hook.Add("Think","bhop",function()
		RunConsoleCommand((LocalPlayer():IsOnGround() and "+" or "-").."jump")
	end)
end,function() return {"Super secret bhop concommand!"} end)

concommand.Add("-lookleft",function()
	RunConsoleCommand("-jump")
	hook.Remove("Think","bhop")
end)
-- local maxspeedcvar = GetConVar("sv_maxhspeed")
-- local maxspeed = maxspeedcvar:GetInt()
-- local function setmaxhspeed()
	 -- maxspeed = maxspeedcvar:GetInt()
	 -- if maxspeed == 0 then
		-- maxspeed = 400
	 -- end
	 -- MsgC(Color(200,0,0),"Max speed is "..maxspeed)
-- end
-- setmaxhspeed()
-- timer.Create("Check convar",60,0, setmaxhspeed)
-- hook.Add("Think","maxspeed",function()
	-- local v = LocalPlayer():GetVelocity()
	-- local len = math.sqrt(math.pow(v.x,2) + math.pow(v.z,2))
	-- if len > maxspeed then
		-- LocalPlayer():SetVelocity(Vector(v.x,0,v.z):Normalize() + Vector(0,v.y,0))
	-- end
-- end)
local currenteffs = {}
/*
simul: Number of simultaneous timers active
tspeed: timer speed
color: 
player: Steamid of attached player
dev: deviance
effn: effect name
bone: Bone to attach effect to (ValveBiped.Bip01_R_Hand ValveBiped.Bip01_Head1)
upvel: the speed that the particle goes up
startalpha/endalpha: starting and ending alpha
startwidth/endwidth/startheight/endheight: starting and ending width and height
lifetime: how long the particle exists
change: offset of particles
	changef,changey,changer
*/
local function remeff(effid)
	if !currenteffs[effid] then return false end
	for i = 0,(currenteffs[effid][2] or 5) do
		timer.Remove(effid.."e"..i)
	end
	currenteffs[effid][1]:Finish()
	currenteffs[effid] = nil
end
local fpun = CreateClientConVar( "firstpersonunusuals", "1", true, false )
local un = CreateClientConVar( "unusuals", "1", true, false )
local inactive = {}

net.Receive("seteffactive",function()
	print("an effect status has been changed")
	local iactive = net.ReadString() == "0"
	local id = net.ReadString()
	inactive[id] = iactive
	print("an effect status has been changed: "..id,iactive)
end)

net.Receive("Eff",function()
	local effid = net.ReadString()
	local recv = net.ReadTable()
	local stuff = {}
	for i,v in pairs(EFFECT[recv.base] or {}) do
		stuff[i] = v
	end
	for i,v in pairs(recv) do
		if i ~= "base" then stuff[i] = v end
	end
	local add = stuff.add == true
	print("Effect called: "..effid.."- "..(add and "Added" or "Removed"))
	PrintTable(stuff)
	
	if currenteffs[effid] then 
		for i = 0,(currenteffs[effid][2] or 5) do
			timer.Remove(effid.."e"..i)
		end
		currenteffs[effid][1]:Finish()
		currenteffs[effid] = nil
	end
	if add then
		if !fpun:GetBool() and stuff.player == LocalPlayer():SteamID() or !un:GetBool() then
			return
		end		
		local cPlayer
		for i,v in pairs(player.GetAll()) do
			if v:SteamID() == stuff.player then
				cPlayer = v
				break
			end
		end
		if !cPlayer then MsgC(Color(255,150,0),"ERROR: ADDDED EFFECT TO NONEXISTANT PLAYER")return end
		currenteffs[effid] = {ParticleEmitter( Vector(0,0,0), false ),stuff.simul or 5}
		for i = 1,currenteffs[effid][2] or 5 do
			timer.Create(effid.."e"..i,stuff.tspeed or .01,0,function()
				if !IsValid(cPlayer) then timer.Destroy(effid.."e"..i) return end
				if inactive[effid] then return end
				local BoneIndx = cPlayer:LookupBone(stuff.bone or "ValveBiped.Bip01_Head1")
				if !BoneIndx then return end
				local BonePos , BoneAng = cPlayer:GetBonePosition( BoneIndx )
				
				local angles = cPlayer:EyeAngles()
				local angchg = Vector(0,0,0) + ((angles:Up()*(stuff.changey or 1) + angles:Right()*(stuff.changer or 1) + angles:Forward()*(stuff.changef or 1)))
				local paricled = stuff.dev or 10
				local particle = currenteffs[effid][1]:Add( stuff.effn or "effects/softglow", BonePos + angchg + Vector(math.random(paricled),math.random(paricled),math.random(paricled))-Vector(paricled/2,paricled/2,paricled/2) + Vector(stuff.movex or 0,stuff.movez or 0,stuff.movey or 0))
				
				local ang = LocalPlayer():EyeAngles()
				ang:RotateAroundAxis(ang:Up(), -90)
				ang:RotateAroundAxis(ang:Forward(), 90)
				ang:RotateAroundAxis(ang:Right(), 90)
				
				if ( particle ) then
					particle:SetAngles( ang )
					particle:SetVelocity( Vector( 0, 0, stuff.upvel or 100 ) )
					particle:SetColor( stuff.color.r, stuff.color.g, stuff.color.b)
					particle:SetLifeTime( 0 )
					particle:SetDieTime( stuff.lifetime or .4 )
					particle:SetStartAlpha( stuff.startalpha or 255 )
					particle:SetEndAlpha(  stuff.endalpha or 255 )
					particle:SetStartSize( stuff.startwidth or 10 )
					particle:SetStartLength( stuff.startheight or 10 )
					particle:SetEndSize( stuff.endwidth or 0 )
					particle:SetEndLength( stuff.endheight or 0 )
				end
			end)
		end
	end
end)
local function getGlobalPos(panel)
	local parent = panel:GetParent()
	if parent then
		local px, py = getGlobalPos(parent)
		local x,y = panel:GetPos()
		return px + x, py + y
	else
		return panel:GetPos()
	end
end


local function diag(a)
	local question,opts,callback,x,y,w,h,center,closeable = a.question,a.options or a.opts,a.onAnswer or a.callback,a.x,a.y,a.w,a.h,a.center,a.closeable
	local qpanel = vgui.Create("DFrame")
	local sw,sh = ScrW(),ScrH()
	local width,height = w or 200,h or 200
	qpanel:SetSize(width,height)
	qpanel:SetPos(x or 0,y or 0)
	qpanel:SetTitle(question)
	qpanel:SetVisible(true)
	qpanel:SetDraggable(true)
	qpanel:ShowCloseButton(closeable and true or false)

	local scrollbarmargin = 5
	local scrollbar = vgui.Create("DScrollPanel", qpanel)
	local w,h = width - scrollbarmargin*2 , height- scrollbarmargin*2-25
	scrollbar:SetSize(w,h)
	scrollbar:SetPos(scrollbarmargin, scrollbarmargin+25)
	
	local holder = vgui.Create( "DIconLayout", scrollbar )
	holder:SetSize(w,h)
	holder:SetPos(0, 0)
	holder:SetSpaceY(5)
	holder:SetSpaceX(5)
	--gui.EnableScreenClicker(!LocalPlayer():TTTAlive())
	w = w-1
	h = 25
	for i,v in pairs(opts) do
		local ipan = holder:Add("DPanel")
		
		ipan:SetSize(w,h)
		function ipan:Paint()
			draw.RoundedBox(2, 0, 0, w, h, Color(0,0,0))
			draw.RoundedBox(2, 1, 1, w-2, h-2, Color(100,100,100))
			draw.SimpleText(v, "TabLarge", 3, h/2+1, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		local canuse = false
		function ipan:OnMousePressed()
			canuse = true
		end
		
		function ipan:OnMouseReleased()
			if !canuse then return end
			qpanel:Close()
			callback(i)
		end
	end
	qpanel:MakePopup()
	if center then qpanel:Center() end
end

net.Receive("diag",function()
	local question = net.ReadString()
	local opts = net.ReadTable()
	local voteid = net.ReadString()
	diag{
		question = question,
		opts = opts,
		onAnswer = function(a)
			RunConsoleCommand("vote",voteid,a)
		end,
		x = ScrW()-310,
		y = 200,
		w = 300,
		h = 300,
	}
end)

concommand.Add("testdiag",function(ply,cmd,args)
	diag{
		question = args[1],
		opts = string.Explode("||",args[2]),
		onAnswer = print,
		w = 300,
		h = 300,
		center = true
	}
end)
local noconfirm = CreateClientConVar("noconfirm","0",true,false)
local function confirm(callback,donothingifno)
	if noconfirm:GetBool() then
		callback(true)
		return
	end
	diag{
		question = "Are you sure?",
		opts = {"Yes","No"},
		onAnswer = function(i) 
			if donothingifno and i == 2 then return end
			callback(i == 1) 
		end,
		w = 100,
		h = 100,
		center = true
	}
end
local function unbox(recalc)
	local qpanel = vgui.Create("DFrame")
	local sw,sh = ScrW(),ScrH()
	local w,h = 200,200
	qpanel:SetSize(w,h)
	qpanel:SetTitle("Unboxing...")
	qpanel:SetVisible(true)
	qpanel:SetDraggable(true)
	qpanel:ShowCloseButton(false)
	
	local unboxsc = vgui.Create( "DPanel", qpanel )
	h = h - 25
	w = w - 4
	unboxsc:SetSize(w,h)
	unboxsc:SetPos(2, 20)
	local timeleft = 5
	timer.Create("unbox"..nn(),1,5,function()
		timeleft = timeleft - 1
	end)
	timer.Simple(5,function() 
		qpanel:Close()
	end)
	function unboxsc:Paint()
		draw.RoundedBox(2, 0, 0, w, h, Color(0,0,0))
		draw.RoundedBox(2, 1, 1, w-2, h-2, Color(100,100,100))
		draw.ShadowedText(timeleft.."...", "HealthAmmo", w/2,h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	qpanel:MakePopup()
	qpanel:Center()
	surface.PlaySound( "johns/cratestart.wav" )
	timer.Simple(5,function() 
		RunConsoleCommand("requestitems") 
		surface.PlaySound( "johns/cratecomplete.wav" )
	end)
	timer.Simple(6,recalc)
end

local showinv
local tradewindow
local partnetitems = {}
local youritems = {}
local yourholder,theirholder

local function painttradeitem(draw,item)
	function li:Paint()
		if item then
			draw.RoundedBox(4, 0, 0, 80, 40, item:getRarityColor())
			draw.SimpleText(item:getNameNT(), "TabLarge", 40, 20, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			if critera and !critera(item,i) then draw.RoundedBox(4, 0, 0, 80, 40, Color(0,0,0,150)) end
		else 
			draw.RoundedBox(4, 0, 0, 80, 40, critera and !critera() and Color(100,100,100) or Color(255,255,255))
		end
	end
end

local reshowyour = function()
	local hover
	local hlparpos
	local hparpos
	yourholder:Clear()
end
local reshowtheir = function()
	theirholder:Clear()
end
local addTradeItem = function(i)
	if table.HasValue(youritems,i) then return end
	table.insert(youritems,i)
	reshowyour()
end
local showtrade = function()
	tradewindow = vgui.Create("DFrame")
	local sw,sh = ScrW(),ScrH()
	local width,height = 800,400
	tradewindow:SetSize(width,height)
	tradewindow:SetPos(sw/2-width/2+310,sh/2-height/2)
	tradewindow:SetTitle("Trade")
	tradewindow:SetVisible(true)
	tradewindow:SetDraggable(true)
	tradewindow:ShowCloseButton(true)
	
	local itempanelsizex,itempanelsizey = 300,200
	local buffer = 10
	
	local your = vgui.Create("DScrollPanel", tradewindow)
	your:SetSize(itempanelsizex - buffer , itempanelsizey - buffer)
	your:SetPos(buffer, buffer + 15)
	
	local their = vgui.Create("DScrollPanel", tradewindow)
	their:SetSize(itempanelsizex - buffer , itempanelsizey - buffer)
	their:SetPos(width - (itempanelsizex + buffer), buffer+15)
	
	yourholder = vgui.Create( "DIconLayout", your )
	yourholder:SetSize(itempanelsizex - buffer - 15, itempanelsizey - buffer-15)
	yourholder:SetPos(0, 0)
	yourholder:SetSpaceY(5)
	yourholder:SetSpaceX(5)
	
	theirholder = vgui.Create( "DIconLayout", their )
	theirholder:SetSize(itempanelsizex - buffer - 15, itempanelsizey - buffer-15)
	theirholder:SetPos(0, 0)
	theirholder:SetSpaceY(5)
	theirholder:SetSpaceX(5)
	
	reshowyour()
	reshowtheir()
	
	tradewindow:MakePopup()
	tradewindow:MoveToFront()
end
net.Receive("synctrade",function()
	local close = net.ReadString()
	partneritems = net.ReadTable()
	
	if close == "1" then 
		tradewindow:Close()
		tradewindow = nil
	elseif !tradewindow then
		showtrade()
		if !mainpanel then RunConsoleCommand("gm_showspare1") end
	end
end)
local useModelPanel = CreateClientConVar("usemodelpanel",  0, true, false)
local invrows = CreateClientConVar("invrowsmin", 12, true, false)
showinv = (function()
	local recalc
	itemsnew = 0
	mainpanel = vgui.Create("DFrame")
	local sw,sh = ScrW(),ScrH()
	local width,height = 800,600
	mainpanel:SetSize(width,height)
	mainpanel:SetTitle("Inventory")
	mainpanel:SetVisible(true)
	mainpanel:SetDraggable(true)
	mainpanel:ShowCloseButton(true)

	local scrollbarmargin = 10
	local scrollbar = vgui.Create("DScrollPanel", mainpanel)
	scrollbar:SetSize(width - scrollbarmargin*2 , height- scrollbarmargin*2-25)
	scrollbar:SetPos(scrollbarmargin, scrollbarmargin+25)
	
	local holder = vgui.Create( "DIconLayout", scrollbar )
	holder:SetSize(width - scrollbarmargin*2 - 15, height- scrollbarmargin*2-25)
	holder:SetPos(0, 0)
	holder:SetSpaceY(5)
	holder:SetSpaceX(5)

	local itemsize = #LocalPlayer():getItems()+9-((#LocalPlayer():getItems())%9)
	local critera
	local iid
	local oncomp
	local function createoptions(item,i)
		--print(item:getFlags(),USEABLE,EQUIPABLE,KEY)
		local opts = {}
		if tradewindow then
			if !item:hasFlag(UNTRADABLE) then
				table.insert(opts,{"Add to trade",function()
					addTradeItem(i)
				end})
			end
			-- print("Useable")
		end
		if item:hasFlag(USEABLE) then
			table.insert(opts,{"Use",function()
				if !LocalPlayer():canUseItem(item) then return end
				RunConsoleCommand("useitem",i)
				LocalPlayer().items[i] = nil
				recalc()
			end})
			-- print("Useable")
		end
		if item:hasFlag(EQUIPABLE) then
			if table.HasValue(LocalPlayer().equips,"__ref"..i) then
				table.insert(opts,{"Unequip",function()
					RunConsoleCommand("unequip",item:getData("slot"))
					LocalPlayer().equips[item:getData("slot")] = nil
				end})
			else
				table.insert(opts,{"Equip",function()
					RunConsoleCommand("equip",i)
					LocalPlayer().equips[item:getData("slot")] = "__ref"..i
				end})
			end
			-- print("Equipable")
		end
		if item:hasFlag(USEOTHER) then
			table.insert(opts,{"Use on item",function()
				if item:getData("iskey") then
					critera = function(item2)
						if !item2 then return false end
						return LocalPlayer():canUseItemOn(item,item2)
					end	
					oncomp = function(a,b)
						LocalPlayer().items[a] = nil
						LocalPlayer().items[b] = nil
						timer.Simple(4.8,function() RunConsoleCommand("useitemon",a,b) end)
						unbox(recalc)
					end
				elseif item:getData("strangepartname") then
					critera = function(item2)
						if !item2 then return false end
						return item2:hasFlag(STRANGEPARTS)
					end	
					oncomp = function(a,b)
						LocalPlayer().items[a] = nil
						RunConsoleCommand("useitemon",a,b)
					end
				else
					critera = item:getData("criteria")
				end
				iid = i
				oncomp = function(a,b)
					
					LocalPlayer().items[a] = nil
					LocalPlayer().items[b] = nil
					timer.Simple(4.8,function() RunConsoleCommand("useitemon",a,b) end)
					unbox(recalc)
				end
			end})
			-- print("KEY")
		end
		table.insert(opts,{"Move to",function()
			critera = function(_,place) return place ~= i end
			iid = i
			oncomp = function(a,b)
				RunConsoleCommand("swapitem",a,b)
				LocalPlayer():swapItem(a,b)
				recalc()
			end
		end})
		table.insert(opts,{"Delete",function()
			confirm(function()
				RunConsoleCommand("delitem",i)
				LocalPlayer().items[i] = nil
				recalc()
			end,true)
		end})
		if !item:hasFlag(UNTRADABLE) then
			table.insert(opts,{"Gift",function()
				local options = {}
				for i,v in ipairs(player.GetAll()) do
					options[i] = gn(v)
				end
				diag{
					question = "Gift whom?",
					opts = options,
					center = true,
					w = 300,
					h = 500,
					closeable = true,
					onAnswer = function(toply) confirm(function()
							RunConsoleCommand("itemto",toply,i)
							LocalPlayer().items[i] = nil
							recalc()
						end,true)
					end
				}
			end})
		end
		return opts
	end
	recalc = function()
	if IsValid(holder) then holder:Clear() end
	local hmenu
	local hover
	
	local hlparpos
	local hparpos
	local setposh = function()
		if !hover then return end
		hover:SetPos(hlparpos[1] < 400 and (hlparpos[1]+ (gui.MouseX() - hparpos[1])+4) or (hlparpos[1] + (gui.MouseX() - hparpos[1])-334),hlparpos[2] + (gui.MouseY() - hparpos[2])+4)
	end
	local douseModelPanel = useModelPanel:GetBool()
	local minobjs = (invrows:GetInt())*9 or 108
	for i = 1, itemsize < minobjs and minobjs or itemsize do
		
		local li = holder:Add("DPanel")
		li:SetSize(80, 40)
		local item = LocalPlayer():getItem(i)
		function li:Paint()
			if item then
				draw.RoundedBox(4, 0, 0, 80, 40, item:getRarityColor())
				if !douseModelPanel or !item:getData("gun") then draw.SimpleText(item:getNameNT(), "TabLarge", 40, 20, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
				if critera and !critera(item,i) then draw.RoundedBox(4, 0, 0, 80, 40, Color(0,0,0,150)) end
			else 
				draw.RoundedBox(4, 0, 0, 80, 40, critera and !critera() and Color(100,100,100) or Color(255,255,255))
			end
		end
		if item then
			-- if douseModelPanel and item:getData("gun") then
				-- local icon = vgui.Create( "DModelPanel", li )
				-- icon:SetSize(40,40)
				-- icon:SetPos(20,0)
				-- icon:SetModel(weapons.Get(item:getData("gun")).WorldModel)
			-- end
			-- function li:OnCursorEntered()
				--openmenu(opts)
				-- newpanel(item,i)
			-- end
			-- function li:OnCursorExited()
				-- closepanel()
			-- end
			function li:OnMousePressed(button)
				if button == MOUSE_RIGHT then
					critera = nil
					if hmenu then hmenu:Remove() end 
					hmenu = nil 
					return
				end
				if critera then
					if critera(item) then
						critera = nil
						oncomp(iid,i)
					end
					return
				end
				if hmenu then 
					hmenu:Remove() 
					hmenu = nil 
				end
				hmenu = vgui.Create("DPanel",scrollbar)
				local opts = createoptions(item,i)
				local nopts = #opts
				--if nopts == 0 then print("no options") return end
				local onesize = 30
				local w,h = 120, (nopts)*onesize
				hmenu:SetSize(w,h)
				-- hmenu:SetParent(holder)
				local parsize = ({li:GetSize()})
				local lparpos = {li:GetPos()}
				local parpos = {getGlobalPos(li)}
				hmenu:SetPos(lparpos[1] + (gui.MouseX() - parpos[1]),lparpos[2] + (gui.MouseY() - parpos[2]))
				-- print(gui.MouseX(),gui.MouseY())
				-- print(w,h)
				local copt = 0
				function hmenu:Paint()
					draw.RoundedBox(2, 0, 0, w, h, Color(0,0,0))
					draw.RoundedBox(2, 1, 1, w-2, h-2, Color(100,100,100))
					local ind = 1
					for k,x in pairs(opts) do
						draw.SimpleText(x[1], "TabLarge", 60, ind*onesize-onesize/2, copt == k and Color(0,200,200) or Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						ind = ind + 1
					end
				end
				local canuse = false
				function hmenu:OnMousePressed()
					canuse = true
				end
				function hmenu:OnCursorMoved()
					local parpos = {getGlobalPos(self)}
					copt = math.floor((gui.MouseY() - parpos[2])/onesize) + 1
				end
				function hmenu:OnCursorExited()
					copt = -1
				end
				
				function hmenu:OnMouseReleased()
					if !canuse then return end
					local parpos = {getGlobalPos(self)}
					local func = opts[math.floor((gui.MouseY() - parpos[2])/onesize) + 1][2]
					if func then func() end
					hmenu:Remove()
				end
				
			end
			
			function li:OnMouseReleased()
				-- hmenu:Remove()
			end
			
			
			
			
			
			
			function li:OnCursorEntered(button)
				if hover then 
					hover:Remove() 
				end
				hover = vgui.Create("DPanel",scrollbar)

				--if nopts == 0 then print("no options") return end
				local w,h = 330,72
				hover:SetSize(w,h)
				-- hmenu:SetParent(holder)
				
				hlparpos = {li:GetPos()}
				hparpos = {getGlobalPos(li)}
				setposh()
				local iname = item:getName()
				local idesc = item:getData("desc") or "No description"
				local idesc2 = item:getData("desc2")
				local extra = item:getData()
				local irarity = item:getRarity()
				local untradable = item:hasFlag(UNTRADABLE)
				local color
				local margin = 3
				h = 30+6+15
				if idesc2 then h = h + 15 end
				if extra.keyid then h = h + 15 end
				if extra.strangekills then h = h + 15 end
				if extra.event then h = h + 15 end
				if extra.autograph then h = h + 15 end
				if untradable then h = h + 15 end
				if extra.strangeparts then 
					for i,v in pairs(extra.strangeparts) do
						h = h + 15 
					end
				end
				if extra.baseeffect then 
					h = h + 15 
					color = item:getData("effect").color
				end
				local itemsn
				if extra.items then
					local iii = {}
					for i,v in pairs(extra.items) do
						table.insert(iii,ITEM[v]:getNameNT())
					end
					itemsn = table.concat(iii,", ")
					h = h + 15
				end
				hover:SetSize(w,h)
				-- print(gui.MouseX(),gui.MouseY())
				-- print(w,h)
				local dmen = function()
					local drawpos = margin
					local function drawp(inc)
						local oldd = drawpos
						drawpos = drawpos + (inc or 15)
						return oldd
					end
					draw.ShadowedText(iname, "HealthAmmo", margin, drawp(30), irarity == 1 and Color(255,255,255) or RARITY[irarity], TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
					draw.SimpleText(idesc, "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
					if desc2 then draw.SimpleText(idesc2, "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if extra.keyid then draw.SimpleText("Can be opened with '"..ITEM[KEYNAMES[extra.keyid]]:getName().."'", "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if extra.strangekills then draw.SimpleText("Kills: "..extra.strangekills, "TabLarge", margin, drawp(),RARITY[5], TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					
					if extra.baseeffect then 
						local drawy = drawp()
						-- surface.SetFont("TabLarge")
						-- local offset = {surface.GetTextSize("Effect: ")}
						draw.SimpleText("Effect: ", "TabLarge", margin, drawy, Color(200,0,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) 
						draw.SimpleText(extra.baseeffect.." ("..color.r..","..color.g..","..color.b..")", "TabLarge", margin + 37, drawy,color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) 
					end
					if extra.event then draw.SimpleText("Obtained from "..extra.event, "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if extra.autograph then draw.SimpleText("Autographed by "..extra.autograph, "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if untradable then draw.SimpleText("Untradable", "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if itemsn then draw.SimpleText("Possible drops: "..itemsn, "TabLarge", margin, drawp(),Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
					if extra.strangeparts then 
						for i,v in pairs(extra.strangeparts) do
							draw.SimpleText(STRANGEPARTNAME[i]..": "..v, "TabLarge", margin, drawp(),RARITY[5], TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) 
						end
					end
					
				end
				function hover:Paint()
					if hmenu then return end
					draw.RoundedBox(2, 0, 0, w, h, Color(0,0,0))
					draw.RoundedBox(2, 1, 1, w-2, h-2, Color(100,100,100))
					
					dmen()
				end
				function hover:OnCursorMoved(button)
					setposh()
				end
			end
			function li:OnCursorMoved(button)
				setposh()
			end
			function li:OnCursorExited(button)
				if hover then 
					hover:Remove() 
					hover = nil 
				end
			end
			if douseModelPanel and item:getData("gun") then
				local icon = vgui.Create( "SpawnIcon", li )
				icon:SetSize(40,40)
				icon:SetPos(20,0)
				-- icon:SetLookAt(Vector(0,0,0))
				-- icon:SetZoo(Vector(0,0,0))
				icon:SetModel(weapons.Get(item:getData("gun")).WorldModel)
				icon:SetToolTip(nil)
				icon.OnCursorMoved = li.OnCursorMoved
				icon.OnCursorExited = li.OnCursorExited
				icon.OnCursorEntered = li.OnCursorEntered
				icon.OnMousePressed = li.OnMousePressed
				icon.OnMouseReleased = li.OnMouseReleased
			end
		else
			function li:OnMousePressed(button)
				if hmenu then 
					hmenu:Remove() 
					hmenu = nil 
				end
				if critera then
					if button == MOUSE_RIGHT then
						critera = nil
						return
					end
					if critera() then
						critera = nil
						oncomp(iid,i)
					end
					return
				end
			end
		end
	end
	end
	recalc()
	mainpanel:MakePopup(true)
	mainpanel:Center(true)
	
end)
net.Receive("openinv",function()
	-- if mainpanel then
		-- mainpanel:Close()
	-- else
		showinv()
	-- end
end)
-- concommand.Add("eff",function(ply,cmd,args)
	-- local vOffset = Vector(0,0,0)
	-- local vAngle = LocalPlayer():GetAngles()
	-- local emitter = ParticleEmitter( vOffset, false )
	-- for i = 0,5 do
		-- timer.Create(LocalPlayer():EntIndex().."eff"..i,.01,0,function()
			 -- local BoneIndx = LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")
			-- local BonePos , BoneAng = LocalPlayer():GetBonePosition( BoneIndx )
			
			-- local paricled = 10
			-- local particle = emitter:Add( "effects/softglow", BonePos + Vector(0,0,5) + Vector(math.random(paricled),math.random(paricled),math.random(paricled))-Vector(paricled/2,paricled/2,paricled/2))
			
			
			-- if ( particle ) then
				-- particle:SetAngles( vAngle )
				-- particle:SetVelocity( Vector( 0, 0, 100 ) )
				-- particle:SetColor( 0, 255, 0 )
				-- particle:SetLifeTime( 0 )
				-- particle:SetDieTime( .25 )
				-- particle:SetStartAlpha( 255 )
				-- particle:SetEndAlpha( 255 )
				-- particle:SetStartSize( 10 )
				-- particle:SetStartLength( 10 )
				-- particle:SetEndSize( 0 )
				-- particle:SetEndLength( 0 )
			-- end
		-- end)
	-- end
-- end)