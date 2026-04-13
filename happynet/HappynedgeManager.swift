//
//  HappynedgeManager.swift
//  HappynetDylib
//
//  Created by mac on 2023/7/18.
//

import Foundation
import NetworkExtension
import HappynetDylib


@objcMembers
public class HappynedgeManager: NSObject {
    public typealias Handler = (Error?) -> Void

    // MARK: - Property
    public static let shared = HappynedgeManager()

    // MARK: - Public
    public var statusDidChangeHandler: ((String) -> Void)?

    public private(set) var tunnel: NETunnelProviderManager?
    public var isOn: Bool { status == .online }
    public private(set) var status: Status = .offline {
        didSet { notifyStatusDidChange() }
    }

    private var observers = [AnyObject]()
    private var isStarting = false
    private var pendingStartCompletion: Handler?

    private override init() {
        super.init()
        refresh()
        let statusChange = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange,
                                                                  object: nil,
                                                                  queue: OperationQueue.main) { [weak self] _ in
            self?.updateStatus()
        }
        observers.append(statusChange)

        let configChange = NotificationCenter.default.addObserver(forName: .NEVPNConfigurationChange, object: nil,
                                                                  queue: OperationQueue.main) { [weak self] _ in
            guard let self = self, !self.isStarting else { return }
            self.refresh()
        }
        observers.append(configChange)
    }
}

// MARK: - Status

extension HappynedgeManager {
    @objc
    public enum Status: Int {
        case online
        case offline
        case invalid /// The VPN is not configured
        case connecting
        case disconnecting

        public var text: String {
            switch self {
            case .online:
                return "On"
            case .connecting:
                return "Connecting..."
            case .disconnecting:
                return "Disconnecting..."
            case .offline, .invalid:
                return "Off"
            }
        }

        public init(_ status: NEVPNStatus) {
            switch status {
            case .connected:
                self = .online
            case .connecting, .reasserting:
                self = .connecting
            case .disconnecting:
                self = .disconnecting
            case .disconnected, .invalid:
                self = .offline
            @unknown default:
                self = .offline
            }
        }
    }
}

// MARK: - Public Methods

