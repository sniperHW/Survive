require "Cocos2d"
require "extern"
require "src.net.NetCmd"
require "src.net.ParseSC"
require "src/net/Client2Server"
require "src.MgrPlayer"
require "src/MgrFight"
require "src.Avatar"
require "math"
require "src.table.Model"
require "src.table.Action"
require "Cocos2dConstants"
require "ExtensionConstants"

DesignSize = {width = 960, height = 640}

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    cc.FileUtils:getInstance():addSearchPath("src")
    cc.FileUtils:getInstance():addSearchPath("res")
    cc.Director:getInstance():getOpenGLView():
        setDesignResolutionSize(DesignSize.width, DesignSize.height, cc.ResolutionPolicy.FIXED_HEIGHT)

    Lang = require "LangCh"
    local scene = require("SceneLogin")
    --local scene = require("SceneLoading")
    --local scene = require("TestScene")
    local loginScene = scene.create()   
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(loginScene)
    else
        cc.Director:getInstance():runWithScene(loginScene)
    end
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
