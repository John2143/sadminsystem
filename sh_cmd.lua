AddCSLuaFile()
-- local META_player = FindMetaTable("Player")
COMMANDS = {}
GROUP = {}

local __GROUPMETATABLE = {}
function __GROUPMETATABLE:getName()
	return self[2]
end
function __GROUPMETATABLE:getNameBrackets()
	return "["..self:getName().."]"
end
function __GROUPMETATABLE:getColor()
	return self[1]
end
function __GROUPMETATABLE:getCommands()
	return self[4]
end
function __GROUPMETATABLE:getBaseCommands()
	return self[5]
end
function __GROUPMETATABLE:getBaseName()
	return self[6]
end
function __GROUPMETATABLE:getParent()
	return GROUP[self[3]]
end

function META_player:getGroup()
	return GROUP[self.group or "guest"]
end


function addGroup(name,color,dname,commands,inherit)
	GROUP[name] = {}
	setmetatable(GROUP[name],{__index = __GROUPMETATABLE})
	GROUP[name][1] = color
	GROUP[name][2] = dname
	GROUP[name][3] = inherit
	local cmds = commands
	if GROUP[inherit] then
		for i,v in pairs(GROUP[inherit]:getCommands()) do
			table.insert(cmds,v)
		end
	end
	GROUP[name][4] = cmds
	GROUP[name][5] = commands
	GROUP[name][6] = name
end

function addCommand(name,func,raw)
	COMMANDS[name] = {}
	if CLIENT then return end
	COMMANDS[name].func = func
	COMMANDS[name].raw = raw
	COMMANDS[name].lcname = name
end

for i,v,d in pairs(file.Find("addons/poopinmymouth/lua/commands/*","GAME")) do
	AddCSLuaFile("commands/"..v)
	include("commands/"..v)
end
GROUP = file.flLoad("groups")
-- local gg = {}
if !GROUP then
	GROUP = {}
	-- setmetatable(GROUP,{
		-- __newindex = function(tab,ind,val)
			-- print(val," was added") 
			-- gg[ind] = val
		-- end,
		-- __index = function(tab,ind)
			-- print(ind," was accessed")
			-- return gg[ind]
		-- end
	-- })
	addGroup("guest",Color(150,150,150),"Guest",{"who"})
	addGroup("mod",Color(53,120,255),"Mod",{"say","kick"},"guest")
	addGroup("admin",Color(200,0,0),"Admin",{"csay"},"mod")
	addGroup("dev",Color(255,0,123),"Dev",{"rcon","setrank"},"admin")
	-- PrintTable(GROUP)
	-- file.flSave("groups",GROUP)
else
	for i,v in pairs(GROUP) do
		setmetatable(GROUP[i],{__index = __GROUPMETATABLE})
	end
end
