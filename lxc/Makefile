.PHONY: build clean stop FORCE
.ONESHELL:
CONFIGDIR  = ../config
GLOBALVARS = $(CONFIGDIR)/vars
LXCVARS	   = $(CONFIGDIR)/lxcvars
NORDVPNVARS= $(CONFIGDIR)/nordvpnvars
CONT_TYPE  = lxc
include $(GLOBALVARS) $(LXCVARS)
export

build: buildopenwrt buildnordvpn

buildopenwrt: $(CONTAINERROOTFS) openwrt/runconfig $(CONTAINERROOTFS)/etc/config stopopenwrt | /usr/bin/lxc-create ipv6
	@echo "BUILDING IMAGE $(CONTAINERWRT) AND INSTALL ADDITIONAL MODULES"
	. $(GLOBALVARS) ; \
	envsubst <$(CONFIGDIR)/rc.local >rc.local.mod; \
	cp rc.local.mod $(CONTAINERROOTFS)/etc/rc.local; \
	rm -f rc.local.mod
# 	sed -i '/sysctl -w net.ipv6.conf/d' $(CONTAINERROOTFS)/etc/rc.local
# 	sed -i '/exit 0/d' $(CONTAINERROOTFS)/etc/rc.local

# ifeq ($(IPV6_ENABLED),true)
# 	echo "sysctl -w net.ipv6.conf.all.disable_ipv6=0" >> $(CONTAINERROOTFS)/etc/rc.local
# 	echo "sysctl -w net.ipv6.conf.default.disable_ipv6=0" >> $(CONTAINERROOTFS)/etc/rc.local
# else
# 	echo "sysctl -w net.ipv6.conf.all.disable_ipv6=1" >> $(CONTAINERROOTFS)/etc/rc.local
# 	echo "sysctl -w net.ipv6.conf.default.disable_ipv6=1" >> $(CONTAINERROOTFS)/etc/rc.local
# endif
# 	echo "exit 0" >> $(CONTAINERROOTFS)/etc/rc.local
	#	Copy configuration files
	for file in $(CONFIGDIR)/openwrt/*; do \
		envsubst <$${file} >$${file}.mod; \
		if [ "$$(basename $${file})" = "wireless.tpl" ] ; then \
			echo "Skipping template file $${file}"; \
		else \
			cp $${file}.mod $(CONTAINERROOTFS)/etc/config/$$(basename $${file}); \
		fi; \
	done
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

	touch buildnordvpn

run: runnordvpn runopenwrt

runopenwrt: openwrt/runconfig $(CONTAINERLOC)$(CONTAINERWRT)
	@echo "STARTING CONTAINER $(CONTAINERWRT)"
	ip l set ${LAN_PARENT} promisc on
	./lxccmd.sh start $(CONTAINERWRT)
	$(WIFI_SCRIPT) add
	sleep 10
	./lxccmd.sh attach $(CONTAINERWRT) "service uhttpd restart"

runnordvpn: $(CONTAINERVPNLOC)$(CONTAINERVPN) 
	@echo "STARTING CONTAINER $(CONTAINERVPN)"
	ip l set ${WAN_PARENT} promisc on	
	./lxccmd.sh start $(CONTAINERVPN)
	sleep 5
	./lxccmd.sh attach $(CONTAINERVPN) "cd /home/scripts/ && ./start.sh"

clean:cleanopenwrt cleannordvpn

cleanopenwrt: stopopenwrt
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINERWRT) || true
	rm -rf $(CONTAINERROOTFS)
	rm -rf buildopenwrt

cleannordvpn: stopnordvpn
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINERVPN) || true
	rm -rf $(CONTAINERVPNROOTFS)
	rm -rf buildnordvpn

stop: stopopenwrt stopnordvpn

stopopenwrt:
	./lxccmd.sh stop $(CONTAINERWRT)
	$(WIFI_SCRIPT) remove

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

install:
	LINE=$(shell crontab -l | grep -c "$(shell pwd)/boot.sh"); \
	if [ "$${LINE}" -eq 0 ]; then \
		(crontab -l; echo "@reboot cd $(shell pwd) && ./boot.sh > ./boot.log") | crontab - ; \
	fi
	chmod +x $(shell pwd)/boot.sh

uninstall:
	(crontab -l | sed  'd#@reboot cd $(shell pwd) && ./boot.sh/#')|crontab -