.PHONY: build clean stop FORCE
.ONESHELL:
CONT_TYPE  = lxc
include ../tools/Makefile.shared
include $(LXCVARS)
export

build: buildopenwrt buildnordvpn

buildopenwrt: $(CONTAINERROOTFS) openwrt/runconfig $(CONTAINERROOTFS)/etc/config stopopenwrt | /usr/bin/lxc-create ipv6 $(ADGUARDVARS)
	@echo "BUILDING IMAGE $(CONTAINERWRT) AND INSTALL ADDITIONAL MODULES"
	. $(GLOBALVARS) ; \
	envsubst <$(CONFIGDIR)/rc.local >rc.local.mod; \
	cp rc.local.mod $(CONTAINERROOTFS)/etc/rc.local; \
	rm -f rc.local.mod

	#	Copy configuration files
	for file in $(CONFIGDIR)/openwrt/*; do \
		envsubst <$${file} >$${file}.mod; \
		if [ "$$(basename $${file})" = "wireless.tpl" ] ; then \
			echo "Skipping template file $${file}"; \
		else \
			cp $${file}.mod $(CONTAINERROOTFS)/etc/config/$$(basename $${file}); \
		fi; \
	done

	ADGUARDCONF=$(CONFIGDIR)/adguard/adguardhome.yaml; \
	envsubst <$${ADGUARDCONF} >$${ADGUARDCONF}.mod; \
	cp $${ADGUARDCONF}.mod $(CONTAINERROOTFS)/etc/$$(basename $${ADGUARDCONF}); 

	rm -f $${ADGUARDCONF}.mod
	rm -rf $(CONFIGDIR)/openwrt/*.mod

	./lxccmd.sh start $(CONTAINERWRT) 
	./lxccmd.sh attach $(CONTAINERWRT) "cd /home/scripts/ && ./install.sh"
	./lxccmd.sh stop $(CONTAINERWRT)

	touch buildopenwrt

buildnordvpn: $(CONTAINERVPNROOTFS) nordvpn/runconfig | /usr/bin/lxc-create ipv6
	@echo "BUILDING IMAGE $(CONTAINERVPN) AND INSTALL ADDITIONAL MODULES"
	./lxccmd.sh start $(CONTAINERVPN)
	sleep 10
	./lxccmd.sh attach $(CONTAINERVPN) "cd /home/scripts/ && ./install.sh"
	./lxccmd.sh stop $(CONTAINERVPN)
	cp $(CONFIGDIR)/forward.ports $(CONTAINERVPNROOTFS)/ 

	touch buildnordvpn

run: runnordvpn runopenwrt setupshim

runopenwrt: openwrt/runconfig $(CONTAINERLOC)$(CONTAINERWRT)
	@echo "STARTING CONTAINER $(CONTAINERWRT)"
	ip l set ${LAN_PARENT} promisc on
	./lxccmd.sh start $(CONTAINERWRT)
ifeq ($(WIFI_ENABLED),true)
	. $(GLOBALVARS) && $(WIFI_SCRIPT) add
endif
	RSLT=$$(./lxccmd.sh attach $(CONTAINERWRT) "netstat -lnp|grep $(LAN_IP):80"); \
	echo RSLT=$${RSLT}
	while [ -z "$$RSLT" ]; do \
		echo "Waiting for uhttpd to start..."; \
		sleep 1; \
		./lxccmd.sh attach $(CONTAINERWRT) "service uhttpd restart"; \
		RSLT=$$(./lxccmd.sh attach $(CONTAINERWRT) "netstat -lnp|grep $(LAN_IP):80"); \
	done

	# sleep 12
	# ./lxccmd.sh attach $(CONTAINERWRT) "/etc/init.d/uhttpd stop" || true
	# ./lxccmd.sh attach $(CONTAINERWRT) "/etc/init.d/uhttpd restart"

runnordvpn: $(CONTAINERVPNLOC)$(CONTAINERVPN) 
	@echo "STARTING CONTAINER $(CONTAINERVPN)"
	ip l set ${WAN_PARENT} promisc on	
	./lxccmd.sh start $(CONTAINERVPN)
	sleep 5
	./lxccmd.sh attach $(CONTAINERVPN) "cd /home/scripts/ && ./start.sh"
	./lxccmd.sh attach $(CONTAINERVPN) "ip r del default dev eth0"
	./lxccmd.sh attach $(CONTAINERVPN) "dhclient eth0"
	./lxccmd.sh attach $(CONTAINERVPN) "ip r add $(LAN_SUBNET) via $(OPENWRT_LOCAL_IP)"
	
clean:cleanopenwrt cleannordvpn

cleanopenwrt: stopopenwrt
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINERWRT) || true
	rm -rf $(CONTAINERROOTFS)
	rm -rf buildopenwrt

cleannordvpn: stopnordvpn
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINERVPN) || true
	rm -rf $(CONTAINERVPNROOTFS)
	rm -rf buildnordvpn

stop: stopopenwrt stopnordvpn removeshim

stopopenwrt:
	./lxccmd.sh stop $(CONTAINERWRT)
ifeq ($(WIFI_ENABLED),true)
	. $(GLOBALVARS) && $(WIFI_SCRIPT) remove
endif

stopnordvpn:
	@echo "DISCONNECTING NORDVPN CONTAINER $(CONTAINERVPN)"
	./lxccmd.sh attach $(CONTAINERVPN) "cd /home/scripts/ && ./stop.sh"
	./lxccmd.sh stop $(CONTAINERVPN)

/usr/bin/lxc-create:
	apt update && apt install -y lxc

ipv6:
	sed -i '/LXC_IPV6_/d' /etc/default/lxc-net
ifeq ($(IPV6_ENABLED),true)
	echo "LXC_IPV6_ADDR=fd80:192:168:56::3" >> /etc/default/lxc-net ; \
	echo "LXC_IPV6_MASK=64" >> /etc/default/lxc-net ; \
	echo "LXC_IPV6_NETWORK=fd80:192:168:56::" >> /etc/default/lxc-net ; \
	echo "LXC_IPV6_NAT=true" >> /etc/default/lxc-net 
endif
	service lxc-net restart

openwrt/runconfig: $(GLOBALVARS) $(CONTAINERCONFIG)
	rm -rf $@
	envsubst < $(CONTAINERCONFIG) > $@

nordvpn/runconfig: $(GLOBALVARS) $(CONTAINERVPNROOTFS)/home/scripts $(CONTAINERVPNCONFIG)
	rm -rf $@
	envsubst < $(CONTAINERVPNCONFIG) > $@

$(CONTAINERVPNROOTFS)/home/scripts: $(GLOBALVARS) $(LXCVARS)
	@echo "CREATING NORDVPN VARIABLES IN $(CONTAINERVPNROOTFS)/home/scripts"
	mkdir -p $(CONTAINERVPNROOTFS)/home/scripts/
	cp $(CONFIGDIR)/nordvpn/*.sh $(CONTAINERVPNROOTFS)/home/scripts/
	cp -r nordvpn/scripts/ $(CONTAINERVPNROOTFS)/home/
	chmod +x $(CONTAINERVPNROOTFS)/home/scripts/*.sh
	cp $(GLOBALVARS) $(CONTAINERVPNROOTFS)/home/scripts/vars
	cp $(LXCVARS) $(CONTAINERVPNROOTFS)/home/scripts/lxcvars
	cp $(NORDVPNVARS) $(CONTAINERVPNROOTFS)/home/scripts/nordvpnvars

$(CONTAINERROOTFS)/etc/config: $(GLOBALVARS) $(LXCVARS)
	@echo "CREATING CONFIGURATION FILES IN $(CONTAINERROOTFS)/etc/config"
#	Create directories and copy scripts
	mkdir -p $(CONTAINERROOTFS)/home/
	mkdir -p $(CONTAINERROOTFS)/etc/config/
	cp -r openwrt/scripts/ $(CONTAINERROOTFS)/home/
	cp $(GLOBALVARS) $(CONTAINERROOTFS)/home/scripts/vars
	cp $(LXCVARS) $(CONTAINERROOTFS)/home/scripts/lxcvars
	chmod +x $(CONTAINERROOTFS)/home/scripts/*.sh

$(OPENWRTIMAGE): $(GLOBALVARS)
	@echo "DOWNLOADING IMAGE $(VERSION) $(ARCH) $(SUBARCH)"
	wget -4 https://downloads.openwrt.org/releases/${VERSION}/targets/${ARCH}/${SUBARCH}/${DOWNLOADNAME} -O $(DOWNLOADNAME)
	mv $(DOWNLOADNAME) $(OPENWRTIMAGE)
	touch $(OPENWRTIMAGE)

$(CONTAINERROOTFS): $(OPENWRTIMAGE)
	@echo "CREATING CONTAINER $(CONTAINERWRT) FROM IMAGE $(OPENWRTIMAGE)"
#	Create container directory and config
	lxc-create -n $(CONTAINERWRT) -t download -- -d openwrt -a $(LXCARCH) -r 24.10
	rm -rf $(CONTAINERROOTFS)/*
	tar xzf $(OPENWRTIMAGE) -C $(CONTAINERROOTFS)

$(CONTAINERVPNROOTFS):
	@echo "CREATING CONTAINER $(CONTAINERVPN) FROM IMAGE $(NORDVPNIMAGE)"
	lxc-create -n $(CONTAINERVPN) -t download -- -d debian -a $(LXCARCH) -r bookworm

iptables:
#	Only run this if you have issues with the iptables rules with docker installed
	iptables -D  DOCKER-USER -i lxcbr0 -o $(LAN_PARENT) -j ACCEPT || true
	iptables -D  DOCKER-USER -o lxcbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || true
	iptables -t nat -D POSTROUTING -s 10.0.3.0/24 -o $(LAN_PARENT) -j MASQUERADE || true
	iptables -I  DOCKER-USER -i lxcbr0 -o $(LAN_PARENT) -j ACCEPT
	iptables -I  DOCKER-USER -o lxcbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -t nat -I POSTROUTING -s 10.0.3.0/24 -o $(LAN_PARENT) -j MASQUERADE
	iptables -P FORWARD ACCEPT
