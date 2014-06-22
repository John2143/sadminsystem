print("Commands starting")
function getPlayers(ca,str)
	if !str or str == "" then return {} end
	local all = player.GetAll()
	local ret = {}
	local negate = false
	local function addply(ply)
		if negate then
			for i,v in pairs(ret) do
				if ply == v then ret[i] = nil end
			end
		else
			table.insert(ret,ply)
		end
	end
	-- local function addplys(plys)
		-- for i,ply in ipairs(plys) do
			-- addply(ply)
		-- end
	-- end
	for i,v in pairs(string.Explode(",",str)) do
		if v and v:len() > 0 then
			if v:sub(1,1) == "-" then
				negate = true
				v = v:sub(2)
			end
			if v == "*" then
				if negate then 
					ret = {}
				else
					ret = all
				end
			elseif v == "^" then
				addply(ca)
			elseif v == "#" then
				local id = tonumber(v:sub(2))
				for k,x in ipairs(all) do
					if id == x:UserID() then addply(x) break end
				end
			else
				for k,x in ipairs(all) do
					if gn(x):lower():find(v:lower()) or x:SteamID():lower() == v:lower() then addply(x) end
				end
			end
			negate = false
		end
	end
	local ret2 = {}
	for i,v in pairs(ret) do
		local ins
		for k,x in pairs(ret2) do
			if x == v then ins = true end
		end
		if !ins then table.insert(ret2,v) end
	end
	return ret2
end

function parseargs(text)
	local args = {}
	local ind = 0
	local quot = false
	local arg = false
	for i,v in pairs(string.Explode(" ",text)) do
		if quot then
			if v:sub(-1,-1) == '"' then
				quot = false
				table.insert(args,arg.." "..v:sub(1,-2))
			else
				arg = arg.." "..v
			end
		else
			if v:sub(1,1) == '"' then
				quot = true
				arg = v:sub(2)
			else
				table.insert(args,v)
			end
		end
	end
	if quot then table.insert(args,arg:sub(2)) end
	return args
end

function doCommand(self,cname,args)
	if CLIENT then return end
	local cando = false
	local v = COMMANDS[cname]
	if !v then tellctab(self,"Unknown Command") return end
	if self == NULL then
		cando = true
	else
		for k,x in pairs(self:getGroup():getCommands()) do
			if v.lcname == x then cando = true break end
		end
	end
	-- print(cando)
	if cando then 
		if v.raw then
			if !args then args = ""
			elseif type(args) == "table" then args = table.concat(args," ") end
			-- print(args)
		else
			if !args then args = {}
			elseif type(args) == "string" then args = parseargs(args) end
			-- PrintTable(args)
		end
		
		v.func(self,args)
	else
		tellctab(self,"You cannot run that command.")
	end
end
function META_player:doCommand(cname,args)
	doCommand(self,cname,args)
end

concommand.Add("exc",function(ply,cmd,args)
	local cn = args[1]:lower()
	if cn then
		local newargs = {}
		for i=2,#args do
			newargs[i-1] = args[i]
		end
		-- PrintTable(newargs)
		doCommand(ply,cn,newargs)
	else
		tellctab(ply,"Unknown command")
	end
end)

hook.Add("PlayerSay","acommands",function(ply,text,team)
	local sub = text:sub(1,1)
	if sub == "!" or sub == "/" then
		local split = string.find(text," ")
		if split then
			local cmdstr = text:sub(2,split-1):lower()
			ply:doCommand(cmdstr,text:sub(split+1))
		else
			ply:doCommand(text:sub(2):lower(),nil)
		end
		return ""
	end
end)