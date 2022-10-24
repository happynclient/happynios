# hin2n-ios
This is a tiny iOS implementation of n2n.

1. It works as a n2n edge to connect to supernode. It works on iOS device which need NOT be jailbreaked.
2. It supports all versions of n2n(v1/v2/v2s/v3).
3. Since Apple reject all GPL-only applications, we CANNOT publish it in Apple APP Store. You MUST clone source code and compile by yourself.
4. To compile and run this APP, you MUST have an Apple developer account and have the Network-Extension entitlement.

some problems which are already known:

0. It does NOT support the iOS emulator in xcode.
1. If you switch to another app and switch back, the connection status may be temporarily abnormal.
2. If you select the other VPN in system configuration, then click connect button in app, it will fail and network service will be abnormal after you click disconnect button.
3. missing legality checking of some parameters.
4. missing night theme adaption.


Any suggestion will be appreciated!


# hin2n-ios 说明
此为n2n的一个iOS简易实现。

1. 它实现了在iOS设备（无需越狱）下作为edge工作，能够连接到supernode以实现NAT穿透。
2. 支持全部n2n协议(v1/v2/v2s/v3)
3. 由于苹果不支持仅以GPL协议发行的APP，我们无法在苹果商店上架。您必须自己下载代码并编译安装。
4. 如果要编译，您必须拥有一个苹果开发者账号且确保申请了Network-Extension的权限。

部分已知问题：

0. 不支持使用Xcode中的模拟器运行这个程序。
1. 切出再切入APP，则连接状态会短暂地显示不正常。
2. 如果用户选择了其他非hin2n的VPN，则点击连接按钮时会连接失败；再断开之后，就无法上网了。
3. 未对部分参数做合法性判断
4. 未适配深色主题

欢迎提出您的宝贵意见！
