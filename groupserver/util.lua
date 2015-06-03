
require "common.TableItem"
require "common.TableEquipment"
local Item = require "groupserver.item"

local function SplitString(s,separator)
	local ret = {}
	local initidx = 1
	local spidx
	while true do
		spidx = string.find(s,separator,initidx)
		if not spidx then
			break
		end
		table.insert(ret,string. sub(s,initidx,spidx-1))
		initidx = spidx + 1
	end
	if initidx <= string.len(s) then
		table.insert(ret,string. sub(s,initidx))
	end
	return ret
end

--[[
[4001] = 贝壳,
[4002] = { ["Item_Name"] = 珍珠, 
[4003] = { ["Item_Name"] = 精元,
[4004] = { ["Item_Name"] = 经验, 
]]--

local function NewRes(ply,id,num,attr)
	local itemtb = TableItem[id]
	if not itemtb then return end
	if id == 4001 then
		ply.attr:Add("shell",num)
		return true
	elseif id == 4002 then
		ply.attr:Add("pearl",num)
		return true
	elseif id == 4003 then
		ply.attr:Add("soul",num)
		return true
	elseif id == 4004 then
		ply:AddExp(num)
		return true
	elseif id == 4005 then
		ply.attr:Add("stamina",num)
		return true		
	else
		if  itemtb["Item_Type"] < 5 then
			num = 1
			attr = attr or {0,0,0,0,0,0,0,0,0,0}
		end
		return ply.bag:AddItem(id,num,attr)
	end
	return false
end

local function GenItem(id,num,attr)
	local itemtb = TableItem[id]
	if not itemtb then 
		return nil 
	end
	if  itemtb["Item_Type"] < 5 then
		num = 1
		attr = attr or {0,0,0,0,0,0,0,0,0,0}
	end
	return Item.New(id,num,attr)		
end


return {
	SplitString = SplitString,
	NewRes = NewRes,
	GenItem = GenItem,
}