local MsgHandler = require "SurviveServer.netcmd.msghandler"
local Name2idx = require "SurviveServer.common.name2idx"
local Db = require "SurviveServer.common.db"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local Bag = require "SurviveServer.groupserver.bag"
local Task = require "SurviveServer.groupserver.everydaytask"
require "SurviveServer.common.TableRole"
require "SurviveServer.common.TableEquipment"
require "SurviveServer.common.TableExperience"
require "SurviveServer.common.TableItem"
require "SurviveServer.common.TableIntensify"
require "SurviveServer.common.TableRising_Star"
require "SurviveServer.common.TableStone"

MsgHandler.RegHandler(NetCmd.CMD_CG_EQUIP_UPRADE,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local pos   =  rpk:Read_uint8()
		if pos < Bag.weapon or pos > Bag.cloth then
			return
		end
		local equip = ply.bag:GetBagItem(pos)
		if not equip then return end
		local equip_tb = TableItem[equip.id]
		if not  equip_tb then return end
		local equip_type = equip_tb["Item_Type"]
		if equip_type < Bag.weapon and equip_type > Bag.cloth then
			return
		end
		local use_level = equip_tb["Use_level"]
		local ply_level = ply.attr:Get("level")
		local strengthen_lev =  equip:GetAttrHigh(3) + 1--bit32.rshift(attr3,16) + 1
		if  strengthen_lev > ply_level then
			return
		end	
		local tb_Intensify = TableIntensify[strengthen_lev]
		if not tb_Intensify then
			return
		end
		local need_shell = tb_Intensify["Money"]
		local shell = ply.attr:Get("shell")
		if need_shell > shell then
			return
		end
		if strengthen_lev == use_level + 5 then--math.fmod(strengthen_lev,5) == 0 then
			if not TableItem[equip.id+1] then
				return
			end 
			equip.id = equip.id + 1
		end
		--attr3 = bit32.bor(bit32.lshift(strengthen_lev,16), bit32.band(attr3,0x0000FFFF))
		equip:SetAttrHigh(3,strengthen_lev)
		--equip:SetAttr({3},{attr3})
		shell = shell - need_shell
		ply.attr:Set("shell",shell)
		ply.bag:SetBagItem(pos,equip)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply:CalAttr(true)
		ply.attr:DbSave()
		ply.task:OnEvent(Task.TaskType.EQUIPUPGRADE)
		--[[local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_NOTIOPSUCCESS)
		wpk:Write_uint8(noti_equipupgrade_success)
		ply:Send2Client(wpk)]]--
	end		
end)

local function setStone(equip,stonepos,stone)
	if stonepos == 1 then
		equip:SetAttrHigh(1,stone)
		return true
	elseif stonepos == 2 then
		equip:SetAttrLow(1,stone)
		return true
	elseif stonepos == 3 then
		equip:SetAttrHigh(2,stone)
		return true
	elseif stonepos == 4 then
		equip:SetAttrLow(2,stone)
		return true
	end
	return false
end


MsgHandler.RegHandler(NetCmd.CMD_CG_EQUIP_UNINSET,function (sock,rpk)
	print("CMD_CG_EQUIP_UNINSET")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.gatesession then
		local eq_pos = rpk:Read_uint8();
		local stone_pos = rpk:Read_uint8();
		if eq_pos < Bag.weapon or eq_pos > Bag.cloth then
			return
		end
		local equip = ply.bag:GetBagItem(eq_pos)
		if not equip then return end
		local equip_tb = TableItem[equip.id]
		if not  equip_tb then return end
		local equip_type = equip_tb["Item_Type"]
		if equip_type < Bag.weapon and equip_type > Bag.cloth then
			return
		end		
		local stoneid = getStone(equip,stone_pos)
		if not stoneid or stoneid == 0 then
			return
		end
		if ply.bag:AddItem(stoneid,1) then
			setStone(equip,stone_pos,0)
			ply.bag:SetBagItem(eq_pos,equip)
			ply.bag:NotifyUpdate()
			ply.bag:Save()
			ply:CalAttr(true)
			ply.attr:DbSave()
			--[[local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_NOTIOPSUCCESS)
			wpk:Write_uint8(noti_equipuninst_success)
			ply:Send2Client(wpk)]]--				
		end
	end
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_EQUIP_INSET,function (sock,rpk)
	print("CMD_CG_EQUIP_INSET")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.gatesession then
		local eq_pos = rpk:Read_uint8();
		local stone_pos = rpk:Read_uint8();
		local stoneid = rpk:Read_uint16();
		if eq_pos < Bag.weapon or eq_pos > Bag.cloth then
			return
		end
		local equip = ply.bag:GetBagItem(eq_pos)
		if not equip then return end
		local equip_tb = TableItem[equip.id]
		if not  equip_tb then return end
		local equip_type = equip_tb["Item_Type"]
		if equip_type < Bag.weapon and equip_type > Bag.cloth then
			return
		end
		if getStone(equip,stone_pos) ~= 0 then
			return
		end
		local stone_tb = TableStone[stoneid]
		if not stone_tb or stone_tb["Seat"] ~= eq_pos then
			return
		end
		if ply.bag:RemItem(nil,stoneid,1) then
			setStone(equip,stone_pos,stoneid)
			ply.bag:SetBagItem(eq_pos,equip)
			ply.bag:NotifyUpdate()
			ply.bag:Save()
			ply:CalAttr(true)
			ply.attr:DbSave()
			--[[local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_NOTIOPSUCCESS)
			wpk:Write_uint8(noti_equipinst_success)
			ply:Send2Client(wpk)]]--							
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_EQUIP_ADDSTAR,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local pos   =  rpk:Read_uint8()
		if pos < Bag.weapon or pos > Bag.cloth then
			return
		end
		local equip = ply.bag:GetBagItem(pos)
		if not equip then return end
		local equip_tb = TableItem[equip.id]
		if not  equip_tb then return end
		local equip_type = equip_tb["Item_Type"]
		if equip_type < Bag.weapon and equip_type > Bag.cloth then
			return
		end
		--local attr3 = equip:GetAttr({3})
		local star = equip:GetAttrLow(3)--bit32.band(attr3,0x0000FFFF)

		if star == 60 then
			return
		end
		star = star + 1
		local tb_RisingStar = TableRising_Star[star]
		local need_shell = tb_RisingStar["Money"]
		local shell = ply.attr:Get("shell")
		if need_shell > shell then
			return
		end
		--attr3 = attr3 + 1
		--equip:SetAttr({3},{attr3})
		equip:SetAttrLow(3,star)
		shell = shell - need_shell
		ply.attr:Set("shell",shell)
		ply.bag:SetBagItem(pos,equip)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply:CalAttr(true)
		ply.attr:DbSave()
		ply.task:OnEvent(Task.TaskType.ADDSTAR)
		--[[
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_NOTIOPSUCCESS)
		wpk:Write_uint8(noti_equipaddstar_success)
		ply:Send2Client(wpk)]]--		
	end		
end)