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
            self?.refresh()
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
        loadTunnelManager { [unowned self] manager, error in
            if let error = error {
                return completion(error)
            }

            if manager == nil {
                self.tunnel = self.makeTunnelManager(with: config)
            }

            if self.tunnel?.isEnabled == false {
                self.tunnel?.isEnabled = true
            }

            self.saveToPreferences(with: config) { [weak self] error in
                if let error = error {
                    return completion(error)
                }

                self?.tunnel?.loadFromPreferences { [weak self] _ in
                    self?.start(completion)
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
        tunnel?.connection.stopVPNTunnel()
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
        NETunnelProviderManager.loadAllFromPreferences { [unowned self] managers, error in
            self.tunnel = managers?.first
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
