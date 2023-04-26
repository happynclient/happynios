#include "tun2tap.h"

#include "n2n.h"
#include "libs_def.h"

#include "../../happynet/BridgeC2OC.h"

int supernode_connect(n2n_edge_t *eee);
void send_query_peer (n2n_edge_t * eee, const n2n_mac_t dst_mac);
void send_register_super (n2n_edge_t *eee);
int fetch_and_eventually_process_data (n2n_edge_t *eee, SOCKET sock,
                                       uint8_t *pktbuf, uint16_t *expected, uint16_t *position,
                                       time_t now);

/** Find the address and IP mode for the tuntap device.
 *
 *  s is one of these forms:
 *
 *  <host> := <hostname> | A.B.C.D
 *
 *  <host> | static:<host> | dhcp:<host>
 *
 *  If the mode is present (colon required) then fill ip_mode with that value
 *  otherwise do not change ip_mode. Fill ip_mode with everything after the
 *  colon if it is present; or s if colon is not present.
 *
 *  ip_add and ip_mode are NULL terminated if modified.
 *
 *  return 0 on success and -1 on error
 */
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

#if 1    // callbacks

static void on_sn_registration_updated(n2n_edge_t *eee, time_t now, const n2n_sock_t *sn) {
    notifyConnectionStatus(CONNECTED);
    update_gateway_mac(eee);
}

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

#endif

