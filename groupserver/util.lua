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
	if initidx ~= string.len(s) then
		table.insert(ret,string. sub(s,initidx))
	end
	return ret
end

return {
	SplitString = SplitString
}