local function playerSend( from, to )
	local force = from:GetMoveType() == MOVETYPE_NOCLIP
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
addCommand("bring",function(ply,args,silent)
	if ply == NULL then print("Thats not very easy...") return end
	local targets = getPlayers(ply,args[1])
	
	for i,target_ply in pairs(targets) do
		-- if !target_ply then return end
			if target_ply ~= ply then
			local newpos = playerSend(target_ply, ply)
			local newang = (ply:GetPos() - newpos):Angle()
			target_ply:SetPos(newpos)
			target_ply:SetEyeAngles(newang)
			target_ply:SetLocalVelocity(Vector(0, 0, 0)) -- Stop!
		end
	end
	telltab(targets,formatcString{silent and NULL or ply," brought you."})
	telltab(ply,formatcString{"You brought ",targets})
end)
addCommand("goto",function(ply,args,silent)
	local target = getPlayers(ply,args[1])
	if !target[1] or target[2] then tellctab(ply,"You must run this command on one person.") return end
	if target[1] == ply then tellctab(ply,"You are already at yourself.") return end
	target = target[1]
	-- if !target_ply then return end
	local newpos = playerSend(ply, target[1])
	if !newpos then tellctab(ply,"Teleport failed.") return end
	local newang = (target:GetPos() - newpos):Angle()
	ply:SetPos(newpos)
	ply:SetEyeAngles(newang)
	ply:SetLocalVelocity(Vector(0, 0, 0)) -- Stop!
	if !silent then telltab(target,formatcString{ply," teleported to you."}) end
	telltab(ply,formatcString{"You teleported to ",target,"."})
end)