__attribute__((visibility("default"))) int start_edge_v3(CurrentSettings *settings){
    int keep_on_running = 0;
    char tuntap_dev_name[N2N_IFNAMSIZ] = "tun0";
    char ip_mode[N2N_IF_MODE_SIZE] = "static";
    char ip_addr[N2N_NETMASK_STR_SIZE] = "";
    char netmask[N2N_NETMASK_STR_SIZE] = "255.255.255.0";
    char device_mac[N2N_MACNAMSIZ] = "";
    char *encrypt_key = NULL;
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

    //g_stop_initial = 0;
    //g_status = status;
    //n2n_edge_cmd_t *cmd = &status->cmd;

    setTraceLevel(settings->level);
    FILE *fp = fopen(settings->logPath, "w+");
    if (fp == NULL) {
        traceEvent(TRACE_ERROR, "failed to open log file.");
    } else {
        setTraceFile(fp);
    }
    
    notifyConnectionStatus(CONNECTING);

    memset(&dev, 0, sizeof(dev));
    edge_init_conf_defaults(&conf);

    /* Load the configuration */
    strncpy((char *)conf.community_name, settings->community, N2N_COMMUNITY_SIZE - 1);

    if (settings->encryptKey && settings->encryptKey[0]) {
        conf.transop_id = N2N_TRANSFORM_ID_TWOFISH;
        conf.encrypt_key = strdup(settings->encryptKey);
        traceEvent(TRACE_DEBUG, "encrypt_key = '%s'\n", encrypt_key);

        switch(settings->encryptionMethod){
            case 0:
                conf.transop_id = N2N_TRANSFORM_ID_AES;
                break;
            case 1:
                conf.transop_id = N2N_TRANSFORM_ID_TWOFISH;
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
    } else {
        conf.transop_id = N2N_TRANSFORM_ID_NULL;
    }

    if(settings->ipAddress && settings->ipAddress[0])
        scan_address(ip_addr, N2N_NETMASK_STR_SIZE,
                     ip_mode, N2N_IF_MODE_SIZE,
                     settings->ipAddress);
    else
        memset(ip_mode, 0, sizeof(ip_mode));

    dev.fd = settings->vpnFd;

    conf.drop_multicast = settings->acceptMultiMacaddr == 0 ? 1 : 0;
    conf.allow_routing  = settings->forwarding == 0 ? 0 : 1;

    if(0 == strcmp("static", ip_mode))
        conf.tuntap_ip_mode = TUNTAP_IP_MODE_STATIC;
    else if(0 == strcmp("dhcp", ip_mode))
        conf.tuntap_ip_mode = TUNTAP_IP_MODE_DHCP;
    else
        conf.tuntap_ip_mode = TUNTAP_IP_MODE_SN_ASSIGN;

    if(settings->supernode == NULL)
        goto cleanup;
    
    if(strlen(settings->supernode) == 0)
        goto cleanup;
        
    if(0 == edge_conf_add_supernode(&conf, settings->supernode))
        traceEvent(TRACE_DEBUG, "Adding supernode[%u] = %s\n", (unsigned int) conf.sn_num, settings->supernode);
        
    if(settings->supernode2 && strlen(settings->supernode2))
        if(0 == edge_conf_add_supernode(&conf, settings->supernode2))
            traceEvent(TRACE_DEBUG, "Adding supernode[%u] = %s\n", (unsigned int) conf.sn_num, settings->supernode2);

    if (settings->subnetMark && settings->subnetMark[0] != '\0')
        strncpy(netmask, settings->subnetMark, N2N_NETMASK_STR_SIZE);

    if (settings->gateway && settings->gateway[0] != '\0')
        inet_aton(settings->gateway, &gateway_ip);

    if (settings->mac && settings->mac[0] != '\0')
        strncpy(device_mac, settings->mac, N2N_MACNAMSIZ);
    else {
        strncpy(device_mac, random_device_mac(), N2N_MACNAMSIZ);
        traceEvent(TRACE_DEBUG, "random device mac: %s\n", device_mac);
    }

    str2mac(hex_mac, device_mac);

    if(settings->deviceDescription && settings->deviceDescription[0]) {
        conf.dev_desc[sizeof(conf.dev_desc) - 1] = '\0';
        strncpy(conf.dev_desc, settings->deviceDescription, sizeof(conf.dev_desc) - 1);
    }

    if (edge_verify_conf(&conf) != 0) {
        if (conf.encrypt_key) free(conf.encrypt_key);
        conf.encrypt_key = NULL;
        traceEvent(TRACE_ERROR, "Bad configuration");
        rv = 1;
        goto cleanup;
    }

    /* Start n2n */
    eee = edge_init(&conf, &i);

    if (eee == NULL) {
        traceEvent(TRACE_ERROR, "Failed in edge_init");
        rv = 1;
        goto cleanup;
    }

    // 说明： 安卓版的必须保护socket，iOS版的很可能不需要。
    /* Protect the socket so that the supernode traffic won't go inside the n2n VPN */
//    if (protect_socket(edge_get_management_socket(eee)) < 0) {
//        traceEvent(TRACE_ERROR, "protect(management_socket) failed");
//        rv = 1;
//        goto cleanup;
//    }
        
    strncpy(eee->tuntap_priv_conf.tuntap_dev_name, tuntap_dev_name, N2N_IFNAMSIZ - 1);
    strncpy(eee->tuntap_priv_conf.ip_mode, ip_mode, N2N_IF_MODE_SIZE - 1);
    strncpy(eee->tuntap_priv_conf.ip_addr, ip_addr, N2N_NETMASK_STR_SIZE - 1);
    strncpy(eee->tuntap_priv_conf.netmask, netmask, N2N_NETMASK_STR_SIZE - 1);
    strncpy(eee->tuntap_priv_conf.device_mac, device_mac, N2N_MACNAMSIZ - 1);
    eee->tuntap_priv_conf.mtu = settings->mtu;
        
    if((0 == strcmp("static", eee->tuntap_priv_conf.ip_mode)) ||
            ((eee->tuntap_priv_conf.ip_mode[0] == '\0') && (eee->tuntap_priv_conf.ip_addr[0] != '\0'))) {
        traceEvent(TRACE_NORMAL, "Use manually set IP address.");
        eee->conf.tuntap_ip_mode = TUNTAP_IP_MODE_STATIC;
    } else if(0 == strcmp("dhcp", eee->tuntap_priv_conf.ip_mode)) {
        traceEvent(TRACE_NORMAL, "Obtain IP from other edge DHCP services.");
        eee->conf.tuntap_ip_mode = TUNTAP_IP_MODE_DHCP;
    } else {
        traceEvent(TRACE_NORMAL, "Automatically assign IP address by supernode.");
        eee->conf.tuntap_ip_mode = TUNTAP_IP_MODE_SN_ASSIGN;
    }

    /* Private Status */
    memset(&private_status, 0, sizeof(private_status));
    private_status.gateway_ip = gateway_ip.s_addr;
    private_status.conf = &conf;
    memcpy(private_status.tap_mac, hex_mac, 6);
    inet_aton(ip_addr, &tap_ip);
    private_status.tap_ipaddr = tap_ip.s_addr;
    edge_set_userdata(eee, &private_status);

    /* set host addr, netmask, mac addr for UIP and init arp*/
    if(0 == strcmp(ip_mode, "static"))
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
    callbacks.packet_from_peer        = on_packet_from_peer;
    callbacks.packet_from_tap         = on_packet_from_tap;
    callbacks.main_loop_period        = on_main_loop_period;
    //callbacks.sock_opened             = on_edge_sock_opened;
    edge_set_callbacks(eee, &callbacks);

    /* Hin2n : mostly transplant from origin n2n edge init sequence */
    uint8_t runlevel = 0;         /* bootstrap: runlevel */
    time_t now, last_action = 0;  /*            timeout */
    uint8_t seek_answer = 1;      /*            expecting answer from supernode */
    tuntap_dev tuntap = {0};            /* a tuntap device */
    fd_set socket_mask;           /*            for supernode answer */
    struct timeval wait_time;     /*            timeout for sn answer */
    peer_info_t *scan, *scan_tmp; /*            supernode iteration */
    uint16_t expected = sizeof(uint16_t);
    uint16_t position = 0;
    uint8_t  pktbuf[N2N_SN_PKTBUF_SIZE + sizeof(uint16_t)]; /* buffer + prepended buffer length in case of tcp */
    macstr_t mac_buf;             /*            output mac address */

    tuntap.fd = settings->vpnFd;

    // mini main loop for bootstrap, not using main loop code because some of its mechanisms do not fit in here
    // for the sake of quickly establishing connection. REVISIT when a more elegant way to re-use main loop code
    // is found

    // if more than one supernode given, find at least one who is alive to faster establish connection
    if((HASH_COUNT(eee->conf.supernodes) <= 1) || (eee->conf.connect_tcp)) {
        // skip the initial supernode ping
        traceEvent(TRACE_DEBUG, "Skip PING to supernode.");
        runlevel = 2;
    }

    eee->last_sup = 0; /* if it wasn't zero yet */
    eee->curr_sn = eee->conf.supernodes;
    supernode_connect(eee);

    while(runlevel < 5) {

        now = time(NULL);

        // we do not use switch-case because we also check for 'greater than'

        if(runlevel == 0) { /* PING to all known supernodes */
            last_action = now;
            eee->sn_pong = 0;
            // (re-)initialize the number of max concurrent pings (decreases by calling send_query_peer)
            eee->conf.number_max_sn_pings = NUMBER_SN_PINGS_INITIAL;
            send_query_peer(eee, null_mac);
            traceEvent(TRACE_NORMAL, "Send PING to supernodes.");
            runlevel++;
        }

        if(runlevel == 1) { /* PING has been sent to all known supernodes */
            if(eee->sn_pong) {
                // first answer
                eee->sn_pong = 0;
                sn_selection_sort(&(eee->conf.supernodes));
                eee->curr_sn = eee->conf.supernodes;
                supernode_connect(eee);
                traceEvent(TRACE_NORMAL, "Received first PONG from supernode [%s].", eee->curr_sn->ip_addr);
                runlevel++;
            } else if(last_action <= (now - BOOTSTRAP_TIMEOUT)) {
                // timeout
                runlevel--;
                // skip waiting for answer to direcly go to send PING again
                seek_answer = 0;
                traceEvent(TRACE_DEBUG, "PONG timeout.");
            }
        }

        // by the way, have every later PONG cause the remaining (!) list to be sorted because the entries
        // before have already been tried; as opposed to initial PONG, do not change curr_sn
        if(runlevel > 1) {
            if(eee->sn_pong) {
                eee->sn_pong = 0;
                if(eee->curr_sn->hh.next) {
                    sn_selection_sort((peer_info_t**)&(eee->curr_sn->hh.next));
                    traceEvent(TRACE_DEBUG, "Received additional PONG from supernode.");
                    // here, it is hard to detemine from which one, so no details to output
                }
            }
        }

        if(runlevel == 2) { /* send REGISTER_SUPER to get auto ip address from a supernode */
            if(eee->conf.tuntap_ip_mode == TUNTAP_IP_MODE_SN_ASSIGN) {
                last_action = now;
                eee->sn_wait = 1;
                send_register_super(eee);
                runlevel++;
                traceEvent(TRACE_NORMAL, "Send REGISTER_SUPER to supernode [%s] asking for IP address.",
                           eee->curr_sn->ip_addr);
            } else {
                runlevel += 2; /* skip waiting for TUNTAP IP address */
                traceEvent(TRACE_DEBUG, "Skip auto IP address asignment.");
            }
        }

        if(runlevel == 3) { /* REGISTER_SUPER to get auto ip address from a sn has been sent */
            if(!eee->sn_wait) { /* TUNTAP IP address received */
                runlevel++;
                traceEvent(TRACE_NORMAL, "Received REGISTER_SUPER_ACK from supernode for IP address asignment.");
                // it should be from curr_sn, but we can't determine definitely here, so no details to output
            } else if(last_action <= (now - BOOTSTRAP_TIMEOUT)) {
                // timeout, so try next supernode
                if(eee->curr_sn->hh.next)
                    eee->curr_sn = eee->curr_sn->hh.next;
                else
                    eee->curr_sn = eee->conf.supernodes;
                supernode_connect(eee);
                runlevel--;
                // skip waiting for answer to direcly go to send REGISTER_SUPER again
                seek_answer = 0;
                traceEvent(TRACE_DEBUG, "REGISTER_SUPER_ACK timeout.");
            }
        }

        if(runlevel == 4) { /* configure the TUNTAP device */
#if 1
            /* call java function to establish vpn service */
            if(tuntap.fd < 0) {
                
                tuntap.fd = setAddressFromSupernode(eee->tuntap_priv_conf.ip_addr, eee->tuntap_priv_conf.netmask);
                
                dev.fd = tuntap.fd;

                /*     这里就不要把管道描述符弄成非阻塞啦        */
//                int val = fcntl(g_status->cmd.vpn_fd, F_GETFL);
//                if (val == -1) {
//                    rv = 1;
//                    goto cleanup;
//                }
//                if ((val & O_NONBLOCK) == O_NONBLOCK) {
//                    val &= ~O_NONBLOCK;
//                    val = fcntl(g_status->cmd.vpn_fd, F_SETFL, val);
//                    if (val == -1) {
//                        rv = 1;
//                        goto cleanup;
//                    }
//                }

                /****************** INIT ARP MODULE ******************/
                {
                    int match, i;
                    int ip[4];
                    uip_ipaddr_t ipaddr;
                    struct uip_eth_addr eaddr;

                    match = sscanf(eee->tuntap_priv_conf.ip_addr, "%d.%d.%d.%d", ip, ip + 1, ip + 2, ip + 3);
                    if (match != 4) {
                        traceEvent(TRACE_ERROR, "scan ip failed, ip: %s", ip_addr);
                        rv = 1;
                        goto cleanup;
                    }
                    uip_ipaddr(ipaddr, ip[0], ip[1], ip[2], ip[3]);
                    uip_sethostaddr(ipaddr);
                        
                    match = sscanf(eee->tuntap_priv_conf.netmask, "%d.%d.%d.%d", ip, ip + 1, ip + 2, ip + 3);
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
            }
#endif
            
            if(tuntap_open(&tuntap, eee->tuntap_priv_conf.tuntap_dev_name, eee->tuntap_priv_conf.ip_mode,
                            eee->tuntap_priv_conf.ip_addr, eee->tuntap_priv_conf.netmask,
                            eee->tuntap_priv_conf.device_mac, eee->tuntap_priv_conf.mtu) < 0)
                goto cleanup;
            memcpy(&eee->device, &tuntap, sizeof(tuntap));
            traceEvent(TRACE_NORMAL, "Created local tap device IP: %s, Mask: %s, MAC: %s",
                       eee->tuntap_priv_conf.ip_addr,
                       eee->tuntap_priv_conf.netmask,
                       macaddr_str(mac_buf, eee->device.mac_addr));
            runlevel = 5;
            // no more answers required
            seek_answer = 0;
        }

        // we usually wait for some answer, there however are exceptions when going back to a previous runlevel
        if(seek_answer) {
            FD_ZERO(&socket_mask);
            FD_SET(eee->sock, &socket_mask);
            wait_time.tv_sec = BOOTSTRAP_TIMEOUT;
            wait_time.tv_usec = 0;

            if(select(eee->sock + 1, &socket_mask, NULL, NULL, &wait_time) > 0) {
                if(FD_ISSET(eee->sock, &socket_mask)) {
                    fetch_and_eventually_process_data (eee, eee->sock,
                                                        pktbuf, &expected, &position,
                                                        now);
                }
            }
        }

        seek_answer = 1;
    }
    
    // allow a higher number of pings for first regular round of ping
    // to quicker get an inital 'supernode selection criterion overview'
    eee->conf.number_max_sn_pings = NUMBER_SN_PINGS_INITIAL;
    // shape supernode list; make current one the first on the list
    HASH_ITER(hh, eee->conf.supernodes, scan, scan_tmp) {
        if(scan == eee->curr_sn)
            sn_selection_criterion_good(&(scan->selection_criterion));
        else
            sn_selection_criterion_default(&(scan->selection_criterion));
    }
    
    sn_selection_sort(&(eee->conf.supernodes));
    // do not immediately ping again, allow some time
    eee->last_sweep = now - SWEEP_TIME + 2 * BOOTSTRAP_TIMEOUT;
    eee->sn_wait = 1;
    eee->last_register_req = 0;

#ifdef HAVE_LIBCAP
    /* Before dropping the privileges, retain capabilities to regain them in future. */
    caps = cap_get_proc();

    cap_set_flag(caps, CAP_PERMITTED, num_cap, cap_values, CAP_SET);
    cap_set_flag(caps, CAP_EFFECTIVE, num_cap, cap_values, CAP_SET);

    if((cap_set_proc(caps) != 0) || (prctl(PR_SET_KEEPCAPS, 1, 0, 0, 0) != 0))
        traceEvent(TRACE_WARNING, "Unable to retain permitted capabilities [%s]\n", strerror(errno));
#else
#ifndef __APPLE__
    traceEvent(TRACE_WARNING, "n2n has not been compiled with libcap-dev. Some commands may fail.");
#endif
#endif /* HAVE_LIBCAP */

#if 1
    if((eee->tuntap_priv_conf.userid != 0) || (eee->tuntap_priv_conf.groupid != 0)) {
        traceEvent(TRACE_NORMAL, "Dropping privileges to uid=%d, gid=%d",
                    (signed int)eee->tuntap_priv_conf.userid, (signed int)eee->tuntap_priv_conf.groupid);

        /* Finished with the need for root privileges. Drop to unprivileged user. */
        if((setgid(eee->tuntap_priv_conf.groupid) != 0)
            || (setuid(eee->tuntap_priv_conf.userid) != 0)) {
            traceEvent(TRACE_ERROR, "Unable to drop privileges [%u/%s]", errno, strerror(errno));
            exit(1);
        }
    }

    if((getuid() == 0) || (getgid() == 0))
        traceEvent(TRACE_WARNING, "Running as root is discouraged, check out the -u/-g options");
#endif

    notifyConnectionStatus(CONNECTED);
    
    traceEvent(TRACE_NORMAL, "edge started");
    keep_on_running = 1;
    eee->keep_running = &keep_on_running;
    run_edge_loop(eee);
    traceEvent(TRACE_NORMAL, "edge stopped");
    
cleanup:
    if (eee) edge_term(eee);
    if (encrypt_key) free(encrypt_key);
    tuntap_close(&dev);
    edge_term_conf(&conf);

    notifyConnectionStatus(DISCONNECTED);
    return rv;
}

__attribute__((visibility("default"))) int stop_edge_v3(void){
    int fd = open_socket(0, 0 /* bind LOOPBACK*/,0 );
    if (fd < 0) {
        return -1;
    }

    struct sockaddr_in peer_addr;
    peer_addr.sin_family = PF_INET;
    peer_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    peer_addr.sin_port = htons(N2N_EDGE_MGMT_PORT);
    traceEvent(TRACE_NORMAL, "send stop command to supernode, waiting for response......");
    sendto(fd, "stop", 4, 0, (struct sockaddr *) &peer_addr, sizeof(struct sockaddr_in));
    close(fd);

    return 0;
}
