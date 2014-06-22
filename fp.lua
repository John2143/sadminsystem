--Made by John2143
--	A simple file saving and loading system for players and other stuff

--This character is used in the files to split the indexes from the values
--This means you can't use it in any values
local unsavechar = "º"

local string = string--I don't think I can localize file because I add functions
local meta = FindMetaTable("Player")
local desafetable = {
	n = tonumber,
	c = function(s) 
			local x = string.Explode(",",s)
			return Color(tonumber(x[1]),tonumber(x[2]),tonumber(x[2]))
		end,
	s = tostring,
	f = function() return function() end end,
	e = function() return {} end,
	p = function(s)
			for i,v in ipairs(player.GetAll()) do
				if v:UniqueID() == s then
					return v
				end
			end
		end,
	v = function(s) 
			local x = string.Explode(",",s)
			return Vector(tonumber(x[1]),tonumber(x[2]),tonumber(x[2]))
		end,
	a = function(s) 
			local x = string.Explode(",",s)
			return Angle(tonumber(x[1]),tonumber(x[2]),tonumber(x[2]))
		end,
	b = tobool
}
local safetable = {
	number = "n",
	-- color = function(s)
				-- return "c"..s.r..","..s.g..","..s.b
			-- end,
	string = "s",
	["function"] = function() return "f" end, --functions should not be saved, neither should entities
	Entity = function() return "e" end,
	Player = function(s) return "p"..ply:UniqueID() end,
	Vector = function(s)
				return "v"..s.x..","..s.y..","..s.z
			end,
	Angle = function(s)
				return "a"..s.p..","..s.y..","..s.r
			end,
	bool = "b",
	boolean = "b"
}
local function Safestr(str)
	local x = safetable[tostring(getmetatable(str)):lower()] or safetable[tostring(type(str)):lower()] 
	if x then
		if type(x) == "function" then
			return x(str)
		else
			return x..tostring(str)
		end
	else
		ErrorNoHalt("Unsavabale data type: "..str)
		return "s"..tostring(str)
	end
end
local function deSafestr(str)
	local fc = desafetable[str:sub(1,1)]
	local sc = str:sub(2)
	if !fc then ErrorNoHalt("Unloadable data type: "..fc.."("..sc..")"); return str end
	return fc(sc)
end

file.flSave = function(sstr,tab)
	file.Write(sstr..".txt",file.flSaveRaw(sstr,tab))
end

file.flSaveRaw = function(sstr,tab)
	t = ""
	local numt = 0
	
	local function dosave(tab)
		local s = "\n"..string.rep("\t",numt)
		for i,v in pairs(tab) do
			if type(v) == "table" then
				numt = numt + 1
				t = t..s..Safestr(i)
				dosave(v)
				t = t..s.."-"
				numt = numt - 1
			else
				t = t..s..Safestr(i)..unsavechar..Safestr(v)
			end
		end
	end
	dosave(tab)
	return t.."\n-"
end

file.flLoad = function(tstr)
	local fstr = file.Read(tstr..".txt")
	if !fstr then return false end
	local i,x = 1
	fstr = string.Replace(fstr,"\t","")
	local tab = string.Explode("\n",fstr)
	local function inc()
		i = i + 1
		x = string.Explode(unsavechar,tab[i] or "")
	end
	inc()
	local function doload()
		local rett = {}
		while true do
			if x[1] == "-" then return rett end
			if x[2] then
				rett[deSafestr(x[1])] = deSafestr(x[2])
			else
				local tabname = x[1]
				inc()
				rett[deSafestr(tabname)] = doload()
			end
			inc()
		end
	end
	return doload()
end

function meta:LoadPData(tstr)
	local x = file.flLoad(self:UniqueID()..tstr)
	if !x then return false end
	for i,v in pairs(x) do
		self[i] = v
	end
	return true
end

function meta:SavePData(sstr,data)
	local tab = {}
	for i,v in pairs(data) do
		tab[v] = self[v]
	end
	file.flSave(self:UniqueID()..sstr,tab)
end