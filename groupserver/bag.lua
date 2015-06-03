local Cjson = require "cjson"
local Name2idx = require "common.name2idx"
local NetCmd = require "netcmd.netcmd"
local Db = require "common.db"
local Item = require "groupserver.item"
local MsgHandler = require "netcmd.msghandler"
local bag = {}
require "common.TableItem"

function bag:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function bag:Init(ply,bag)
	if bag then
		self.bag = {size = bag.size}
		for k,v in pairs(bag) do
			if k ~= "size" then
				self.bag[tonumber(k)] = Item.New(v.id,v.count,v.attr)
			end
		end
	else
		self.bag = {size=60}
	end
	self.owner = ply
	--self.flag = {}
	return self
end

function bag:GetItemId(pos)
	if self.bag[pos] then
		return self.bag[pos].id
	else
		return nil
	end
end

function bag:GetBagItem(pos)
	return self.bag[pos]
end

function bag:SetBagItem(pos,item)
	if pos > 0 and pos <= self.bag.size then
		self.bag[pos] = item
		self.dbchange = true
		self.flag = self.flag or {}
		self.flag[pos] = true
	end
end

function bag:GetItemCount(pos)
	if self.bag[pos] then
		return self.bag[pos].count
	else
		return nil
	end
end

function bag:GetItemAttr(pos,idxs)
	if self.bag[pos] then
		if idxs then
			return self.bag[pos]:GetAttr(idxs)
		else
			return self.bag[pos].attr
		end
	else
		return nil
	end
end

function bag:SetItemAttr(pos,idxs,vals)
	if self.bag[pos] then
		self.bag[pos]:SetAttr(idxs,vals)
		self.flag = self.flag or {}
		self.flag[pos] = true
		self.dbchange = true	
	end	
end

local function find_battle_item_pos(self,id)
	if not id then
		for i=5,10 do
			if not self.bag[i] then
				return i
			end
		end
		return nil
	else
		local firstempty = nil
		for i=5,10 do
			if self.bag[i] then
				if self.bag[i].id == id then
					return i
				end
			elseif not firstempty then
				firstempty = i
			end
		end
		return firstempty		
	end
end


local function findbagpos(self,id)
	if not id then
		for i=11,self.bag.size do
			if not self.bag[i] then
				return i
			end
		end
		return nil
	else
		local firstempty = nil
		for i=11,self.bag.size do
			if self.bag[i] then
				if self.bag[i].id == id then
					return i
				end
			elseif not firstempty then
				firstempty = i
			end
		end
		return firstempty		
	end
end

--向背包新增加一个物品
function bag:AddItem(id,count,attr)
	if attr then
		local pos = findbagpos(self)
		if pos then
			self.bag[pos] = Item.New(id,count,attr)
			self.flag = self.flag or {}			
			self.flag[pos] = true
			self.dbchange = true			
			return true
		else
			return false
		end
	else
		local pos = findbagpos(self,id)
		if pos then
			if not self.bag[pos] then
				self.bag[pos] = Item.New(id,count,attr)	
			else
				if self.bag[pos].count + count > 65535 then
					self.bag[pos].count = 65535
				else
					self.bag[pos].count = self.bag[pos].count + count
				end
			end
			self.flag = self.flag or {}				
			self.flag[pos] = true
			self.dbchange = true			
			return true					
		else
			return false
		end
	end
end

function bag:AddItems(items)
	local bagpos = {}
	for i = 1,#items do
		local item = items[i]
		local tb = TableItem[item[1]] 
		if not tb then
			return false
		end
		if tb["Item_Type"] < 5 then
			item.isEquip = true
		end
		local fitpos
		for j=11,self.bag.size do
			if item.isEquip then
				if not self.bag[j] and not bagpos[j] then
					fitpos = j
					break
				end 		
			else
				if not self.bag[j] and not fitpos then
					fitpos = j
				elseif self.bag[j] and self.bag[j].id == item[1] then
					fitpos = j
					break
				end
			end
		end
		if not fitpos then
			return false
		end
		if not bagpos[fitpos] then
			bagpos[fitpos] = {}
		end
		table.insert(bagpos[fitpos],item)
	end

	for k,v in pairs(bagpos) do
		local items = v
		for k1,v1 in pairs(items) do
			if v1.isEquip then
				self.bag[k] = Item.New(v1[1],v1[2],v1[3])
			else
				local count = v1[2]
				if not self.bag[k] then
					self.bag[k] = Item.New(v1[1],v1[2])	
				else
					if self.bag[k].count + count > 65535 then
						self.bag[k].count = 65535
					else
						self.bag[k].count = self.bag[k].count + count
					end
				end	
			end
		end
		self.dbchange = true
		self.flag = self.flag or {}				
		self.flag[k] = true
	end
	return true
