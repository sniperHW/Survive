local BuffFunc = {
	LifeRecover_OnBegin = function (buff)
		--print("LifeRecover_OnBegin")
		local avatar = buff.owner
		local maxlife = avatar.attr:Get("maxlife")
		local tb = buff.tb
		avatar.attr:Add("life",tb.Begin_Reply,maxlife)
		avatar.attr:NotifyUpdate()
	end,
	LifeRecover_onInterval =  function (buff)
		local avatar = buff.owner
		local maxlife = avatar.attr:Get("maxlife")
		local tb = buff.tb
		--print("LifeRecover_onInterval",tb.Reply,maxlife)
		avatar.attr:Add("life",tb.Reply,maxlife)
		avatar.attr:NotifyUpdate()		
	end,
	SpeedChange_OnBegin = function (buff)
		local avatar = buff.owner
		local oldspeed = avatar.speed
		local maxspeed = 37
		local minspeed = 17
		local tb = buff.tb
		local newspeed = math.floor(oldspeed * (100 + tb.Move_Speed))
		if newspeed > maxspeed then
			newspeed = maxspeed
		elseif newspeed < minspeed then
			newspeed = minspeed
		end
		avatar.oldspeed = oldspeed
		avatar:SetSpeed(newspeed)
	end,
	SpeedChange_OnEnd = function (buff)
		local avatar = buff.owner
		local oldspeed = avatar.oldspeed
		avatar:SetSpeed(oldspeed)
	end,
	Buff3201_OnBegin = function (buff)
		local avatar = buff.owner
		local skill = avatar.skillmgr:GetSkill(1150)
		if skill then
			avatar.attr:Set("suffer_plusrate",1.5)
		end
	end,
	Buff3201_OnEnd = function (buff)
		local avatar = buff.owner
 		avatar.attr:Set("suffer_plusrate",1)
	end,
	Blackout_OnBegin = function (buff)
		local avatar = buff.owner
		avatar.stick = true
		avatar:StopMov()
	end,
	Blackout_OnEnd = function (buff)
		local avatar = buff.owner
		avatar.stick = nil
	end,
	Buff3002_OnBegin = function (buff)
		local avatar = buff.owner
		avatar.invisible = true
	end,
	Buff3002_OnEnd = function (buff)
		local avatar = buff.owner
		avatar.invisible = false
	end,		
}



return BuffFunc