local Timer = require "lua.timer"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local Item = require "groupserver.item"
local Game = require "groupserver.game"
local RPC = require "lua.rpc"
local Bag = require "groupserver.bag"
local Util = require "groupserver.util"
local AlarmClock = require "lua.alarmclock"
require "common.TablePond"
require "common.TableLive_Reward"



local vipPond = {}
local normalPond = {}
local award = {}

do
	local _vipPond = Util.SplitString(TablePond[1].Item,",")
	for k,v in pairs(_vipPond) do
		local tmp2 = Util.SplitString(v,":")
		tmp2[1] = tonumber(tmp2[1])
		tmp2[2] = tonumber(tmp2[2])
		table.insert(vipPond,tmp2)
	end

	local _normalPond = Util.SplitString(TablePond[2].Item,",")
	for k,v in pairs(_normalPond) do
		local tmp2 = Util.SplitString(v,":")
		tmp2[1] = tonumber(tmp2[1])
		tmp2[2] = tonumber(tmp2[2])
		table.insert(normalPond,tmp2)
	end

	local _award = Util.SplitString(TableLive_Reward[1].live_Reward,",")

	for k,v in pairs(_award) do
		local tmp2 = Util.SplitString(v,":")
		tmp2[1] = tonumber(tmp2[1])
		tmp2[2] = tonumber(tmp2[2])
		table.insert(award,tmp2)
	end
end

--print(award[1][1],award[1][2])
--print(award[2][1],award[2][2])

--[1] = { ["live_Reward"] = [[4002:300,4001:200000]]}

local survive = {
	nextTime,                   --下次开启时间
	applyDeadLine,           --报名截止
	ticketRemain = 45,      --剩余门票数量
	applyers = {},               --已经参加过本轮比赛的玩家
	TransferTimer,
	GameServer,
}

local waitForTransfer = {}


function OnGameDisconnected()
	print("OnGameDisconnected")
	GameServer = nil
	applyers = {}
	waitForTransfer = {}
end

--报名
local function Apply(ply)
	local now = os.time()
	if now < nextTime then
		return "生存挑战未开启"
	end 

	if now > applyDeadLine then
		return "生存挑战未开启"
	end

	if applyers[ply.chaid] then
		return "你已经参加过本轮游戏"
	end

	--[[
	if ticketRemain == 0 then
		return "人数已满"
	end
	]]--	

	return nil,10--ticketRemain
end



local function PackPlayer(ply,item)
	local gatesession = nil
	if ply.gatesession then
		gatesession = {name=ply.gatesession.gate.name,id=ply.gatesession.sessionid}
	end
	return 	{
			nickname=ply.nickname,
			actname=ply.actname,
			gatesession = gatesession,
			groupsession = ply.groupsession,
			avatid = ply.avatarid,
			weapon = {id = ply.bag:GetItemId(Bag.weapon),count = ply.bag:GetItemCount(Bag.weapon),attr = ply.bag:GetItemAttr(Bag.weapon)},
			fashion = ply.bag:GetItemId(Bag.fashion),		
			attr = ply.attr:Pack2Game(),
			skills = ply.skills:GetSkills(),
			battleitem = ply.bag:FetchBattleItem(),
			item = item,
		}	
end

local function Transfer(ply,item)
	if not GameServer then
		GameServer = Game.GetMinGame()
		if GameServer  then
			GameServer.survive = survive
		end
	end
	if GameServer then
		ply.status = entermap
		local rpccaller = RPC.MakeRPC(GameServer.sock,"EnterSurvive")	
			
		if item then
			item = {id=item.id,count=item.count,attr = item.attr}
		end

		local err,ret = rpccaller:CallSync(PackPlayer(ply,item),nextTime + 5*60,os.time())
		if not err and ret[1] then
			Game.Bind(GameServer,ply,ret[2])
			ply.mapinstance = 206
		end
	else
		local wpk = CPacket.NewWPacket(256)
		wpk:Write_uint16(NetCmd.CMD_GC_BACK2MAIN)
		ply:Send2Client(wpk)	
		ply.bag:SynBattleItem()	
	end

	ply.status = playing
	return true
end