end

local fashion = 1
local weapon = 2
local belt = 3
local cloth = 4


function bag:LoadBattleItem(pos)
	if pos >= 11 and pos < self.bag.size then
		local item = self.bag[pos]
		if not item then return false end
		local tb =  TableItem[item.id]
		if not tb then return false end
		local tag = tb["Tag"]
		if tag ~= 0 then return false end
		local maxcount = 5
		local battlepos = find_battle_item_pos(self,item.id)
		local battle_item = self.bag[battlepos]	
		if not battle_item then
			if item.count <= maxcount then
				battle_item = item
				item = nil
			else
				battle_item = Item.New(item.id,maxcount)
				item.count = item.count - maxcount
			end
			self:SetBagItem(pos,item)
			self:SetBagItem(battlepos,battle_item)
		else
			local count = maxcount - battle_item.count
			if count == 0 then return false end
			if item.count <= count then
				battle_item.count = battle_item.count + item.count
				item = nil
			else
				battle_item.count = battle_item.count + count
				item.count = item.count - count
			end
			self:SetBagItem(pos,item)
			self:SetBagItem(battlepos,battle_item)			
		end
		return true
	end
	return false
end

function bag:UnLoadBattleItem(pos)
	if pos >= 5 and pos <= 10 then
		local battle_item = self.bag[pos]
		if not battle_item then return false end
		local bagpos = findbagpos(self,battle_item.id)
		if not bagpos then return false end
		local item = self.bag[bagpos]
		if not item then
			item = battle_item
			battle_item = nil
			self:SetBagItem(bagpos,item)
			self:SetBagItem(pos,battle_item)			
		else
			item.count = item.count + battle_item.count 
			if item.count > 65535 then item.count = 65535 end
			battle_item = nil
			self:SetBagItem(bagpos,item)
			self:SetBagItem(pos,battle_item)
		end
		return true
	end
	return false
end

function bag:Swap(pos1,pos2)
	if pos1 < 1 or pos1 > self.bag.size then
		return false
	end
	if pos2 < 1 or pos2 > self.bag.size then
		return false
	end
	if pos1 <= 10 and pos2 <= 10 then
		return false
	end 
	local item1 = self.bag[pos1]
	local item2 = self.bag[pos2]
	if not item1 and not item2 then
		return false
	end
	local type1
	local type2
	if item1 then
		local tb1 =  TableItem[item1.id]
		if not tb1 then return false end
		type1 = tb1["Item_Type"]
		if not type1 then return false end
		if pos2 <= cloth then
			if type1 ~= pos2 then
				return false
			end
			if tb1["Use_level"] > self.owner.attr:Get("level") then
				return false
			end
		elseif pos2 <= 10 then
			local InBattle = tb1["Tag"] == 0
			if not InBattle then
				return false
			end
		end
	end
	if item1 and type1 > cloth and item2 and item1.id == item2.id then --merge
		if item1.count + item2.count > 65535 then
			item2.count = 65535
		else
			item2.count = item1.count + item2.count
		end
		self.flag = self.flag or {}		
		self.bag[pos1] = nil
		self.flag[pos1] = true
		self.flag[pos2] = true
		self.dbchange = true		
		return true
	end
	--ok swap
	self.flag = self.flag or {}	
	self.bag[pos2] = item1
	self.bag[pos1] = item2
	self.flag[pos1] = true
	self.flag[pos2] = true
	self.dbchange = true	
	--print("bag:Swap",pos1,pos2,self.bag[pos1],self.bag[pos2])
	if pos1 >= weapon and pos1 <= cloth or pos2 >= weapon and pos2 <= cloth then
		--print("recalattr")
		return true,"recalattr"
	else
		return true
	end
end

--根据位置或id移除一定数量的物品
function bag:RemItem(pos,id,count)
	if id then
		for i=0,self.bag.size do
			if self.bag[i] and self.bag[i].id == id then
				pos = i
			end
		end
	end
	local item = self.bag[pos]
	if item and item.count >= count then
		item.count = item.count - count
		if item.count == 0 then
			self.bag[pos] = nil
		end
		self.flag = self.flag or {}		
		self.dbchange = true		
		self.flag[pos] = true
		return true
	else
		return false
	end	
