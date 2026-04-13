import Foundation
import NetworkExtension
import HappynetDylib
import os.log

class PacketTunnelEngine: NSObject {
    // MARK: - Property
    private let udp: HappynedgeUDP
    private var ocEngine: EdgeEngine!
    private weak var tunnel: PacketTunnelProvider!
    private var configuration: HappynedgeConfig!
    private var superNode: NWUDPSession!
    private let log = OSLog(subsystem: "Happynet", category: "default")
    private let queue = DispatchQueue(label: "happynet.tunnel")    //serial
    // n2nQueue 设计为「类级（static）串行队列」，所有 PacketTunnelEngine 实例共用：
    // - ocEngine.stop() 通过设置 closing 标志使 n2n select() 在 ≤1s 内退出，
    //   从而释放 n2nQueue 供下一次连接使用。
    // - 全局串行保证旧 n2n 完全退出后新 n2n 才启动，消除并发冲突。
    // - udpSession(.ready) 块使用 [weak self]：
    //   若 engine 在等待期间被释放（连接已取消），block 自动 no-op，不会启动孤儿 n2n。
    private static let n2nQueue = DispatchQueue(label: "happynet.n2n.global", qos: .utility)
    // 专用 stop 队列：将 ocEngine.stop()（可能耸塞数秒）移到此队列，
    // 避免阻塞 `queue`，确保超时 WorkItem 与其他状态操作免受影响。
    // 串行确保多次 stop 调用不会并发执行 n2n stop。
    private let stopQueue = DispatchQueue(label: "happynet.engine.stop", qos: .utility)
    private var startHandler: ((Error?) -> Void)?
    private var stopHandler: (() -> Void)?
    // 用 DispatchWorkItem 替代 Timer，避免依赖 RunLoop。
    // Network Extension 的 startTunnel 不保证在有活跃 RunLoop 的线程上调用，
    // Timer.scheduledTimer 在此场景下可能永远不触发，导致系统 30s 兜底超时。
    private var timeoutWorkItem: DispatchWorkItem?
    private var observer: AnyObject?
    private var udpSessionList: [NWUDPSession]!

    // MARK: - Init and Deinit
    init(provider: PacketTunnelProvider) {
        udp = HappynedgeUDP(queue: queue, tunnel: provider)
        super.init()
        tunnel = provider
        udpSessionList = []
        ocEngine = EdgeEngine(tunnelProvider: self)
    }

    deinit {
        self.timeoutWorkItem?.cancel()
        self.timeoutWorkItem = nil
        self.superNode?.cancel()
        self.observer = nil
        os_log(.default, log: self.log, "engine deinit")
    }

    // MARK: - Public
    func start(config: HappynedgeConfig, _ completionHandler: @escaping (Error?) -> Void) {
        configuration = config
        startHandler = completionHandler
        self.startTunnel()
    }

    func stop(complete: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { complete() }
                return
            }
            self.timeoutWorkItem?.cancel()
            self.timeoutWorkItem = nil
            self.startHandler = nil
            self.superNode?.cancel()
            self.observer = nil
            // complete() 立即在主线程调用 → UI 立即响应
            let engineToStop = self.ocEngine
            DispatchQueue.main.async { complete() }

