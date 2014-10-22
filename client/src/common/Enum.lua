local function ENUM_FUN(cmdBegin)
    local cmd = cmdBegin
    return function() 
        cmd = cmd + 1 
        return cmd 
    end
end

function GetEnumName(t, idx)
    for k,v in pairs(t) do
        if idx == v then
            return k
        end
    end
    return nil
end

local ENUM = ENUM_FUN(0)
EnumAvatar = EnumAvatar or {
    ["Tag3D"]       = ENUM(),
    ["Tag2D"]       = ENUM(),
}

ENUM = ENUM_FUN(0)
EnumActions = EnumActions or {
    ["Idle"]        = ENUM(),
    ["Walk"]        = ENUM(),
    ["Hit"]         = ENUM(),
    ["Death"]       = ENUM(),
    ["Attack1"]     = ENUM(),
    ["Attack2"]     = ENUM(),
    ["Attack3"]     = ENUM(),
    ["Skill1"]      = ENUM(),
    ["Skill2"]      = ENUM(),
    ["Skill3"]      = ENUM(),
    ["Skill4"]      = ENUM(),
    ["Skill5"]      = ENUM(),
}

ENUM = ENUM_FUN(0)
EnumActionTag = EnumActionTag or {
    ["Idle"]        = ENUM(),
    ["Walk"]        = ENUM(),
    ["Hit"]         = ENUM(),
    ["ActionMove"]  = ENUM(),       --位移action,非动作
    ["Attack3D"]    = ENUM(),       --3D专用，攻击动作不混合
    ["State2D"]     = ENUM(),       --2D专用，动作不混合
}

return nil