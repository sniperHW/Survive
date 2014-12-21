package.cpath = "SurviveServer/?.so"
local Astar = require "astar"


local ret = Astar.lineto(nil,0,0,5,5)
for k,v in pairs(ret) do
	print(v[1],v[2])
end