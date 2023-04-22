#include "n2n.h"
#include "tun2tap.h"
#include "PacketDataManager.h"

int tuntap_open (tuntap_dev *device /* ignored */,
                 char *dev,
#ifndef N2N_V1
                 const char *address_mode, /* static or dhcp */
#endif
                 char *device_ip,
                 char *device_mask,
                 const char * device_mac,
                 int mtu) {
    int i, n_matched;
    unsigned int mac[6];

    n_matched = sscanf(device_mac, "%x:%x:%x:%x:%x:%x", mac, mac + 1, mac + 2, mac + 3, mac + 4, mac + 5);
    if (n_matched != 6) {
        return -1;
    }
    memset(device->mac_addr, 0, sizeof(device->mac_addr));
    for (i = 0; i < 6; i++)
        device->mac_addr[i] = mac[i];
    device->ip_addr = inet_addr(device_ip);
    device->device_mask = inet_addr(device_mask);
    device->mtu = mtu;
#ifndef N2N_V1
    strncpy(device->dev_name, dev, N2N_IFNAMSIZ);
#endif
    return device->fd;
}

int tuntap_read (struct tuntap_dev *tuntap, unsigned char *buf, int len) {
#if 1
    unsigned short pktHead = 0;
    int readLen = 0;
    while(sizeof(pktHead) == (readLen = read(tuntap->fd, &pktHead, sizeof(pktHead))) && pktHead != 0x1234) ;
    if (readLen < sizeof(pktHead))
        return -1;
    
    unsigned short pktLen = 0;
    if (sizeof(pktLen) != read(tuntap->fd, &pktLen, sizeof(pktLen)))
        return -1;
    
    len = pktLen + UIP_LLH_LEN;
#endif
#if !defined(N2N_V1) && !defined(N2N_V2S)   // v2 or v3
    memset(buf, 0, UIP_LLH_LEN);
    int rlen = read(tuntap->fd, buf + UIP_LLH_LEN, len - UIP_LLH_LEN);
    if (rlen < 0) {
        traceEvent(TRACE_WARNING, "read pipe data error.\n");
        return rlen;
    }
    return rlen + UIP_LLH_LEN;
#else
    int rlen = read(tuntap->fd, buf + UIP_LLH_LEN, len - UIP_LLH_LEN);
    if ((rlen <= 0) || (rlen > 2048 - UIP_LLH_LEN)) {
        return rlen;
    }
    
    uip_buf = buf;
    uip_len = rlen;
    uip_arp_out();
    if (IPBUF->ethhdr.type == htons(UIP_ETHTYPE_ARP)) {
        traceEvent(TRACE_INFO, "ARP request packets are sent instead of packets");
    }
    return uip_len;
#endif
}

int tuntap_write (struct tuntap_dev *tuntap, unsigned char *buf, int len) {
    uip_buf = buf;
    uip_len = len;
    if (IPBUF->ethhdr.type == htons(UIP_ETHTYPE_IP)) {
        int rlen = writeDataToTunnel(buf + UIP_LLH_LEN, len - UIP_LLH_LEN);
        if (rlen < 0) {
            return rlen;
        }
        return rlen + UIP_LLH_LEN;
    }
#if defined(N2N_V1) || defined(N2N_V2S)
    else if (IPBUF->ethhdr.type == htons(UIP_ETHTYPE_ARP)) {
        uip_arp_arpin();
        if (uip_len > 0) {
            uip_arp_len = uip_len;
            memcpy(uip_arp_buf, uip_buf, uip_arp_len);
            traceEvent(TRACE_INFO, "ARP reply packet prepare to send");
        }
        return len;
    }
    errno = EINVAL;
    return -1;
#else
    return 0;
#endif
}

void tuntap_close (struct tuntap_dev *tuntap) {
    // TODO
    return;
}

#ifndef N2N_V1
// fill out the ip_addr value from the interface, called to pick up dynamic address changes
void tuntap_get_address (struct tuntap_dev *tuntap) {
    // no action
    return;
}
#endif
