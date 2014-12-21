local function SysTick()
	return math.floor(os.clock()*1000)--GetSysTick()
end

return {
	SysTick = SysTick
}