local skillmgr = {
	skills,
}

local function skillmgr:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.skills = {}
  return o
end

local function skillmgr:init(skills)
	
end

local function skillmgr:pack(wpk)

end

local function skillmgr::save2db(ply)
	
end


return {
	NewSkillmgr = function () skillmgr:new() end,
}
