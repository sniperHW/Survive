轻量级手游服务器框架Survive
======

Survive是一个在distri.lua之上构建的手机网游服务器,除了几个基本模块外全部使用lua编写.


获取 Survive
-----------

Clone [dirsti.lua](https://github.com/sniperHW/distri.lua).

cd distri.lua/deps

Clone [KendyNet](https://github.com/sniperHW/KendyNet).

cd ..

Clone [Survive](https://github.com/sniperHW/survive.lua).


构建
------
```
make distrilua

cd Survive

make all

```

运行服务

1)启动redis服务器

2)按实际需要调整setconfig.lua中的ip地址和端口号

3)运行./distrilua Survive/setconfig.lua

4)启动游戏服务器

./distrilua Survive/groupserver/groupserver.lua

./distrilua Survive/gameserver/gameserver.lua

./distrilua Survive/gateserver/gateserver.lua


5)启动启动客户端

首先调整中的ip和端口号 client/src/UI/UILogin.lua

然后执行client/runtime/win32/battle.exe

6)启动机器人

./distrilua Survive/robotclient.lua

```

