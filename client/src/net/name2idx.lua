local t  = {
--角色属性相关
	level = 1,--角色等级
	exp = 2, --经验值
	power = 3,--力量
	endurance = 4,--耐力
	constitution = 5,--体质
	agile = 6,--敏捷
	lucky = 7,--幸运
	accurate = 8,--精准
	movement_speed = 9,-- 移动速度
	shell = 10,--贝币
	pearl = 11,--珍珠
	soul = 12,--武魂
	action_force = 13,--行动力

	attack = 21,  --攻击
	defencse = 22,--防御
	life = 23,    --当前生命
	maxlife = 24, --最大生命
	dodge = 25,--闪避
	crit = 26,--暴击
	hit = 27,--命中
	anger = 28,--怒气
	combat_power = 29,--战斗力
}

local function name2idx(name)
	return t[name]
end

local function idx2name(idx)
	for k,v in pairs(t) do
		if idx == v then
			return k
		end
	end
	return nil
end

return {
	idx = name2idx,
	name = idx2name,
}
