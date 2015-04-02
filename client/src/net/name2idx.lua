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
	potential_point = NextNum(), --可供使用的潜能点
	fishing_start =  NextNum(), --钓鱼开始时间
	gather_start =  NextNum(), --采集开始时间
	sit_start = NextNum(), --打坐开始时间
	spve_last_award = NextNum(), --上次领取奖励的关卡号
	spve_history_max = NextNum(), --历史最大关卡记录
	spve_today_max = NextNum(), --尚未提交的关卡记录
	introduce_step = NextNum(), --新手引导步骤
	online_award = NextNum(),
	stamina = NextNum(),
	attack = NextNum(),  --攻击
	defencse = NextNum(),--防御
	life = NextNum(),    --当前生命
	maxlife = NextNum(), --最大生命
	dodge = NextNum(),--闪避
	crit = NextNum(),--暴击
	hit = NextNum(),--命中
	anger = NextNum(),--怒气
	combat_power = NextNum(),--战斗力
	suffer_plusrate = NextNum(), --伤害加成倍率
	endidx = NextNum()
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
	Idx = name2idx,
	name = idx2name,
}
