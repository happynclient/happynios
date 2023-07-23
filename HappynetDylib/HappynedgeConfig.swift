import Foundation

@objcMembers
public class HappynedgeConfig: NSObject, Codable {
    public static let group = "group.net.happyn.happynios.happynet"

    public static let hostKey = "host"
    public static let portKey = "port"
    public static let networkName = "networkName"
    public static let encryptionKey = "encryptionKey"
    public static let ipAddress = "ipAddress"
    public static let isSecure = "isSecure"

    public var superNodeAddr: String = ""
    public var superNodePort: String = ""
    public var networkName: String = ""
    public var encryptionKey: String = ""
    public var ipAddress: String = ""
    public var isSecure = true

    public override init() {
        super.init()
        load()
    }

    public init(host: String, port: String, network: String, key: String, ipAddr: String) {
        superNodeAddr = host
        superNodePort = port
        networkName = network
        encryptionKey = key
        ipAddress = ipAddr
        super.init()
    }

    public func sync() {
        if let dataStorage = UserDefaults(suiteName: HappynedgeConfig.group) {
            dataStorage.setValue(superNodeAddr, forKey: HappynedgeConfig.hostKey)
            dataStorage.setValue(superNodePort, forKey: HappynedgeConfig.portKey)
            dataStorage.setValue(networkName, forKey: HappynedgeConfig.networkName)
            dataStorage.setValue(encryptionKey, forKey: HappynedgeConfig.encryptionKey)
            dataStorage.setValue(ipAddress, forKey: HappynedgeConfig.ipAddress)
            dataStorage.setValue(isSecure, forKey: HappynedgeConfig.isSecure)
            dataStorage.synchronize()
        }
    }

    private func load() {
        if let dataStorage = UserDefaults(suiteName: HappynedgeConfig.group) {
            if let host = dataStorage.string(forKey: HappynedgeConfig.hostKey) {
                superNodeAddr = host
            }

            if let port = dataStorage.string(forKey: HappynedgeConfig.portKey) {
                superNodePort = port
            }

            if let network = dataStorage.string(forKey: HappynedgeConfig.networkName) {
                networkName = network
            }
            if let key = dataStorage.string(forKey: HappynedgeConfig.encryptionKey) {
                encryptionKey = key
            }
            if let ipAddr = dataStorage.string(forKey: HappynedgeConfig.ipAddress) {
                ipAddress = ipAddr
            }
            isSecure = dataStorage.bool(forKey: HappynedgeConfig.isSecure)
        }
    }
}
