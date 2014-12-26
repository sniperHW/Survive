local Name2idx = require "Survive.common.name2idx"
local Bag = require "Survive.groupserver.bag"
require "Survive.common.TableItem"
require "Survive.common.TableEquipment"

local gm_command={
	setattr = function (ply,param)
		if param[1] == "exp" then
			local exp = tonumber(param[2])
			ply:AddExp(exp)
			ply.attr:Update2Client()
			ply.attr:DbSave()			
		else
			local attr = param[1]
			if attr == "shell" or attr == "soul" or attr == "pearl" or attr == "potential_point" then
				local val = tonumber(param[2])
				ply.attr:Set(attr,val)
				ply.attr:Update2Client()
				ply.attr:DbSave()
			end
		end
	end,
	newres = function (ply,param)
		local id = tonumber(param[1])
		if not id then return end
		local itemtb = TableItem[id]
		print("newres",id,itemtb)
		if not itemtb then return end
		local count
		local attr
		if itemtb["Item_Type"] >= 5 then
			count = tonumber(param[2]) or 1
		else
			count = 1
			attr = {0,0,0,0,0,0,0,0,0,0}
		end
		if ply.bag:AddItem(id,count,attr) then
			ply.bag:NotifyUpdate()
			ply.bag:Save()
		end
	end,
	clearsign = function(ply,param)
		if param[1] and type(param[1]) ~= "number" then
			return
		end
		local clearcount = tonumber(param[1])		
		ply.sign.lastreset = 0
		ply.sign.count =  clearcount or ply.sign.count
		ply.sign:Update2Client()
		ply.sign:DbSave()
	end,
	cleartask = function(ply,param)
		if #param == 0 or type(param[1]) ~= "number" then
			return
		end
		local task = tonumber(param[1])
		if ply.Task.tasks[task] then
			ply.Task.tasks[task].count = 0
			ply.Task.tasks[task].awarded = false
			ply.Task:DbSave()
		end
	end
}

local function Command(ply,command)
	print("Command")
	local param = {}
	for w in string.gmatch(command, "%w+") do
		table.insert(param,w)
		print(w)
	end
	print(#param)
	if #param > 1 then
		local cmd = param[1]
		table.remove(param,1)
		if gm_command[cmd] then
			gm_command[cmd](ply,param)
		end
	end
end

return {
	Command = Command
}

