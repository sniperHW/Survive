TableBuff = TableBuff or { 
[3001] = { ["Period1"] = 5000, ["Period2"] = 0, ["Interval"] = 0, ["ClientInterval"] = 500, ["Range"] = 20, ["AtkSkill"] = 1040, ["ActionName"] = [[Skill3]], ["Effects_ID"] = 40, ["Sound"] = 13},
[3002] = { ["Period1"] = 5000, ["Period2"] = 0, ["Interval"] = 0, ["Range"] = 0, ["OnBegin"] = [[Buff3002_OnBegin]], ["OnEnd"] = [[Buff3002_OnEnd]], ["ActionName"] = [[Skill4]], ["Effects_ID"] = 90, ["Sound"] = 14},
[3101] = { ["Period1"] = 3000, ["Range"] = 0, ["OnBegin"] = [[Blackout_OnBegin]], ["OnEnd"] = [[Blackout_OnEnd]], ["ActionName"] = [[Vertigo]], ["Effects_ID"] = 60},
[3201] = { ["Period1"] = 10000, ["Period2"] = 0, ["Interval"] = 0, ["Range"] = 0, ["OnBegin"] = [[Buff3201_OnBegin]], ["OnEnd"] = [[Buff3201_OnEnd]], ["ActionName"] = [[Skill5]], ["Effects_ID"] = 120, ["Sound"] = 20},
[3300] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 120, ["Reply"] = 30},
[3301] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 248, ["Reply"] = 62},
[3302] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 392, ["Reply"] = 98},
[3303] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 636, ["Reply"] = 159},
[3304] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 1004, ["Reply"] = 251},
[3305] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 1344, ["Reply"] = 336},
[3306] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnInterval"] = [[LifeRecover_onInterval]], ["Range"] = 0, ["OnBegin"] = [[LifeRecover_OnBegin]], ["Begin_Reply"] = 1720, ["Reply"] = 430},
[3321] = { ["Period1"] = 5000, ["Interval"] = 1000, ["Range"] = 0, ["OnBegin"] = [[SpeedChange_OnBegin]], ["OnEnd"] = [[SpeedChange_OnEnd]], ["Move_Speed"] = 10},
[3322] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnBegin"] = [[SpeedChange_OnBegin]], ["OnEnd"] = [[SpeedChange_OnEnd]], ["Move_Speed"] = 20},
[3323] = { ["Period1"] = 5000, ["Interval"] = 1000, ["Range"] = 0, ["OnBegin"] = [[SpeedChange_OnBegin]], ["OnEnd"] = [[SpeedChange_OnEnd]], ["Move_Speed"] = -5},
[3324] = { ["Period1"] = 5000, ["Interval"] = 1000, ["OnBegin"] = [[SpeedChange_OnBegin]], ["OnEnd"] = [[SpeedChange_OnEnd]], ["Move_Speed"] = -10}
}