local function TransferTimerTick()
	local now = C.GetSysTick()
	for k,v in pairs(waitForTransfer) do
		if now >= v.TransferTick then
			Transfer(v.ply,v.item)
			if not GameServer then
				OnGameDisconnected()
			end
			waitForTransfer[k] = nil
		end 
	end
end


local function GenerateItem(vipitem)
	local item
	if vipitem then
		local index = math.random(1,#vipPond)
		item = Util.GenItem(vipPond[index][1],vipPond[index][2])
	else
		local index = math.random(1,#normalPond)
		item = Util.GenItem(normalPond[index][1],normalPond[index][2])		
	end
	return item
end

--确认
local function Confirm(ply,itemno)
	local now = os.time()
	if now < nextTime then
		return false
	end

	if now > applyDeadLine then
		return false
	end

	local item = GenerateItem(selectVipItem)
	if not TransferTimer then
		TransferTimer = Timer.New("runImmediate"):Register(TransferTimerTick,100)
	end

	table.insert(waitForTransfer,{TransferTick=C.GetSysTick()+1500,ply=ply,item=item})
	ply.status = queueing
	applyers[ply.chaid] = ply

	return true,item
end

MsgHandler.RegHandler(NetCmd.CMD_CG_SURVIVE_APPLY,function (sock,rpk)
	print("CMD_CG_SURVIVE_APPLY")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local err,ticketRemain = Apply(ply)
		err = err or ""
		ticketRemain = ticketRemain or 0		
		local wpk = CPacket.NewWPacket(128)
		wpk:Write_uint16(NetCmd.CMD_GC_SURVIVE_APPLY)
		wpk:Write_string(err)
		wpk:Write_uint8(ticketRemain)
		ply:Send2Client(wpk)
	end	
end)


MsgHandler.RegHandler(NetCmd.CMD_CG_SURVIVE_CONFIRM,function (sock,rpk)
	print("CMD_CG_SURVIVE_CONFIRM")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local itemno = rpk:Read_uint8()		
		local ret,item = Confirm(ply,itemno)
		local wpk = CPacket.NewWPacket(128)
		wpk:Write_uint16(NetCmd.CMD_GC_SURVIVE_CONFIRM)
		if not ret then
			wpk:Write_uint8(0)
		else
			wpk:Write_uint8(1)
			if item then
				item:Pack(wpk)
			else
				Item.PackEmpty(wpk)
			end			
		end
		ply:Send2Client(wpk)
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_GAMEG_SURVIVE_FINISH,function (sock,rpk)
	print("CMD_GAMEG_SURVIVE_FINISH")
	local winner = rpk:Read_string()
	local size = rpk:Read_uint8()
	for i=1,size do
		local groupsession = rpk:Read_uint32()
		local ply = GetPlayerBySessionId(groupsession)
		if ply then
			Game.UnBind(ply)
			ply.mapinstance = nil
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_BACK2MAIN)
			ply:Send2Client(wpk)
			ply.bag:SynBattleItem()
			if ply.nickname == winner then
				Util.NewRes(ply,award[1][1],award[1][2])
				Util.NewRes(ply,award[2][1],award[2][2])
				ply.attr:Update2Client()				
			end
			if not ply.gatesession then
				--start a timer
				_,ply.lgTimer = LogOutTimer:Register(function ()
									ReleasePlayer(ply)
									return "stop timer"
			    					       end,release_timeout)
			end				
		end
	end
	applyers = {}
end)

local twTime = CTimeUtil.GetTSWeeHour()
local year,mon,day,hour,min = CTimeUtil.GetYearMonDayHourMin(os.time())
nextTime = twTime + (hour+1) * 3600
applyDeadLine = nextTime + 60*4 + 30

local t = Timer.New("runImmediate"):Register(function ()
		local now = os.time()
		if now > applyDeadLine + 30 then
			nextTime = nextTime + 3600
			applyDeadLine = applyDeadLine + 3600
		end
	end,1000) 


--[[
nextTime = os.time()
applyDeadLine = nextTime + 60*4 + 30

local t = Timer.New("runImmediate"):Register(function ()
		local now = os.time()
		if now > applyDeadLine + 30 then
			nextTime = nextTime + 600
			applyDeadLine = applyDeadLine + 600
		end
	end,1000) 

]]--

return {
	Transfer = Transfer,
}








