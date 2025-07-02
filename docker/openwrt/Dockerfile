FROM scratch
ADD rootfs.tar.gz /

RUN mkdir -p /var/lock

RUN opkg remove --force-depends procd-ujail
RUN opkg update && opkg list-upgradable | awk '{print $1}' | xargs opkg upgrade || true
RUN opkg install nano bash tcpdump curl kmod-mac80211 iwinfo kmod-wireguard luci-proto-wireguard wireguard-tools usbutils hostapd
RUN opkg install pbr luci-app-pbr

CMD ["/sbin/init"]

