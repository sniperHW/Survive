local NetCmd = require "netcmd.netcmd"
local Util = require "groupserver.util"
local MsgHandler = require "netcmd.msghandler"
local Name2idx = require "common.name2idx"
require "common.TableFish"
require "common.TableGather"
require "common.TablePractice"
local Achi = require "groupserver.achievement"
local Task = require "groupserver.everydaytask"

--[25] = { ["Jism"] = 3719, ["Drugs"] = "5501:60:34"}, gather
--[15] = { ["Shell"] = 1000, ["Pearl"] = "4002:5:1"},fish


for k,v in pairs(TableGather) do
	v.Drugs = Util.SplitString(v.Drugs,":")
	for k1,v1 in pairs(v.Drugs) do
		v.Drugs[k1] = tonumber(v1)
	end
end

for k,v in pairs(TableFish) do
	v.Pearl = Util.SplitString(v.Pearl,":")
	for k1,v1 in pairs(v.Pearl) do
		v.Pearl[k1] = tonumber(v1)
	end	
end

MsgHandler.RegHandler(NetCmd.CMD_CG_HOMEBALANCE,function (sock,rpk)
	print("CMD_CG_HOMEBALANCE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local action
		local fishing_start = ply.attr:Get("fishing_start")
		local gather_start = ply.attr:Get("gather_start")
		local sit_start = ply.attr:Get("sit_start")
		local start_time
		if fishing_start > 0 then
			action = 1
			ply.attr:Set("fishing_start",0)
			start_time = fishing_start
		elseif gather_start > 0 then
			action = 2
			ply.attr:Set("gather_start",0)
			start_time = gather_start
		elseif sit_start > 0 then
			action = 3
			ply.attr:Set("sit_start",0)
			start_time = sit_start
		end
		
		if action and start_time then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_HOMEBALANCE_RET)
			wpk:Write_uint8(action)			
			local time = os.time() - start_time
			time = math.floor(time/60)
			local time_in_minute = time
			local reward_item 
			if action == 1 then
				local tb = TableFish[ply.attr:Get("level")]
				local shell = tb.Shell * time
				local old = ply.attr:Get("shell")
				shell = ply.attr:Add("shell",shell) - old
				wpk:Write_uint32(shell)
				--shell = shell + ply.attr:Get("shell")
				--ply.attr:Set("shell",shell)
				time = math.floor(time/30)
				if time > 0 then
					reward_item = {tb.Pearl[1],0}
					for i = 1, time do
						local randnum = math.random(1,100)
						if randnum >= tb.Pearl[2] then
							reward_item[2] = reward_item[2] + tb.Pearl[3]
						end 
					end
				else
					reward_item = {0,0}
				end

			elseif action == 2 then
				local tb = TableGather[ply.attr:Get("level")]
				local Jism = tb.Jism * time
				wpk:Write_uint32(Jism)
				time = math.floor(time/30)
				if time > 0 then
					reward_item = {tb.Drugs[1],0}
					for i = 1, time do
						local randnum = math.random(1,100)
						if randnum >= tb.Drugs[2] then
							reward_item[2] = reward_item[2] + tb.Drugs[3]
						end 
					end
				else
					reward_item = {0,0}
				end			
			else
				local tb = TablePractice[ply.attr:Get("level")]
				local exp = tb.Experience * time
				--exp = exp + ply.attr:Get("exp")
				ply:AddExp(exp)
				--ply.attr:Set("exp",exp)				
				wpk:Write_uint32(exp)				
				reward_item = {0,0}
			end

			if time_in_minute > 60 then
				ply.task:OnEvent(Task.TaskType.GUAJI)
			end
			wpk:Write_uint16(reward_item[1])
			wpk:Write_uint32(reward_item[2])
			ply:Send2Client(wpk)
			ply.attr:Update2Client()
			ply.attr:DbSave()			
		end		
	end		
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_HOMEACTION,function (sock,rpk)
	print("CMD_CG_HOMEACTION")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local action = rpk:Read_uint8()
		local fishing_start =  ply.attr:Get("fishing_start")
		local gather_start =  ply.attr:Get("gather_start")
		local sit_start = ply.attr:Get("sit_start")		
		if not (action >= 1 and action <= 3) or 
		  	(fishing_start ~= 0) or (gather_start ~= 0) or (sit_start ~=0 ) then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_HOMEACTION_RET)
			wpk:Write_uint32(0)
			ply:Send2Client(wpk)
		end

		local timestamp = os.time()
		if action == 1 then
			ply.attr:Set("fishing_start",timestamp)
		elseif action == 2 then
			ply.attr:Set("gather_start",timestamp)
		else
			ply.attr:Set("sit_start",timestamp)
		end
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_HOMEACTION_RET)
		wpk:Write_uint32(timestamp)
		wpk:Write_uint8(action)
		ply:Send2Client(wpk)
		ply.attr:Update2Client()
		ply.attr:DbSave()
		ply.achieve:OnEvent(Achi.AchiType.ACHI_GUAJI)
	end		
end)