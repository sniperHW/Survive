#简介
Survive是使用distri.lua框架实现的一个小型手游服务端示例.除了aoi和astar两个模块以外,所有游戏逻辑皆使用lua编写.

Survive是一个副本玩法的ARPG游戏,目前支持的功能如下:

* 帐号验证,角色创建
* 角色背包,装备穿戴,装备升级,装备升星,装备镶嵌
* 技能学习,升级
* 每日签到,每日任务
* 每日挂机活动
* 单人PVE副本
* 5人PVE副本
* 5V5战场副本

Survive的逻辑服务采用单进程单线程的方式,目前Survive的服务包括:

* gateserver:负责保持与客户端的网络连接,将客户端请求转发到内部服务和把来自内部服务的消息转发给客户端
* groupserver:负责帐号验证,角色创建,角色数据的保存,基本游戏逻辑以及副本的管理
* gameserver:服务服务,运行具体的副本实例,实现战斗及AI处理

    
#运行Survive服务

首先在你的机器上安装[ssdb](https://github.com/ideawu/ssdb/)或[redis](http://www.redis.io/)

启动ssdb/redis

修改gateserver的对外服务ip/端口,打开`setconfig.lua`,将`["gate1"] = {"192.168.0.87",8010}`改成你希望的ip和端口.

在distri.lua目录执行以下命令:

	./distrilua setconfig.lua
    
之后根据使用命令行还是使用管理工具分成两种不同的启动方式

##命令行启动

执行如下命令:

	./distrilua groupserver/groupserver.lua 
	
    ./distrilua gameserver/gameserver.lua
    
    ./distrilua gateserver/gateserver.lua
    
完成后游戏服务便启动完成,可以跳到客户端的启动章节


##通过管理工具启动

Survive提供了一套基于web的管理工具,在配置之前请确保你的机器上已经安装了php和apache.除此之外,还要安装php的redis客户端库[phpredis](https://github.com/phpredis/phpredis).

上面的所有要求都满足之后,打开daemon.lua文件.

1) 将serverip修改为你期望的值

2) 修改groupname="group1"中所有项的ip为你的期望值

3) 修改StartProcess中的路径

4) 执行:

	./distrilua daemon.lua -d
    
这行命令会在你的机器上启动一个daemon进程用于启动/关闭和监控服务

5)在浏览器中输入ip/manage.php,如果看到下图表明php服务及daemon启动成功

![Alt text](img/web1.png)

6)选择你刚才所配置的ip,点击启动,如果看到下图表明游戏服务启动完成

![Alt text](img/web2.png)

#启动游戏客户端

打开`Survive/client/src/UI/UILogin.lua`

将

        local function btnHandle(sender, event)
            print("pre connect")
            --Connect("192.168.0.87", 8010)
            Connect("121.41.37.227", 8010)
            --cc.Director:getInstance():replaceScene(require("SceneLoading.lua").create())
        end

中`Connect`的参数改为你gateserver的ip和端口号

之后通过`Survive/client/runtime/win32/battle.exe`启动游戏客户端.

![Alt text](img/survive1.jpg)

用户名可随便输入,忽略密码直接点击进入游戏,如果一切正常你将会看到如下的创角界面:

![Alt text](img/survive2.jpg)

#游戏图片展示

1)主界面

![Alt text](img/survive3.jpg)

2)背包界面

![Alt text](img/survive4.jpg)

![Alt text](img/survive7.jpg)

3)每日任务

![Alt text](img/survive5.jpg)

4)角色属性

![Alt text](img/survive6.jpg)

5)装备强化

![Alt text](img/survive8.jpg)

![Alt text](img/survive9.jpg)

6)每日签到

![Alt text](img/survive10.jpg)

7)挂机任务

![Alt text](img/survive11.jpg)

8)单人副本

![Alt text](img/survive12.jpg)

9)5人PVE副本

![Alt text](img/survive13.jpg)

![Alt text](img/survive14.jpg)

10)5V5PVP战场副本

![Alt text](img/survive15.jpg)

![Alt text](img/survive16.jpg)

11)多机器人副本压测

![Alt text](img/survive17.jpg)

#问题反馈

如有任何问题请通过huangweilook@21cn.com向我反馈,Enjoy!
