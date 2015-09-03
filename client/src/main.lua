
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
require "table.TableNew_Achieve"
require "table.TableNewbie_Guide"
require "table.TableNewbie_Reward"
require "table.TableSingle_Copy_Balance"
require "table.Tablename"
require "table.TableShop"
require "table.TableSound"
require "table.TableSynthesis"
--require "ExtensionConstants"

require "src.common.Enum"
require "src.common.CommonFun"
require "src.MgrSkill"

math.randomseed(tostring(os.time()):reverse():sub(1, 6))  

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
    local userData = cc.UserDefault:getInstance()
    MgrSetting.bPlayMusic = userData:getBoolForKey("bPlayMusic", true)
    MgrSetting.bPlayEffect = userData:getBoolForKey("bPlayEffect", true)
    
    -- initialize director
    local director = cc.Director:getInstance()

    --turn on display FPS
    director:setDisplayStats(false)

    --set FPS. the default value is 1.0/60 if you don't call this
    director:setAnimationInterval(1.0 / 60)
    
    local glView = cc.Director:getInstance():getOpenGLView() 
    glView:setDesignResolutionSize(960, 640, cc.ResolutionPolicy.FIXED_HEIGHT)
    
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
    
    local loadImages = {}
    local tableEff = TableSpecial_Effects 
    for _, value in pairs(tableEff) do
        local path = "effect/"..value.Resource_Path..".png"
        table.insert(loadImages, path)
    end
    
    local totalCount = #loadImages
    local function onLoad()
        if #loadImages > 0 then
            local image = loadImages[1]
            table.remove(loadImages, 1)
            local cache = cc.Director:getInstance():getTextureCache()
            cache:addImageAsync(image, onLoad) 
        end
    end
    onLoad()
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
