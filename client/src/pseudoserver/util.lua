local gridpixel = 8

local function Pixel2Grid(pixel)
	return math.floor(pixel/gridpixel)
end

local function Grid2Pixel(grid)
	return grid*gridpixel
end

local function Distance(pos1,pos2)
	return math.sqrt(math.pow(pos1[1] - pos2[1] , 2) + math.pow(pos1[2] - pos2[2] , 2))
end

local function TooLong(pos1,pos2,dis)
	return Distance(pos1,pos2) > Pixel2Grid(dis)
end

local function TooClose(pos1,pos2,dis)
	return Distance(pos1,pos2) <= Pixel2Grid(dis)
end

local function CheckOverLap(avatar,pos)
	local viewObjs = avatar:GetViewObj()
	for k,v in pairs(viewObjs) do
		if avatar~= v and TooClose(v.pos,pos,80) then
			return true
		end
	end
	return false
end

local function Rotate(r,radians)
	local x = r*math.sin(radians)  
	local y = r*math.cos(radians)
	return x,y
end

local function convertDir(dir)
	local angle = dir - 90
	if angle < 0 then
		angle = 360 + angle
	end	
	return math.fmod((360 - angle),360)
end

local function DirTo(map,pos,r,dir)
	dir = convertDir(dir)
	local x,y = Rotate(Pixel2Grid(r),math.rad(dir))
	pos = LineTo(pos[1],pos[2],math.floor(x+pos[1]),math.floor(pos[2]-y))
	if pos then
		pos = pos[#pos]
		return pos
	else
		return nil
	end	
end

local function Dir(point1,point2)
	local y = point2[2] - point1[2]
	local x = point2[1] - point1[1]
	local angle = math.floor(math.deg(math.atan2 (y, x)))
	if angle < 0 then
		angle = 360 + angle
	end
	return math.fmod((360 - angle),360)
end

local function ForwardTo(map,from,to,range)
	range = Pixel2Grid(range)
	local distance = math.sqrt(math.pow(from[1] - to[1] , 2) + math.pow(from[2] - to[2] , 2))
	--print("distance",distance)
	if distance == 0 then
		return nil
	end
	local fraction = range/distance
	--print("ForwardTo",distance,fraction,range)
	local deltax = math.floor((to[1] - from[1]) * fraction)
	local deltay = math.floor((to[2] - from[2]) * fraction)
	local pos = {[1] = from[1] + deltax,[2] = from[2] + deltay}
	--print("ForwardTo1",pos[1],pos[2])	
	pos = LineTo(from[1],from[2],pos[1],pos[2])
	if pos then
		pos = pos[#pos]
		--print("ForwardTo2",pos[1],pos[2])
		return pos
	else
		return nil
	end
end

return {
	Pixel2Grid = Pixel2Grid,
	TooLong = TooLong,
	TooClose = TooClose,
	CheckOverLap = CheckOverLap,
	ForwardTo = ForwardTo,
	Distance = Distance,
	DirTo = DirTo,
	Grid2Pixel = Grid2Pixel,
	Dir = Dir,
}