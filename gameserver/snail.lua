
local maxx = 4
local maxy = 3
local final = maxx * maxy

local dir = {
	up = function (x,y)
		y = y - 1
		if y < 1 then
			return nil
		end
		return x,y
	end, 
	down = function (x,y)
		y = y + 1
		if y > maxy then
			return nil
		end
		return x,y
	end, 
	left  = function (x,y)
		x = x - 1
		if x < 1 then
			return nil
		end
		return x,y
	end,
	right = function (x,y)
		x = x + 1
		if x > maxx then
			return nil
		end
		return x,y
	end
}

local function cloneMatrix(matrix)
	local clone = {{},{},{}}
	for i = 1,maxy do
		for j=1,maxx do
			clone[i][j] = matrix[i][j]
		end
	end
	return clone
end

local totalcount = 0


local function isVaild(matrix,x,y)
	if not matrix[y][x] then
		return true
	end
	return false
end


local base = {
	{},
	{},
	{}
}

local count = 0
for i = 1,maxy do
	for j=1,maxx do
		count = count + 1
		base[i][j] = count
	end
end

local output = {}


local function search(matrix,num)
	for i = 1,maxy do
		for j=1,maxx do
			if matrix[i][j] == num then
				return base[i][j]
			end
		end
	end	
	return nil
end

local function snail(matrix,c,x,y)
	if isVaild(matrix,x,y) then
		c = c + 1
		matrix[y][x] = c
		if c == final then
			local tmp = {}	
			for i = 1,final do
				table.insert(tmp,search(matrix,i))
			end
			table.insert(output,tmp)
			--totalcount = totalcount + 1
			--print(matrix[1][1],matrix[1][2],matrix[1][3],matrix[1][4])
			--print(matrix[2][1],matrix[2][2],matrix[2][3],matrix[2][4])
			--print(matrix[3][1],matrix[3][2],matrix[3][3],matrix[3][4])
			--print("---------------------------------------------------------")
			return
		end
		for k,v in pairs(dir) do
			local nextx,nexty = v(x,y)
			if nextx and nexty then
				snail(cloneMatrix(matrix),c,nextx,nexty)
			end
		end	
	end 
end


for i = 1,maxy do
	for j=1,maxx do
		snail({{},{},{}},0,j,i)
	end
end

--snail({{},{},{}},0,1,2)

--for k,v in pairs(output) do
--	print(v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12])
--end
return output