extension HappynedgeManager {
    @objc(startWithConfig:completion:)
    public func start(with config: HappynedgeConfig,
                      completion: @escaping Handler) {
        // 取消上一次未完成的 start
        pendingStartCompletion = nil
        pendingStartCompletion = completion
        isStarting = true

        loadTunnelManager { [weak self] manager, error in
            guard let self = self else { return }
            // 如果 stop() 已经被调用（isStarting 被重置），放弃本次 start
            guard self.isStarting else {
                self.pendingStartCompletion = nil
                return
            }

            if let error = error {
                self.isStarting = false
                let cb = self.pendingStartCompletion
                self.pendingStartCompletion = nil
                cb?(error)
                return
            }

            if manager == nil {
                self.tunnel = self.makeTunnelManager(with: config)
            }

            if self.tunnel?.isEnabled == false {
                self.tunnel?.isEnabled = true
            }

            self.saveToPreferences(with: config) { [weak self] error in
                guard let self = self else { return }
                guard self.isStarting else {
                    self.pendingStartCompletion = nil
                    return
                }

                if let error = error {
                    self.isStarting = false
                    let cb = self.pendingStartCompletion
                    self.pendingStartCompletion = nil
                    cb?(error)
                    return
                }

                // Reload tunnel manager from system preferences to get the
                // canonical instance after first-time save, preventing the
                // race condition where NEVPNConfigurationChange notification
                // could replace self.tunnel with a different instance.
                self.loadTunnelManager { [weak self] _, _ in
                    guard let self = self, self.isStarting else {
                        self?.pendingStartCompletion = nil
                        return
                    }
                    // tunnel 为 nil 意味着 loadAllFromPreferences 返回空数组
                    // 发生于 saveToPreferences 后立即 load 但配置未写入的情况
                    // 快速失败而非静默中断链条（否则 isStarting 永远不清零，UI 卡死）
                    guard self.tunnel != nil else {
                        self.isStarting = false
                        let cb = self.pendingStartCompletion
                        self.pendingStartCompletion = nil
                        cb?(NSError(domain: NEVPNErrorDomain,
                                    code: NEVPNError.Code.configurationInvalid.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to load VPN configuration after saving"]))
                        return
                    }
                    self.tunnel?.loadFromPreferences { [weak self] _ in
                        guard let self = self, self.isStarting else {
                            self?.pendingStartCompletion = nil
                            return
                        }
                        self.isStarting = false
                        let cb = self.pendingStartCompletion
                        self.pendingStartCompletion = nil
                        self.start { error in cb?(error) }
                    }
                }
            }
        }
    }

    public func start(_ completion: @escaping Handler) {
        do {
            try tunnel?.connection.startVPNTunnel()
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func stop() {
        // 中断任何正在进行的异步 start 链，防止 start/stop 状态交叉
        isStarting = false
        pendingStartCompletion = nil
        if let tunnel = self.tunnel {
            tunnel.connection.stopVPNTunnel()
        } else {
            // tunnel 为 nil（可能在 start 链中途被清空），尝试从系统首选项重新加载后再停止
            // 这确保 stop() 总是有效，即使 tunnel 引用丢失
            NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
                if let manager = managers?.first {
                    self?.tunnel = manager
                    manager.connection.stopVPNTunnel()
                }
            }
        }
    }

    public func refresh(completion: Handler? = nil) {
        loadTunnelManager { [weak self] _, error in
            self?.updateStatus()
            completion?(error)
        }
    }

    public func setEnabled(_ isEnabled: Bool, completion: @escaping Handler) {
        guard isEnabled != tunnel?.isEnabled else { return }
        tunnel?.isEnabled = isEnabled
        saveToPreferences(completion: completion)
    }

    public func saveToPreferences(with config: HappynedgeConfig? = nil,
                                  completion: @escaping Handler) {
        if let config = config {
            config.sync()
            tunnel?.config(with: config)
        }
        tunnel?.saveToPreferences { error in
            completion(error)
        }
    }

    public func removeFromPreferences(completion: @escaping Handler) {
        tunnel?.removeFromPreferences { [weak self] error in
            if error != nil {
                self?.tunnel = nil
            }
            completion(error)
        }
    }
}

// MARK: - Private Methods

extension HappynedgeManager {
    private func loadTunnelManager(_ complition: @escaping (NETunnelProviderManager?, Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.tunnel = managers?.first
            complition(managers?.first, error)
        }
    }

    private func makeTunnelManager(with config: HappynedgeConfig) -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        // WARNING: This must match the bundle identifier of the app extension
        // containing packet tunnel provider.
        proto.providerBundleIdentifier = "net.happyn.happynios.happynet.tunnel"
        proto.serverAddress = "\(config.superNodeAddr):\(config.superNodePort)"
        proto.providerConfiguration = [:]
        manager.protocolConfiguration = proto
        manager.localizedDescription = "happynet"
        manager.isEnabled = true

        return manager
    }

    private func updateStatus() {
        if let tunnel = tunnel {
            status = Status(tunnel.connection.status)
        } else {
            status = .offline
        }
        switch status {
            case .online:
                notifyConnectionStatus(CONNECTED);
            case .connecting:
                notifyConnectionStatus(CONNECTING);
            case .disconnecting:
                notifyConnectionStatus(SUPERNODE_DISCONNECT);
            case .offline, .invalid:
                notifyConnectionStatus(DISCONNECTED);
            @unknown default:
                notifyConnectionStatus(DISCONNECTED);
        }
        
        print("====> status: \(status.text)")
    }

    private func notifyStatusDidChange() {
        statusDidChangeHandler?(status.text)
    }
}

public extension NETunnelProviderManager {
    // Objective-C compatible method
    @objc(configWithHappynedgeConfig:)
    func config(with config: HappynedgeConfig) {
        if let proto = protocolConfiguration as? NETunnelProviderProtocol {
            // Update the configuration here
            // For example:
            proto.serverAddress = "\(config.superNodeAddr):\(config.superNodePort)"
            protocolConfiguration = proto
        }
    }
}
