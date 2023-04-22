#include "tun2tap.h"

#include "n2n.h"
#include "libs_def.h"

#include "../../happynet/BridgeC2OC.h"

static int scan_address(char *ip_addr, size_t addr_size,
                        char *ip_mode, size_t mode_size,
                        const char *s) {
    int retval = -1;
    char *p;

    if ((NULL == s) || (NULL == ip_addr)) {
        return -1;
    }

    memset(ip_addr, 0, addr_size);

    p = strpbrk(s, ":");

    if (p) {
        /* colon is present */
        if (ip_mode) {
            size_t end = 0;

            memset(ip_mode, 0, mode_size);
            end = MIN(p - s, (ssize_t) (mode_size - 1)); /* ensure NULL term */
            strncpy(ip_mode, s, end);
            strncpy(ip_addr, p + 1, addr_size - 1); /* ensure NULL term */
            retval = 0;
        }
    } else {
        /* colon is not present */
        strncpy(ip_addr, s, addr_size);
    }

    return retval;
}

static const char *random_device_mac(void) {
    const char key[] = "0123456789abcdef";
    static char mac[18];
    int i;

    srand(getpid());
    for (i = 0; i < sizeof(mac) - 1; ++i) {
        if ((i + 1) % 3 == 0) {
            mac[i] = ':';
            continue;
        }
        mac[i] = key[random() % strlen(key)];
    }
    mac[sizeof(mac) - 1] = '\0';
    return mac;
}

static n2n_mac_t broadcast_mac = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
static n2n_mac_t null_mac = {0, 0, 0, 0, 0, 0};

static char arp_packet[] = {
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, /* Dest mac */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* Src mac */
        0x08, 0x06, /* ARP */
        0x00, 0x01, /* Ethernet */
        0x08, 0x00, /* IP */
        0x06, /* Hw Size */
        0x04, /* Protocol Size */
        0x00, 0x01, /* ARP Request */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* Src mac */
        0x00, 0x00, 0x00, 0x00, /* Src IP */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* Target mac */
        0x00, 0x00, 0x00, 0x00 /* Target IP */
};

/* ************************************** */

static int build_unicast_arp(char *buffer, size_t buffer_len,
                             uint32_t target, n2n_android_t *priv) {
    if (buffer_len < sizeof(arp_packet)) return (-1);

    memcpy(buffer, arp_packet, sizeof(arp_packet));
    memcpy(&buffer[6], priv->tap_mac, 6);
    memcpy(&buffer[22], priv->tap_mac, 6);
    memcpy(&buffer[28], &priv->tap_ipaddr, 4);
    memcpy(&buffer[32], broadcast_mac, 6);
    memcpy(&buffer[38], &target, 4);
    return (sizeof(arp_packet));
}

static void update_gateway_mac(n2n_edge_t *eee) {
    n2n_android_t *priv = (n2n_android_t *) edge_get_userdata(eee);

    if (priv->gateway_ip != 0) {
        size_t len;
        char buffer[48];

        len = build_unicast_arp(buffer, sizeof(buffer), priv->gateway_ip, priv);
        traceEvent(TRACE_DEBUG, "Updating gateway mac");
        edge_send_packet2net(eee, (uint8_t *) buffer, len);
    }
}

static void on_sn_registration_updated(n2n_edge_t *eee, time_t now, const n2n_sock_t *sn) {
    notifyConnectionStatus(CONNECTED);
    update_gateway_mac(eee);
}

/* *************************************************** */

static n2n_verdict on_packet_from_peer(n2n_edge_t *eee, const n2n_sock_t *peer,
                                       uint8_t *payload, uint16_t *payload_size) {
    n2n_android_t *priv = (n2n_android_t *) edge_get_userdata(eee);

    if ((*payload_size >= 36) &&
        (ntohs(*((uint16_t *) &payload[12])) == 0x0806) && /* ARP */
        (ntohs(*((uint16_t *) &payload[20])) == 0x0002) && /* REPLY */
        (!memcmp(&payload[28], &priv->gateway_ip, 4))) { /* From gateway */
        memcpy(priv->gateway_mac, &payload[22], 6);

        traceEvent(TRACE_INFO, "Gateway MAC: %02X:%02X:%02X:%02X:%02X:%02X",
                   priv->gateway_mac[0], priv->gateway_mac[1], priv->gateway_mac[2],
                   priv->gateway_mac[3], priv->gateway_mac[4], priv->gateway_mac[5]);
    }

    uip_buf = payload;
    uip_len = *payload_size;
    if (IPBUF->ethhdr.type == htons(UIP_ETHTYPE_ARP)) {
        uip_arp_arpin();
        if (uip_len > 0) {
            traceEvent(TRACE_DEBUG, "ARP reply packet prepare to send");
            edge_send_packet2net(eee, uip_buf, uip_len);
            return N2N_DROP;
        }
    }

    return (N2N_ACCEPT);
}

/* *************************************************** */

