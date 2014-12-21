TableBuff = TableBuff or { 
[3001] = { ["Period1"] = 5000, ["Period2"] = 0, ["Interval"] = 0, ["ClientInterval"] = 500, ["Range"] = 20, ["AtkSkill"] = 1040, ["ActionName"] = [[Skill3]], ["Effects_ID"] = 40},
[3002] = { ["Period1"] = 5000, ["Period2"] = 0, ["Interval"] = 0, ["Range"] = 0, ["ActionName"] = [[Skill4]], ["Effects_ID"] = 90},
[3101] = { ["Period1"] = 3000, ["Range"] = 0, ["ActionName"] = [[Vertigo]], ["Effects_ID"] = 60},
[3201] = { ["Period1"] = 6000, ["Period2"] = 0, ["Interval"] = 0, ["Range"] = 0, ["OnBegin "] = [[return function (buff)
 local avatar = buff.owner
 local skill = avatar.skillmgr:GetSkill(1150)
 if skill then
  avatar.attr:Set("suffer_plusrate",1.5)
 end
end
]], ["OnEnd"] = [[return function (buff)
 local avatar = buff.owner
 avatar.attr:Set("suffer_plusrate",1)
end]], ["Effects_ID"] = 120},
[3300] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 120, ["Reply"] = 30},
[3301] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 248, ["Reply"] = 62},
[3302] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 392, ["Reply"] = 98},
[3303] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 636, ["Reply"] = 159},
[3304] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 1004, ["Reply"] = 251},
[3305] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 1344, ["Reply"] = 336},
[3306] = { ["Period1"] = 5000, ["Range"] = 0, ["Begin_Reply"] = 1720, ["Reply"] = 430},
[3321] = { ["Period1"] = 5000, ["Range"] = 0, ["Move_Speed"] = 10},
[3322] = { ["Period1"] = 5000, ["Move_Speed"] = 20},
[3323] = { ["Period1"] = 5000, ["Range"] = 0, ["Move_Speed"] = -5},
[3324] = { ["Period1"] = 5000, ["Move_Speed"] = -10}
}