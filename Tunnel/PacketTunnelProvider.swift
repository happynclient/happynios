import NetworkExtension
import HappynetDylib
import os.log

func calculateSubnetAddress(ipAddress: String, subnetMask: String) -> String? {
    let ipComponents = ipAddress.split(separator: ".").compactMap { Int($0) }
    let subnetComponents = subnetMask.split(separator: ".").compactMap { Int($0) }

    guard ipComponents.count == 4, subnetComponents.count == 4 else {
        return nil
    }

    let ipInt = (ipComponents[0] << 24) + (ipComponents[1] << 16) + (ipComponents[2] << 8) + ipComponents[3]
    let subnetInt = (subnetComponents[0] << 24) + (subnetComponents[1] << 16) + (subnetComponents[2] << 8) + subnetComponents[3]


    let subnetAddressInt = ipInt & subnetInt

    let subnetAddress = "\(subnetAddressInt >> 24).\(subnetAddressInt >> 16 & 255).\(subnetAddressInt >> 8 & 255).\(subnetAddressInt & 255)"

    return subnetAddress
}


class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = OSLog(subsystem: "Happynet", category: "default")
    private var engine: PacketTunnelEngine?

    // MARK: - Override
    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log(.default, log: log, "Happynet startTunnel: engine=%{public}@",
               engine == nil ? "nil" : "set")

        // 若上一次连接的 engine 还在（异常情况），先静默 stop，不等待
        if let old = engine {
            os_log(.default, log: log, "Happynet startTunnel: stopping stale old engine")
            engine = nil
            old.stop { }   // complete() 立即触发，n2n 在 stopQueue 后台异步清理
        }

        let newEngine = PacketTunnelEngine(provider: self)
        engine = newEngine
        let config = HappynedgeConfig()

        newEngine.start(config: config) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                os_log(.default, log: self.log, "Happynet Failed to setup tunnel: %{public}@", "\(error)")
                self.setTunnelNetworkSettings(nil) { _ in
                    completionHandler(error)
                    // 必须同步退出，绝对不能用 asyncAfter！
                    // iOS 会在 completionHandler 触发后立刻挂起扩展进程。
                    // 异步定时器会被冻结，导致在"下一次"重新连接唤醒进程的瞬间引爆，炸毁新连接！
                    exit(0)
                }
                return
            }

            os_log(.default, log: self.log, "Happynet Did setup tunnel")

            let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
            let ipV4 = NEIPv4Settings(addresses: [config.ipAddress], subnetMasks: [config.subnetMask])
            if let subnetAddress = calculateSubnetAddress(ipAddress: config.ipAddress, subnetMask: config.subnetMask) {
                ipV4.includedRoutes = [NEIPv4Route(destinationAddress: subnetAddress,
                                                   subnetMask: config.subnetMask)]
            } else {
                ipV4.includedRoutes = [NEIPv4Route.default()]
            }
            settings.ipv4Settings = ipV4

            let dns = "119.29.29.29,8.8.8.8"
            let dnsSettings = NEDNSSettings(servers: dns.components(separatedBy: ","))
            dnsSettings.matchDomains = [""]
            settings.dnsSettings = dnsSettings

            self.setTunnelNetworkSettings(settings) { error in
                os_log(.default, log: self.log,
                       "Did setup tunnel settings: %{public}@, error: %{public}@",
                       "\(settings)", "\(String(describing: error))")
                completionHandler(error)
                // 只有成功时才启动读包循环
                // 失败时系统会调用 stopTunnel，不能在失败的隧道上开启无限递归
                if error == nil {
                    self.didStartTunnel()
                }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log(.fault, log: log, "Happynet stopTunnel called, engine=%{public}@",
               engine == nil ? "nil" : "set")
        
        if let current = engine {
            engine = nil
            current.stop {
                self.setTunnelNetworkSettings(nil) { _ in
                    completionHandler()
                    exit(0) // 同步销毁，杜绝 C 代码全局状态残留到下次连接
                }
            }
        } else {
            // engine 为 nil（如启动失败/未初始化/已清零），必须仍然调用 completionHandler
            // 否则系统超时后 VPN 会卡在 disconnecting 状态
            os_log(.fault, log: log, "Happynet stopTunnel: engine is nil, completing immediately")
            self.setTunnelNetworkSettings(nil) { _ in
                completionHandler()
                exit(0) // 同步销毁
            }
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
        os_log(.fault, log: log, "Happynet ****** happynedge now working*********\n")
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
        os_log(.fault, log: log, "Happynet ****** happynedge now sleep*********\n")
    }

    override func wake() {
        // Add code here to wake up.
        os_log(.fault, log: log, "Happynet ****** happynedge now wake*********\n")
    }

    // MARK: - Private
    private func didStartTunnel() {
        readPackets()
    }

    private func readPackets () {
        os_log(.fault, log: log, "Happynet start readPackets\n")
        packetFlow.readPacketObjects { [weak self] packets in
            guard let self = self else {
                return
            }
            os_log(.fault, log: self.log, "Happynet readPackets ok\n")
            if let engine = self.engine {
                for item in packets {
                    engine.onTunData(item.data)
                }
            }
            os_log(.fault, log: self.log, "Happynet get a packet\n")
            self.readPackets()
        }
    }
}
