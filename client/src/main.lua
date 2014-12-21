
cc.FileUtils:getInstance():addSearchPath("src")
cc.FileUtils:getInstance():addSearchPath("res")
--cc.FileUtils:getInstance():addSearchPath("lua")

-- CC_USE_DEPRECATED_API = true
require "cocos.init"

require "src.net.ParseSC"
require "src/net/Client2Server"
require "src.MgrPlayer"
require "src.MgrFight"
require "src.Avatar"
require "math"
require "src.table.TableModel"
require "src.table.TableAvatar"
require "src.table.TableAction"
require "src.table.TableSkill"
require "src.table.TableItem"
require "src.table.TableMap"
require "src.table.TableSpecial_Effects"
require "src.table.TableBuff"
require "src.table.TableItem"
require "src.table.TableExperience"
require "src.table.TableStone"
require "src.table.TableIntensify"
require "src.table.TableEquipment"
require "src.table.TableRising_Star" 
require "table.Tableskill_Upgrade"
require "table.TableSkill_Addition"
require "table.TableFish"
require "table.TableGather"
require "table.TablePractice"
require "table.TableStone_Synthesis"
require "table.TableSign"
require "table.TableDay_Task"
--require "ExtensionConstants"
require "src.common.Enum"
require "src.common.CommonFun"
require "src.MgrSkill"

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

DesignSize = {width = 960, height = 640}
BeginTime = {localtime = os.clock(), servertime = 0} 
local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    MgrSetting.bPlayMusic = cc.UserDefault:getInstance():getBoolForKey("bPlayMusic", true)
    MgrSetting.bPlayEffect = cc.UserDefault:getInstance():getBoolForKey("bPlayEffect", true)
    
    -- initialize director
    local director = cc.Director:getInstance()

    --turn on display FPS
    director:setDisplayStats(true)

    --set FPS. the default value is 1.0/60 if you don't call this
    director:setAnimationInterval(1.0 / 60)
    
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(960, 640, cc.ResolutionPolicy.FIXED_HEIGHT)
    
    --create scene 
    Lang = require "LangCh"
    local scene = require("SceneLogin")
    --local scene = require("SceneGarden")
    --local scene = require("TestScene")
    local gameScene = scene.create()
    
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(gameScene)
    else
        cc.Director:getInstance():runWithScene(gameScene)
    end
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
