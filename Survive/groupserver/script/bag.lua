local bag = {
	bag,
}

function bag:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.bag = {}
  return o
end

function bag:init(bag)
	
end

function bag:pack(wpk)

end

function bag:save2db(ply)
	
end

return {
	NewBag = function () bag:new() end,
}
