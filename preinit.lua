AddCSLuaFile()

function concommand.AddC(name,cfunc)
	concommand.Add(name,function(ply,cmd,args)
		if ply ~= NULL then
			ply:tell({Color(200,0,0),"This is a server only command."})
			return
		end	
		cfunc(ply,cmd,args)
	end)
end

function formatString(args,def,prefixes)
	local tab = {}
	local lastwascolor = false
	def = def or 
	for i,v in pairs(args) do
		if type(v) == "player" then
			if !lastwascolor then table.insert(tab,v:namecolor()) end
			table.insert(tab,gn(v))
			lastwascolor = false
		elseif type(v) == "table" 
			if tab.r and tab.b and tab.g then
				lastwascolor = true
				table.insert(tab,v)
			else
				local numplys = #v
				for k,x in ipairs(v) do
					if prefixes then
						table.insert(tab,v.prefixc)
						table.insert(tab,sp(v.prefix))
					end
					table.insert(tab,v:namecolor())
					table.insert(tab,gn(v))
					if numplys ~= k then 
						table.insert(tab,def)
						table.insert(tab,", ")
					end
				end
			end
		elseif type(v) == "string" then
			if !lastwascolor then table.insert(tab,def) end
			table.insert(tab,gn(v))
			lastwascolor = false
		else
			table.insert(tab,v)
		end
	end
	return tab
end
telltab(player.GetAll(),formatString(player.GetAll()[1],"edge (",player.GetAll(),")",Color(200,200,200)))
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