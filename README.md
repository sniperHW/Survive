轻量级手游服务器框架Survive
======

Survive是一个在distri.lua之上构建的手机网游服务器,除了几个基本模块外全部使用lua编写.


获取 Survive
-----------
Install redis.

Clone [the repository](https://github.com/sniperHW/distri.lua).

cd distri.lua

Clone [Survive](https://github.com/sniperHW/survive.lua).

cd deps

Clone [the repository](https://github.com/sniperHW/KendyNet).


构建
------
```
make distrilua

cd Survive

make all

```

运行服务
-------------
```
首先根据实际情况调整ip和端口号,相关文件为:gateserver.lua gameserver.lua groupserver.lua robotclient.lua client/src/UI/UILogin.lua

启动redis服务器

启动游戏服务器

./distrilua Survive/groupserver/groupserver.lua

./distrilua Survive/gameserver/gameserver.lua

./distrilua Survive/gateserver/gateserver.lua

启动机器人客户端

./distrilua Survive/robotclient.lua

```