static n2n_verdict on_packet_from_tap(n2n_edge_t *eee, uint8_t *payload,
                                      uint16_t *payload_size) {
    n2n_android_t *priv = (n2n_android_t *) edge_get_userdata(eee);

    /* Fill destination mac address first or generate arp request packet instead of
     * normal packet. */
    uip_buf = payload;
    uip_len = *payload_size;
    uip_arp_out();
    if (IPBUF->ethhdr.type == htons(UIP_ETHTYPE_ARP)) {
        *payload_size = uip_len;
        traceEvent(TRACE_DEBUG, "ARP request packets are sent instead of packets");
    }

    /* A NULL MAC as destination means that the packet is directed to the
     * default gateway. */
    if ((*payload_size > 6) && (!memcmp(payload, null_mac, 6))) {
        traceEvent(TRACE_DEBUG, "Detected packet for the gateway");

        /* Overwrite the destination MAC with the actual gateway mac address */
        memcpy(payload, priv->gateway_mac, 6);
    }

    return (N2N_ACCEPT);
}

void on_main_loop_period(n2n_edge_t *eee, time_t now) {
    n2n_android_t *priv = (n2n_android_t *) edge_get_userdata(eee);

    /* call arp timer periodically  */
    if ((now - priv->lastArpPeriod) > ARP_PERIOD_INTERVAL) {
        uip_arp_timer();
        priv->lastArpPeriod = now;
    }
}

