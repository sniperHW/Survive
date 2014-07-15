local mapdef = {
		[1] = {
			gridlength = 4,          --管理格大小
			toleft = {0,0},           --左上角坐标
			bottomright = {29,29},  --右下角坐标
			radius = 8,              --视距大小
 			coli   = "./map1.coli",   --寻路碰撞文件
 			astar  = nil,
		},
	}


local function init()
	for k,v in ipairs(mapdef) do
		v.astar = GameApp.create_astar(v.coli,v.bottomright[1] - v.toleft[1] + 1,
									   v.bottomright[2] - v.toleft[2] + 1)
	end
end

init()

local function getDefByType(type)
	return mapdef[type]
end

return {
	GetDefByType = getDefByType,
}
