FROM scratch
ADD rootfs.tar.gz /

RUN mkdir -p /var/lock

#Original
#RUN opkg remove --force-depends dnsmasq* wpad* iw* procd-ujail && \
#    opkg update && \
#    opkg install luci wpad-wolfssl iw-full ip-full kmod-mac80211 dnsmasq-full iwinfo nano bash tcpdump curl

RUN opkg remove --force-depends procd-ujail
RUN opkg update && opkg list-upgradable | awk '{print $1}' | xargs opkg upgrade || true
RUN opkg install nano bash tcpdump curl kmod-mac80211 iwinfo kmod-wireguard luci-proto-wireguard wireguard-tools usbutils hostapd


#RUN sed -i '/^exit 0/i cat \/tmp\/resolv.conf > \/etc\/resolv.conf' /etc/rc.local
#RUN sed -i 's/procd_add_jail/# \0/g' /etc/init.d/dnsmasq
#RUN sed -i 's/procd_add_jail/# \0/g' /etc/init.d/sysntpd
#COPY --chmod=755 scripts/init.sh /init.sh
#COPY config/network /etc/config/network

#ENTRYPOINT ["/init.sh"]
#CMD ["app:start"]
CMD ["/sbin/init"]

