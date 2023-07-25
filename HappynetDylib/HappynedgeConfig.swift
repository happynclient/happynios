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
    
    public static let subnetMaskKey = "subnetMask"
    public static let deviceDescriptionKey = "deviceDescription"
    public static let gatewayKey = "gateway"
    public static let dnsKey = "dns"
    public static let macKey = "mac"
    public static let mtuKey = "mtu"
    public static let encryptionMethodKey = "encryptionMethod"
    public static let localPortKey = "localPort"
    public static let forwardingKey = "forwarding"
    public static let isAcceptMulticastKey = "isAcceptMulticast"
    public static let loglevelKey = "loglevel"

    public var superNodeAddr: String = ""
    public var superNodePort: String = ""
    public var networkName: String = ""
    public var encryptionKey: String = ""
    public var ipAddress: String = ""
    public var isSecure = true
    
    public var subnetMask: String = ""
    public var deviceDescription: String = ""
    public var gateway: String = ""
    public var dns: String = ""
    public var mac: String = ""
    public var mtu: Int = 0
    public var encryptionMethod: Int = 0
    public var localPort: Int = 0
    public var forwarding: Int = 0
    public var isAcceptMulticast: Int = 0
    public var loglevel: Int = 0

    public override init() {
        super.init()
        load()
    }

    public init(host: String, port: String, network: String, key: String, ipAddr: String,
                isubnetMask: String, ideviceDescription: String, igateway: String, idns: String, imac: String, imtu: Int,
                iencryptionMethod: Int,  ilocalPort: Int, iforwarding: Int, iisAcceptMulticast: Int, iloglevel: Int) {
        superNodeAddr = host
        superNodePort = port
        networkName = network
        encryptionKey = key
        ipAddress = ipAddr
        
        subnetMask = isubnetMask
        deviceDescription = ideviceDescription
        gateway = igateway
        dns = idns
        mac = imac
        mtu = imtu
        encryptionMethod = iencryptionMethod
        localPort = ilocalPort
        forwarding = iforwarding
        isAcceptMulticast = iisAcceptMulticast
        loglevel = iloglevel
        
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
            
            dataStorage.setValue(subnetMask, forKey: HappynedgeConfig.subnetMaskKey)
            dataStorage.setValue(deviceDescription, forKey: HappynedgeConfig.deviceDescriptionKey)
            dataStorage.setValue(gateway, forKey: HappynedgeConfig.gatewayKey)
            dataStorage.setValue(dns, forKey: HappynedgeConfig.dnsKey)
            dataStorage.setValue(mac, forKey: HappynedgeConfig.macKey)
            dataStorage.setValue(mtu, forKey: HappynedgeConfig.mtuKey)
            dataStorage.setValue(encryptionMethod, forKey: HappynedgeConfig.encryptionMethodKey)
            dataStorage.setValue(localPort, forKey: HappynedgeConfig.localPortKey)
            dataStorage.setValue(forwarding, forKey: HappynedgeConfig.forwardingKey)
            dataStorage.setValue(isAcceptMulticast, forKey: HappynedgeConfig.isAcceptMulticastKey)
            dataStorage.setValue(loglevel, forKey: HappynedgeConfig.loglevelKey)
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
            
            if let isubnetMask = dataStorage.string(forKey: HappynedgeConfig.subnetMaskKey) {
                subnetMask = isubnetMask
            }
            if let ideviceDescription = dataStorage.string(forKey: HappynedgeConfig.deviceDescriptionKey) {
                deviceDescription = ideviceDescription
            }
            if let igateway = dataStorage.string(forKey: HappynedgeConfig.gatewayKey) {
                gateway = igateway
            }
            if let idns = dataStorage.string(forKey: HappynedgeConfig.dnsKey) {
                dns = idns
            }

            mtu = dataStorage.integer(forKey: HappynedgeConfig.mtuKey)
            encryptionMethod = dataStorage.integer(forKey: HappynedgeConfig.encryptionMethodKey)
            localPort = dataStorage.integer(forKey: HappynedgeConfig.localPortKey)
            forwarding = dataStorage.integer(forKey: HappynedgeConfig.forwardingKey)
            isAcceptMulticast = dataStorage.integer(forKey: HappynedgeConfig.isAcceptMulticastKey)
            loglevel = dataStorage.integer(forKey: HappynedgeConfig.loglevelKey)
        }
    }
}
