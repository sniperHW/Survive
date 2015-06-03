local MsgHandler = require "netcmd.msghandler"
local Name2idx = require "common.name2idx"
local Db = require "common.db"
local NetCmd = require "netcmd.netcmd"
local Bag = require "groupserver.bag"
local Task = require "groupserver.everydaytask"
local Achi = require "groupserver.achievement"
local Util = require "groupserver.util"
require "common.TableRole"
require "common.TableEquipment"
require "common.TableExperience"
require "common.TableItem"
require "common.TableIntensify"
require "common.TableRising_Star"
require "common.TableStone"
require "common.TableSynthesis"
require "common.TableStone_Synthesis"


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
		--[[local shell = ply.attr:Get("shell")
		if need_shell > shell then
			return
		end]]--
		if not ply.attr:MoreOrEq("shell",need_shell) then
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
		--shell = shell - need_shell
		--ply.attr:Set("shell",shell)
		ply.attr:Sub("shell",need_shell)
		ply.bag:SetBagItem(pos,equip)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply:CalAttr(true)
		ply.attr:DbSave()
		ply.task:OnEvent(Task.TaskType.EQUIPUPGRADE)
		ply.achieve:OnEvent(Achi.AchiType.ACHI_EQUIP_UPGRADE,strengthen_lev)
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
			ply.achieve:OnEvent(Achi.AchiType.ACHI_EQUIP_INSET)
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
		if not ply.attr:MoreOrEq("shell",need_shell) then
			return
		end		
		equip:SetAttrLow(3,star)
		ply.attr:Sub("shell",need_shell)
		ply.bag:SetBagItem(pos,equip)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply:CalAttr(true)
		ply.attr:DbSave()
		ply.task:OnEvent(Task.TaskType.ADDSTAR)
		ply.achieve:OnEvent(Achi.AchiType.ACHI_EQUIP_ADDSTAR,star)		
	end		
end)


--CMD_CG_STONE_COMPOSITE

MsgHandler.RegHandler(NetCmd.CMD_CG_STONE_COMPOSITE,function (sock,rpk)
	print("CMD_CG_STONE_COMPOSITE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local id = rpk:Read_uint16()
		local bagpos = rpk:Read_uint8()
		local all = rpk:Read_uint8()
		
		local bagitem = ply.bag:GetBagItem(bagpos)
		print(bagpos)
		if not bagitem or bagitem.id ~= id then
			--if bagitem then print(bagitem.id) end
			return
		end
		print(id)
		local tb1 = TableStone[id]
		if not tb1 then
			return
		end
		print("CMD_CG_STONE_COMPOSITE1")
		local tb2 = TableStone_Synthesis[tb1.Stone_Level]
		if not tb2 then
			return
		end
		print("CMD_CG_STONE_COMPOSITE2")
		local count = 1
		if all == 1 then
			count = math.floor(bagitem.count/3)
		end
		print("CMD_CG_STONE_COMPOSITE3")

		if bagitem.count < count*3 then
			return
		end
		print("CMD_CG_STONE_COMPOSITE4")

		local money = tb2.Price
		if ply.attr:Get("shell") < money then
			return
		end
		print("CMD_CG_STONE_COMPOSITE5")

		if not Util.NewRes(ply,tb1.Next_Level,count) then
			return
		end
		print("CMD_CG_STONE_COMPOSITE6")

		bagitem.count = bagitem.count - count*3
		if bagitem.count == 0 then
			bagitem = nil
		end
		print("CMD_CG_STONE_COMPOSITE7")
		ply.bag:SetBagItem(bagpos,bagitem)
		ply.attr:Sub("shell",money)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply.attr:Update2Client()
		ply.attr:DbSave()
		ply.achieve:OnEvent(Achi.AchiType.ACHI_COMPOSITION)		

	end
end)		


MsgHandler.RegHandler(NetCmd.CMD_CG_COMPOSITE,function (sock,rpk)
	print("CMD_CG_COMPOSITE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local id = rpk:Read_uint16()
		local size = rpk:Read_uint8()
		local tb = TableSynthesis[id]
		if not tb then
			return
		end
		local price = tb["Synthesis_Price"]

		if price > ply.attr:Get("shell") then
			return
		end

		local materials = {}
		local i = 1
		while true do
			local key = "Material" .. i
			local val = tb[key]
			if val then
				local tmp = Util.SplitString(val,":")
				tmp[1] = tonumber(tmp[1])
				tmp[2] = tonumber(tmp[2])
				table.insert(materials,tmp)				
			else
				break
			end
			i = i + 1
		end
		if size ~= #materials then
			return
		end
		local bagpos = {}
		for i=1,size do
			table.insert(bagpos,rpk:Read_uint8())
		end
		--check
		for i=1,size do
			local material = materials[i]
			local item = ply.bag:GetBagItem(bagpos[i])
			--print(bagpos[i],item,item.id,item.count,material[1],material[2])
			if not item or item.id ~= material[1] or item.count < material[2] then
				return
			end
		end

		if not Util.NewRes(ply,id,1) then
			return
		end

		for i=1,size do
			local material = materials[i]
			ply.bag:RemItem(bagpos[i],nil,material[2])
		end
		ply.attr:Sub("shell",price)
		ply.bag:NotifyUpdate()
		ply.bag:Save()
		ply.attr:Update2Client()
		ply.attr:DbSave()
		ply.achieve:OnEvent(Achi.AchiType.ACHI_COMPOSITION)	
	end
end)