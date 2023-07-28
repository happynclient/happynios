# happynios

![image](https://github.com/happynclient/happynios/assets/86546534/df4c3a97-f235-4baa-a79e-cf055c847ce6)


Apple Store:

https://apps.apple.com/us/app/happynet/id6448507986

Forked from [hin2n-ios](https://github.com/Oliver0624/hin2n-ios)

This is a tiny iOS implementation of n2n.

1. It works as a n2n edge to connect to supernode. It works on iOS device which need NOT be jailbreaked.
2. It supports  n2n v3
3. To compile and run this APP, you MUST have an Apple developer account and have the Network-Extension entitlement.

some problems which are already known:

0. It does NOT support the iOS emulator in xcode.
1. If you switch to another app and switch back, the connection status may be temporarily abnormal.
2. If you select the other VPN in system configuration, then click connect button in app, it will fail and network service will be abnormal after you click disconnect button.
3. missing legality checking of some parameters.

# HowTo

1. Click the "+" button in the top right corner to create a configuration.
2. add  params:
   - Setting Name: Configuration Name
   - supernode: sueprnode address, such as "server.happyn.net:7654"
   - community: the community id
   - Encryption: Encryption Key (the Default Encryption Method is AES, you can set it in `more settings`)
   - ip address: your edge ip address, such as 10.0.0.1
   - subnetmask: such as 255.255.255.0
   - device name: default is happynios
3. Save the configuration, go back to the previous level interface, click on the `>` icon on the interface, and select service configuration.
4. return to the main View, client `Start` Button

# happynios 说明

此项目同步于[hin2n-ios](https://github.com/Oliver0624/hin2n-ios)

此为n2n的一个iOS简易实现。希望能在原项目基础上，开发一个兼容N2N v3以及happyn.net服务的APP，同时上架Apple Store;

1. 它实现了在iOS设备（无需越狱）下作为edge工作，能够连接到supernode以实现NAT穿透。
2. 支持n2n V3协议
3. 如果要编译，您必须拥有一个苹果开发者账号且确保申请了Network-Extension的权限。

部分已知问题：

0. 不支持使用Xcode中的模拟器运行这个程序。
1. 切出再切入APP，则连接状态会短暂地显示不正常。
2. 如果用户选择了其他非happyn的VPN，则点击连接按钮时会连接失败；再断开之后，就无法上网了。
3. 未对部分参数做合法性判断


# RoadMap

- [x] 用基本配置连接成功N2N V3 Supernode
- [x] 重构代码，界面上只支持N2N V3
- [x] 加入 hin2n-ios的原始项目链接，致谢
- [x] 同步happyn的N2N V3上游代码
- [x] 加入happyn icon
- [x] 上架Apple Store
