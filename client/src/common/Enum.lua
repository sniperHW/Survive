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
    ["Repel"]       = ENUM(),
    ["Vertigo"]     = ENUM(),
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
    ["Death"]       = ENUM(),
    ["Repel"]       = ENUM(),
    ["Vertigo"]     = ENUM(),
    ["ActionMove"]  = ENUM(),       --位移action,非动作
    ["Attack3D"]    = ENUM(),       --3D专用，攻击动作不混合
    ["State2D"]     = ENUM(),       --2D专用，动作不混合
}

ENUM = ENUM_FUN(0)
EnumChildTag = EnumChildTag or {
    ["Weapon"]      = ENUM(),
}

ENUM = ENUM_FUN(0)
EnumHintType = EnumHintType or {
    bag             = ENUM(),
    body            = ENUM(),
    other           = ENUM(),
    
}

ENUM = ENUM_FUN(0)
EnumPopupType = EnumPopupType or {
    cancelGarden    = ENUM(),
}

WeaponNodeName = "Bone020"

QualityColor = {
    {r = 0, g = 0, b = 0},
    {r = 0, g = 153, b = 68},
    {r = 0, g = 104, b = 183},
    {r = 96, g = 25, b = 134},
    {r = 235, g = 97, b = 0},
}

QualityIconPath = {
    "UI/common/pz0.png",
    "UI/common/pz1.png",
    "UI/common/pz2.png",
    "UI/common/pz3.png",
    "UI/common/pz4.png",
}

ColorBlack = {r = 0, g = 0, b = 0}

BASE_SKILLID = 11

return nil