            // 关键：ocEngine.stop() 在连接异常 HOST 时可能永久挂起
            // （n2n C 线程阻塞在 recvfrom 或等待不存在服务器的 ACK）。
            // 若 stopQueue 永久阻塞，afterStop(execute:) 从不触发，
            // 下一次连接的 startNewEngine() 永远不会被调，VPN 卡死在 "connecting"。
            //
            // 用 DispatchGroup + 5s 超时解决：最多等 5s，超时后 stopQueue 正常完成，
            // afterStop 正常触发，新连接正常启动。
            // 旧 n2n 线程若超时未停止，最终随 Extension 进程终止。
            let log = self.log
            self.stopQueue.async {
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.global(qos: .utility).async {
                    engineToStop?.stop()
                    group.leave()
                }
                let result = group.wait(timeout: .now() + 5)
                if case .timedOut = result {
                    os_log(.fault, log: log,
                           "Fatal: Happynet ocEngine.stop() timed out after 5s! C thread is permanently deadlocked. Terminating extension process to unblock future connections.")
                    exit(0)
                }
                // stopQueue 块完成 → afterStop(execute:) 中排队的任务可以运行
            }
        }
    }

    /// 序列化钩子：等 stopQueue 上所有任务（包括 ocEngine.stop()）完成后再执行 execute。
    /// PacketTunnelProvider 在启动新 engine 前调用此方法，确保新旧 n2n 不并发。
    func afterStop(execute: @escaping () -> Void) {
        stopQueue.async {
            DispatchQueue.main.async { execute() }
        }
    }

    func onTunData(_ data: Data?) {
        if let data = data, !data.isEmpty {
            queue.async { [weak self] in
                if let engine = self?.ocEngine {
                    engine.onData(data, with: NetDataType.tun, ip: "", port: 0)
                }
            }
        }
    }

    // MARK: - Called By N2N
    @objc
    func writeTunData(_ data: Data?) {
        guard let data = data else {
            return
        }
        queue.async { [weak self] in
            self?.tunnel.packetFlow.writePackets([data], withProtocols: [AF_INET as NSNumber])
        }
    }

    @objc
    func reportEdgeStatus(_ status: Int32) {
        os_log(.default, log: self.log, "engine reportEdgeStatus: %d", status)
        if status == 1 { // EDGE_STAT_CONNECTED
            queue.async { [weak self] in
                guard let self = self else { return }
                if let handler = self.startHandler {
                    os_log(.default, log: self.log, "engine n2n connected, calling startHandler")
                    self.timeoutWorkItem?.cancel()
                    self.timeoutWorkItem = nil
                    self.startHandler = nil
                    handler(nil)
                }
            }
        } else if status == 4 { // EDGE_STAT_FAILED
            queue.async { [weak self] in
                guard let self = self else { return }
                if let handler = self.startHandler {
                    os_log(.default, log: self.log, "engine n2n failed, calling startHandler with error")
                    self.timeoutWorkItem?.cancel()
                    self.timeoutWorkItem = nil
                    self.startHandler = nil
                    handler(NEVPNError(.connectionFailed))
                }
            }
        }
    }

    @objc
    func sendUdp(data: Data?, hostname: String, port: String) -> Bool {
        guard let data = data else {
            return false
        }
        if hostname == configuration?.superNodeAddr && port == configuration?.superNodePort {
            superNode.writeDatagram(data) { [weak self] error in
                if let error = error {
                    //os_log(.default, log: self?.log ?? .default, "Failed to write udp datagram, error: %{public}@", "\(error)")
                    NSLog("Failed to write udp datagram, error: %@", "\(error)")
                }
            }
        } else {
            udp.sendData(data: data, hostname: hostname, port: port) { [weak self] datagrams, _ in
                guard let self = self else { return }
                os_log(.default, log: self.log, "udp recv data")
                self.queue.async {
                    if let engine = self.ocEngine, let list = datagrams {
                        for item in list {
                            engine.onData(item, with: NetDataType.udp, ip: hostname, port: Int(port) ?? 0)
                        }
                    }
                }
            }
            return true
        }

        return true
    }

    // MARK: - Private
    private func startTunnel() {
        os_log(.default, log: self.log, "engine startTunnel")
        self.startUDPSession()
        scheduleTimeout()
    }

    private func scheduleTimeout() {
        // 使用 DispatchWorkItem + queue.asyncAfter 替代 Timer.scheduledTimer：
        // - 不依赖 RunLoop，Network Extension 进程不保证调用线程有活跃 RunLoop
        // - 在同一 serial queue 执行，与 reportEdgeStatus / stop 天然序列化，线程安全
        // - cancel() 可在 stop() 或 reportEdgeStatus 中安全取消
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let handler = self.startHandler else { return }
            os_log(.default, log: self.log, "engine startTunnel timeout after 10s, forcing disconnect")
            self.timeoutWorkItem = nil
            self.startHandler = nil
            handler(NEVPNError(.connectionFailed))
        }
        self.timeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 10, execute: workItem)
    }

    private func startUDPSession() {
        os_log(.default, log: log, "engine Starting UDP session")
        //let endpoint = NWHostEndpoint(hostname: "151.11.50.180", port: "7777")
        let endpoint = NWHostEndpoint(hostname: configuration.superNodeAddr, port: configuration.superNodePort)
        self.superNode = tunnel.createUDPSession(to: endpoint, from: nil)
        self.observer = superNode.observe(\.state, options: [.new]) { [weak self] session, _ in
            guard let self = self else { return }
            os_log(.default, log: self.log, "engine Session did update state: %{public}@", session)
            self.queue.async {
                self.udpSession(session, didUpdateState: session.state,
                                ipAddr: self.configuration.superNodeAddr,
                                port: Int(self.configuration.superNodePort) ?? 0)
            }
        }
    }

    private func edgeConfig() -> EdgeConfig {
        let config = EdgeConfig()
        config.superNodeAddr = configuration.superNodeAddr
        config.superNodePort = UInt(configuration.superNodePort) ?? 0
        config.networkName = configuration.networkName
        config.encryptionKey = configuration.encryptionKey
        config.ipAddress = configuration.ipAddress
        
        config.subnetMask = configuration.subnetMask
        config.deviceDescription = configuration.deviceDescription
        config.gateway = configuration.gateway
        config.dns = configuration.dns
        config.mac = configuration.mac
        config.mtu = UInt(configuration.mtu)
        config.encryptionMethod = UInt(configuration.encryptionMethod)
        config.localPort = UInt(configuration.localPort)
        config.forwarding = UInt(configuration.forwarding)
        config.isAcceptMulticast = UInt(configuration.isAcceptMulticast)
        config.loglevel = UInt(configuration.loglevel)

        return config
    }

    private func udpSession(_ session: NWUDPSession, didUpdateState state: NWUDPSessionState, ipAddr: String, port: Int) {
        switch state {
        case .ready:
            guard startHandler != nil else { return }
            session.setReadHandler({ [weak self] datagrams, _ in
                guard let self = self else { return }
                self.queue.async {
                    if let engine = self.ocEngine, let list = datagrams {
                        for item in list {
                            engine.onData(item, with: NetDataType.udp, ip: ipAddr, port: port)
                        }
                    }
                }
            }, maxDatagrams: Int.max)
            // self.timeoutTimer?.invalidate() // Don't invalidate yet, wait for n2n connection
            // startHandler?(nil) // Don't call yet, wait for n2n connection
            // startHandler = nil
            PacketTunnelEngine.n2nQueue.async { [weak self] in
                guard let self = self else { return }
                self.ocEngine.start(self.edgeConfig())
            }
        case .failed:
            guard startHandler != nil else { return }
            // 取消超时 WorkItem，避免 .failed 处理后超时再次计入
            timeoutWorkItem?.cancel()
            timeoutWorkItem = nil
            startHandler?(NEVPNError(.connectionFailed))
            startHandler = nil
        default:
            break
        }
    }
}
