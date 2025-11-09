#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >>$LOGFILE
# 设置默认防火墙规则，方便单网口虚拟机首次访问 WebUI 
# 因为本项目中 单网口模式是dhcp模式 直接就能上网并且访问web界面 避免新手每次都要修改/etc/config/network中的静态ip
# 当你刷机运行后 都调整好了 你完全可以在web页面自行关闭 wan口防火墙的入站数据
# 具体操作方法：网络——防火墙 在wan的入站数据 下拉选项里选择 拒绝 保存并应用即可。

# Beware! This script will be in /rom/etc/uci-defaults/ as part of the image.
# Uncomment lines to apply:
#
# wlan_name="ImmortalWrt"
# wlan_password="12345678"
#
root_password="password"
lan_ip_address="192.168.5.1"
#
pppoe_username="085104704559"
pppoe_password="704559"

# log potential errors
exec >/tmp/setup.log 2>&1

if [ -n "$root_password" ]; then
  (echo "$root_password"; sleep 1; echo "$root_password") | passwd > /dev/null
fi

# Configure Vlmcsd
uci set vlmcsd.config.enabled='1'
uci set vlmcsd.config.auto_activate='1'
uci commit vlmcsd

# Configure Ports
uci add_list network.@device[0].ports=eth2
uci add_list network.@device[0].ports=eth3
uci set network.lan.ip6assign=64
uci set network.lan.ip6ifaceid=eui64
uci delete network.globals.ula_prefix
uci commit network

# Configure DHCP
uci del dhcp.lan.ra_slaac
uci del dhcp.lan.dhcpv6
uci del dhcp.lan.ra_flags
uci set dhcp.lan.dns_service='0'
uci add_list dhcp.lan.ra_flags='none'
uci del dhcp.cfg01411c.dns_redirect
uci del dhcp.cfg01411c.rebind_localhost
uci del dhcp.cfg01411c.nonwildcard
uci del dhcp.cfg01411c.resolvfile
uci del dhcp.cfg01411c.boguspriv
uci del dhcp.cfg01411c.filterwin2k
uci del dhcp.cfg01411c.filter_aaaa
uci del dhcp.cfg01411c.filter_a
uci commit dhcp

# Configure AutoReboot
uci set autoreboot.cfg016bf2.enabled='1'
uci set autoreboot.cfg016bf2.week='0'
uci set autoreboot.cfg016bf2.hour='5'
uci commit autoreboot

# Configure MosDNS
uci set mosdns.config.geo_auto_update='1'
uci set mosdns.config.geoip_type='geoip'
uci set mosdns.config.local_dns_redirect='1'
uci set mosdns.config.prefer_ipv4_cn='1'
uci del mosdns.config.remote_dns
uci add_list mosdns.config.remote_dns='tls://8.8.8.8'
uci set mosdns.config.dns_leak='1'
uci set mosdns.config.cache_size='16000'
uci set mosdns.config.dump_file='1'
uci set mosdns.config.dump_interval='3600'
uci set mosdns.config.enabled='1'
uci commit mosdns

# Configure HomeProxy
uci del homeproxy.dns.disable_cache
uci del homeproxy.dns.disable_cache_expire
uci set homeproxy.config.china_dns_server='127.0.0.1'
uci set homeproxy.routing.bypass_cn_traffic='0'
uci set homeproxy.dns.default_server='default-dns'
uci set homeproxy.subscription.auto_update='1'
uci set homeproxy.subscription.auto_update_time='2'
uci set homeproxy.subscription.update_via_proxy='0'
uci add_list homeproxy.subscription.subscription_url='https://53681.nginx24zfd.xyz/link/E7FXsv1TNaHf7Kke?sub=3'
uci add_list homeproxy.subscription.subscription_url='https://wk.mlzone.top/yx/sub'
uci commit homeproxy

# Configure LAN
# More options: https://openwrt.org/docs/guide-user/base-system/basic-networking
if [ -n "$lan_ip_address" ]; then
  uci set network.lan.ipaddr="$lan_ip_address"
  uci commit network
fi

# Configure WLAN
# More options: https://openwrt.org/docs/guide-user/network/wifi/basic#wi-fi_interfaces
if [ -n "$wlan_name" -a -n "$wlan_password" -a ${#wlan_password} -ge 8 ]; then
  uci set wireless.@wifi-device[0].disabled='0'
  uci set wireless.@wifi-iface[0].disabled='0'
  uci set wireless.@wifi-iface[0].encryption='psk2'
  uci set wireless.@wifi-iface[0].ssid="$wlan_name"
  uci set wireless.@wifi-iface[0].key="$wlan_password"
  uci commit wireless
fi

# Configure PPPoE
# More options: https://openwrt.org/docs/guide-user/network/wan/wan_interface_protocols#protocol_pppoe_ppp_over_ethernet
if [ -n "$pppoe_username" -a "$pppoe_password" ]; then
  uci set network.wan.proto=pppoe
  uci set network.wan.username="$pppoe_username"
  uci set network.wan.password="$pppoe_password"
  uci commit network
fi

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Packaged by wukongdaily"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
