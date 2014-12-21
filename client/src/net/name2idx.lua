local num = 0

local function NextNum()
	num = num + 1
	return num
end

local nameidx  = {
--角色属性相关
	level = NextNum(),--角色等级
	exp = NextNum(), --经验值
	power = NextNum(),--力量
	endurance = NextNum(),--耐力
	constitution = NextNum(),--体质
	agile = NextNum(),--敏捷
	lucky = NextNum(),--幸运
	accurate = NextNum(),--精准
	movement_speed = NextNum(),-- 移动速度
	shell = NextNum(),--贝币
	pearl = NextNum(),--珍珠
	soul =   NextNum(),--武魂
	action_force = NextNum(),--行动力
	potential_point = NextNum(),
	fishing_start =  NextNum(),
	gather_start =  NextNum(),
	sit_start = NextNum(),

	attack = NextNum(),  --攻击
	defencse = NextNum(),--防御
	life = NextNum(),    --当前生命
	maxlife = NextNum(), --最大生命
	dodge = NextNum(),--闪避
	crit = NextNum(),--暴击
	hit = NextNum(),--命中
	anger = NextNum(),--怒气
	combat_power = NextNum(),--战斗力
	suffer_plusrate = NextNum(),	
}

local idxname = {}

for k,v in pairs(nameidx) do
	idxname[v] = k
end

local function name2idx(name)
	return nameidx[name]
end

local function idx2name(idx)
	return idxname[idx]
end

return {
	idx = name2idx,
	name = idx2name,
}
