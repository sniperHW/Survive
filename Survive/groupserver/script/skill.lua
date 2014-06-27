local skillmgr = {
	skills,
}

function skillmgr:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.skills = {}
  return o
end

function skillmgr:init(skills)
	
end

function skillmgr:pack(wpk)

end

function skillmgr:save2db(ply)
	
end


return {
	NewSkillmgr = function () skillmgr:new() end,
}