end


function bag:FetchBattleItem()
	--print("FetchBattleItem")
	local battleitem = {}
	for i=5,10 do
		local item = self.bag[i]
		if item then
			table.insert(battleitem,{i,item.id,item.count})
		end
	end
	return battleitem
end



function bag:OnBegPly(wpk)
	--先打包battle相关
	wpk:Write_uint8(self.bag.size)		
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)	
	local c = 0
	for k,v in pairs(self.bag) do
		if k ~= "size" then
			wpk:Write_uint8(k)
			v:Pack(wpk)
			c = c + 1
		end
	end
	wpk:Rewrite_uint8(wpos,c)	
end

function bag:DbStr()
	local b = {size = self.bag.size}
	for i=1,b.size do
		local item = self.bag[i]
		if item then
			local attr = item.attr 
			if attr then
				b[i] = {id=item.id,count=item.count,attr = attr}
			else
				b[i] = {id=item.id,count=item.count}
			end
		end
	end	
	return Cjson.encode(b)
end

function bag:Save()
	if self.dbchange then
		local cmd = "hmset chaid:" .. self.owner.chaid .. " bag  " .. self:DbStr()
		Db.CommandAsync(cmd)
		self.dbchange = false
	end	
end

function bag:SynBattleItem()
	if self.owner.gatesession then
		local wpk = CPacket.NewWPacket(512)
		wpk:Write_uint16(NetCmd.CMD_GC_BAGUPDATE)
		wpk:Write_uint8(6)	
		for i = 5,10 do
			wpk:Write_uint8(i)
			local item = self.bag[i]
			if item then
				item:Pack(wpk)
			else
				Item.PackEmpty(wpk)		
			end
		end
		self.owner:Send2Client(wpk)		
	end
end

function bag:NotifyUpdate()
	if self.flag then
		local wpk = CPacket.NewWPacket(512)
		wpk:Write_uint16(NetCmd.CMD_GC_BAGUPDATE)
		local wpos = wpk:Get_write_pos()
		wpk:Write_uint8(0)	
		local c = 0
		for k,v in pairs(self.flag) do
			wpk:Write_uint8(k)
			local item = self.bag[k]
			if item then
				item:Pack(wpk)
			else
				Item.PackEmpty(wpk)		
			end
			c = c + 1
		end
		wpk:Rewrite_uint8(wpos,c)
		self.owner:Send2Client(wpk)
		self.flag = nil
	end	
end

function bag:PeekInfo(wpk,beg_index,end_index)
	if end_index > beg_index or end_index > self.bag.size or beg_index < 0 then
		return false
	end
	local size = end_index - beg_index
	wpk:Write_uint8(size)
	for i = beg_index,end_index do
		wpk:Write_uint8(i)
		local item = self.bag[i]
		if item then
			item:Pack(wpk)
		else
			Item.PackEmpty(wpk)		
		end		
	end
	return true
end

MsgHandler.RegHandler(NetCmd.CMD_CG_USEITEM,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then

	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_REMITEM,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then
		local pos1 = rpk:Read_uint8()
		if ply.bag:RemItem(pos1,nil,65535) then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_LOADBATTLEITEM,function (sock,rpk)
	print("CMD_CG_LOADBATTLEITEM")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then
		local pos = rpk:Read_uint8()
		if ply.bag:LoadBattleItem(pos) then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_UNLOADBATTLEITEM,function (sock,rpk)
	print("CMD_CG_UNLOADBATTLEITEM")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then
		local pos = rpk:Read_uint8()
		if ply.bag:UnLoadBattleItem(pos) then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_SWAP,function (sock,rpk)
	print("CMD_CG_SWAP")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then
		local pos1 = rpk:Read_uint8()
		local pos2 = rpk:Read_uint8()
		local ret,action = ply.bag:Swap(pos1,pos2) 

		if ret then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
			if action == "recalattr" then
				ply:CalAttr(true)
			end
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_SINGLE_USE_ITEM,function (sock,rpk)
	print("CMD_CG_SINGLE_USE_ITEM")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.bag then
		local pos = rpk:Read_uint8()
		if ply.bag:RemItem(pos,nil,1) then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
		end
	end	
end)



local function newRes(ply,param)
	return ply.bag:AddItems(param)
end

return {
	New = function () return bag:new() end,
	NewRes = newRes,
	fashion = fashion,
	weapon = weapon,
	belt = belt,
	cloth = cloth,
}