__attribute__((visibility("default"))) int start_edge_v2(CurrentSettings *settings){
    
    int keep_on_running = 0;
    char tuntap_dev_name[N2N_IFNAMSIZ] = "tun0";
    char ip_mode[N2N_IF_MODE_SIZE] = "static";
    char ip_addr[N2N_NETMASK_STR_SIZE] = "";
    char netmask[N2N_NETMASK_STR_SIZE] = "255.255.255.0";
    char device_mac[N2N_MACNAMSIZ] = "";
    struct in_addr gateway_ip = {0};
    struct in_addr tap_ip = {0};
    n2n_edge_conf_t conf;
    n2n_edge_t *eee = NULL;
    n2n_edge_callbacks_t callbacks;
    n2n_android_t private_status;
    int i;
    tuntap_dev dev;
    uint8_t hex_mac[6];
    int rv = 0;

    if (!settings) {
        traceEvent(TRACE_ERROR, "Empty cmd struct");
        return 1;
    }

    setTraceLevel(settings->level);
    FILE *fp = fopen(settings->logPath, "w+");
    if (fp == NULL) {
        traceEvent(TRACE_ERROR, "failed to open log file.");
    } else {
        setTraceFile(fp);
    }

    if (settings->vpnFd < 0) {
        traceEvent(TRACE_ERROR, "VPN socket is invalid.");
        return 1;
    }

    //notifyConnectionStatus(CONNECTING);
    
    memset(&dev, 0, sizeof(dev));
    edge_init_conf_defaults(&conf);

    /* Load the configuration */
    strncpy((char *) conf.community_name, settings->community, N2N_COMMUNITY_SIZE - 1);

    if (settings->encryptKey && settings->encryptKey[0]) {
        conf.transop_id = N2N_TRANSFORM_ID_TWOFISH;
        conf.encrypt_key = strdup(settings->encryptKey);
        traceEvent(TRACE_DEBUG, "encrypt_key = '%s'\n", conf.encrypt_key);
        
        switch(settings->encryptionMethod){
            case 0:
                conf.transop_id = N2N_TRANSFORM_ID_TWOFISH;
                break;
            case 1:
                conf.transop_id = N2N_TRANSFORM_ID_AESCBC;
                break;
            case 2:
                conf.transop_id = N2N_TRANSFORM_ID_SPECK;
                break;
            case 3:
                conf.transop_id = N2N_TRANSFORM_ID_CHACHA20;
                break;
            default:
                conf.transop_id = N2N_TRANSFORM_ID_NULL;
                break;
        }
    } else
        conf.transop_id = N2N_TRANSFORM_ID_NULL;

    scan_address(ip_addr, N2N_NETMASK_STR_SIZE,
                 ip_mode, N2N_IF_MODE_SIZE,
                 settings->ipAddress);

    dev.fd = settings->vpnFd;

    conf.drop_multicast = settings->acceptMultiMacaddr == 0 ? 1 : 0;
    conf.allow_routing = settings->forwarding == 0 ? 0 : 1;
    conf.dyn_ip_mode = (strcmp("dhcp", ip_mode) == 0) ? 1 : 0;
    
    if (settings->supernode && settings->supernode[0]) {
        strncpy(conf.sn_ip_array[conf.sn_num], settings->supernode, N2N_EDGE_SN_HOST_SIZE);
        traceEvent(TRACE_DEBUG, "Adding supernode[%u] = %s\n", (unsigned int) conf.sn_num,
                   (conf.sn_ip_array[conf.sn_num]));
        ++conf.sn_num;
    }
    if (settings->supernode2 && settings->supernode2[0]) {
        strncpy(conf.sn_ip_array[conf.sn_num], settings->supernode2, N2N_EDGE_SN_HOST_SIZE);
        traceEvent(TRACE_DEBUG, "Adding supernode[%u] = %s\n", (unsigned int) conf.sn_num,
                   (conf.sn_ip_array[conf.sn_num]));
        ++conf.sn_num;
    }

    if (settings->subnetMark  && settings->subnetMark[0] != '\0')
        strncpy(netmask, settings->subnetMark, N2N_NETMASK_STR_SIZE);

    if (settings->gateway && settings->gateway[0])
        inet_aton(settings->gateway, &gateway_ip);

    if (settings->mac && settings->mac[0])
        strncpy(device_mac, settings->mac, N2N_MACNAMSIZ);
    else {
        strncpy(device_mac, random_device_mac(), N2N_MACNAMSIZ);
        traceEvent(TRACE_DEBUG, "random device mac: %s\n", device_mac);
    }

    str2mac(hex_mac, device_mac);

    if (edge_verify_conf(&conf) != 0) {
        if (conf.encrypt_key) free(conf.encrypt_key);
        conf.encrypt_key = NULL;
        traceEvent(TRACE_ERROR, "Bad configuration");
        rv = 1;
        goto cleanup;
    }

    /* Open the TAP device */
    if (tuntap_open(&dev, tuntap_dev_name, ip_mode, ip_addr, netmask, device_mac, settings->mtu) < 0) {
        traceEvent(TRACE_ERROR, "Failed in tuntap_open");
        rv = 1;
        goto cleanup;
    }

    /* Start n2n */
    eee = edge_init(&dev, &conf, &i);

    if (eee == NULL) {
        traceEvent(TRACE_ERROR, "Failed in edge_init");
        rv = 1;
        goto cleanup;
    }

#if 0  // Android版的需要保护socket，我们可能不需要。
    /* Protect the socket so that the supernode traffic won't go inside the n2n VPN */
    if (protect_socket(edge_get_n2n_socket(eee)) < 0) {
        traceEvent(TRACE_ERROR, "protect(n2n_socket) failed");
        rv = 1;
        goto cleanup;
    }

    if (protect_socket(edge_get_management_socket(eee)) < 0) {
        traceEvent(TRACE_ERROR, "protect(management_socket) failed");
        rv = 1;
        goto cleanup;
    }
#endif
    
    /* Private Status */
    memset(&private_status, 0, sizeof(private_status));
    private_status.gateway_ip = gateway_ip.s_addr;
    private_status.conf = &conf;
    memcpy(private_status.tap_mac, hex_mac, 6);
    inet_aton(ip_addr, &tap_ip);
    private_status.tap_ipaddr = tap_ip.s_addr;
    edge_set_userdata(eee, &private_status);

    /* set host addr, netmask, mac addr for UIP and init arp*/
    {
        int match, i;
        int ip[4];
        uip_ipaddr_t ipaddr;
        struct uip_eth_addr eaddr;

        match = sscanf(ip_addr, "%d.%d.%d.%d", ip, ip + 1, ip + 2, ip + 3);
        if (match != 4) {
            traceEvent(TRACE_ERROR, "scan ip failed, ip: %s", ip_addr);
            rv = 1;
            goto cleanup;
        }
        uip_ipaddr(ipaddr, ip[0], ip[1], ip[2], ip[3]);
        uip_sethostaddr(ipaddr);
        match = sscanf(netmask, "%d.%d.%d.%d", ip, ip + 1, ip + 2, ip + 3);
        if (match != 4) {
            traceEvent(TRACE_ERROR, "scan netmask error, ip: %s", netmask);
            rv = 1;
            goto cleanup;
        }
        uip_ipaddr(ipaddr, ip[0], ip[1], ip[2], ip[3]);
        uip_setnetmask(ipaddr);
        for (i = 0; i < 6; ++i)
            eaddr.addr[i] = hex_mac[i];
        uip_setethaddr(eaddr);

        uip_arp_init();
    }

    /* Set up the callbacks */
    memset(&callbacks, 0, sizeof(callbacks));
    callbacks.sn_registration_updated = on_sn_registration_updated;
    callbacks.packet_from_peer = on_packet_from_peer;
    callbacks.packet_from_tap = on_packet_from_tap;
    callbacks.main_loop_period = on_main_loop_period;
    edge_set_callbacks(eee, &callbacks);

    keep_on_running = 1;
    
    notifyConnectionStatus(CONNECTING);

    traceEvent(TRACE_NORMAL, "edge started");

    run_edge_loop(eee, &keep_on_running);

    traceEvent(TRACE_NORMAL, "edge stopped");

    cleanup:
    if (eee) edge_term(eee);
    tuntap_close(&dev);
    edge_term_conf(&conf);

    return rv;
}

__attribute__((visibility("default"))) int stop_edge_v2(void){
    int fd = open_socket(0, 0 /* bind LOOPBACK*/ );
    if (fd < 0) {
        return 1;
    }

    struct sockaddr_in peer_addr;
    peer_addr.sin_family = PF_INET;
    peer_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    peer_addr.sin_port = htons(N2N_EDGE_MGMT_PORT);
    sendto(fd, "stop", 4, 0, (struct sockaddr *) &peer_addr, sizeof(struct sockaddr_in));
    close(fd);
    
    notifyConnectionStatus(DISCONNECTED);
    return 0;
}
