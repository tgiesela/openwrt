.PHONY: build clean stop FORCE
.ONESHELL:
include ../config/vars
CNTNETWORKPREFIX:=10.0.3
CNTNETWORKMASKLEN:=24
export

build: buildopenwrt buildnordvpn

buildopenwrt: ipv6 /usr/bin/lxc-create $(CONTAINERROOTFS) runconfig $(CONTAINERROOTFS)/etc/config stopopenwrt
	@echo "BUILDING IMAGE $(CONTAINER) AND INSTALL ADDITIONAL MODULES"
	rm -rf error.log
	lxc-start -o error.log -f runconfig -c /dev/tty1 $(CONTAINER)
	lxc-attach $(CONTAINER) -- /bin/sh -c "/home/scripts/install.sh"

	lxc-stop -k $(CONTAINER)
	@echo "WAITING FOR CONTAINER $(CONTAINER) TO STOP"
	lxc-wait --name=$(CONTAINER) --state=STOPPED
	@echo "CONTAINER $(CONTAINER) STOPPED"

	#	Copy configuration files
	cd openwrt; \
	for file in config/*; do \
		envsubst <$${file} >$${file}.mod; \
		cp $${file}.mod $(CONTAINERROOTFS)/etc/$${file}; \
	done ; \
	rm -rf config/*.mod ;\
	cd -

	touch buildopenwrt

buildnordvpn: ipv6 /usr/bin/lxc-create $(CONTAINERVPNROOTFS) runconfigvpn stopnordvpn
	@echo "BUILDING IMAGE $(CONTAINERVPN) AND INSTALL ADDITIONAL MODULES"
	rm -rf errorvpn.log
	cp -r nordvpn/scripts/ $(CONTAINERVPNROOTFS)/home/
	chmod +x $(CONTAINERVPNROOTFS)/home/scripts/*.sh
	lxc-start -o errorvpn.log -f runconfigvpn -c /dev/tty1 $(CONTAINERVPN)
	sleep 10
	lxc-attach $(CONTAINERVPN) -- /bin/sh -c "cd /home/scripts/ && ./install.sh"

	lxc-stop -k $(CONTAINERVPN)
	@echo "WAITING FOR CONTAINER $(CONTAINERVPN) TO STOP"
	lxc-wait --name=$(CONTAINERVPN) --state=STOPPED
	@echo "CONTAINER $(CONTAINERVPN) STOPPED"

	touch buildnordvpn

run: runnordvpn runopenwrt

runopenwrt: runconfig $(CONTAINERLOC)$(CONTAINER) 
	@echo "STARTING CONTAINER $(CONTAINER)"
	ip l set ${LAN_PARENT} promisc on
	rm -rf error.log
	lxc-start --lxcpath=$(CONTAINERLOC) -o error.log -f runconfig -c /dev/tty1 $(CONTAINER)
	./addwifi.sh add
	sleep 10
	lxc-attach $(CONTAINER) service uhttpd restart

runnordvpn: buildnordvpn runconfigvpn $(CONTAINERVPNLOC)$(CONTAINERVPN)
	@echo "STARTING CONTAINER $(CONTAINERVPN)"
	ip l set ${WAN_PARENT} promisc on	
	rm -rf errorvpn.log
	lxc-start --lxcpath=$(CONTAINERLOC) -o errorvpn.log -f runconfigvpn -c /dev/tty1 $(CONTAINERVPN)
	sleep 5
	lxc-attach $(CONTAINERVPN) -- /bin/sh -c "cd /home/scripts/ && ./start.sh"

clean:cleanopenwrt cleannordvpn

cleanopenwrt: stopopenwrt
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINER) || true
	echo rm -rf $(CONTAINERROOTFS)
	rm -rf buildopenwrt

cleannordvpn: stopnordvpn
	lxc-destroy --lxcpath=$(CONTAINERLOC) $(CONTAINERVPN) || true
	echo rm -rf $(CONTAINERVPNROOTFS)
	rm -rf buildnordvpn

stop: stopopenwrt stopnordvpn

stopopenwrt:
	lxc-stop -n $(CONTAINER) || true
	@echo "WAITING FOR CONTAINER $(CONTAINER) TO STOP"
	lxc-wait --name=$(CONTAINER) --state=STOPPED
	@echo "CONTAINER $(CONTAINER) STOPPED"
	./addwifi.sh remove

stopnordvpn:
	@echo "DISCONNECTING NORDVPN CONTAINER $(CONTAINERVPN)"
	lxc-attach $(CONTAINERVPN) -- /bin/sh -c "cd /home/scripts/ && ./stop.sh"
	lxc-stop -n $(CONTAINERVPN) || true
	@echo "WAITING FOR CONTAINER $(CONTAINERVPN) TO STOP"
	lxc-wait --name=$(CONTAINERVPN) --state=STOPPED
	@echo "CONTAINER $(CONTAINERVPN) STOPPED"


/usr/bin/lxc-create:
	apt update && apt install -y lxc

ipv6:
	IPV6=$(shell grep LXC_IPV6 /etc/default/lxc-net)
	if [ -z "$${IPV6}" ] ; then \
		echo "LXC_IPV6_ADDR=fd80:192:168:56::3" >> /etc/default/lxc-net ; \
		echo "LXC_IPV6_MASK=64" >> /etc/default/lxc-net ; \
		echo "LXC_IPV6_NETWORK=fd80:192:168:56::" >> /etc/default/lxc-net ; \
		echo "LXC_IPV6_NAT=true" >> /etc/default/lxc-net ; \
	fi

runconfig: vars $(CONTAINERCONFIG)
	rm -rf runconfig
	envsubst < $(CONTAINERCONFIG) > runconfig

runconfigvpn: vars $(CONTAINERVPNROOTFS)/home/scripts/vars $(CONTAINERVPNCONFIG)
	rm -rf runconfigvpn
	envsubst < $(CONTAINERVPNCONFIG) > runconfigvpn

$(CONTAINERVPNROOTFS)/home/scripts/vars: vars
	@echo "CREATING NORDVPN VARIABLES IN $(CONTAINERVPNROOTFS)/home/scripts/vars"
	mkdir -p $(CONTAINERVPNROOTFS)/home/scripts/
	cp vars $(CONTAINERVPNROOTFS)/home/scripts/vars

$(CONTAINERROOTFS)/etc/config: openwrt/config/* vars
	@echo "CREATING CONFIGURATION FILES IN $(CONTAINERROOTFS)/etc/config"
#	Create directories and copy scripts
	mkdir -p $(CONTAINERROOTFS)/home/
	mkdir -p $(CONTAINERROOTFS)/etc/config/
	cp -r openwrt/scripts/ $(CONTAINERROOTFS)/home/
	cp vars $(CONTAINERROOTFS)/home/scripts/vars
	chmod +x $(CONTAINERROOTFS)/home/scripts/*.sh

$(OPENWRTIMAGE): vars
	@echo "DOWNLOADING IMAGE $(VERSION) $(ARCH) $(SUBARCH)"
	wget -4 https://downloads.openwrt.org/releases/${VERSION}/targets/${ARCH}/${SUBARCH}/${DOWNLOADNAME} -O $(DOWNLOADNAME)
	mv $(DOWNLOADNAME) $(OPENWRTIMAGE)
	touch $(OPENWRTIMAGE)

$(CONTAINERROOTFS): $(OPENWRTIMAGE)
	@echo "CREATING CONTAINER $(CONTAINER) FROM IMAGE $(OPENWRTIMAGE)"
#	Create container directory and config
	lxc-create -n $(CONTAINER) -t download -- -d openwrt -a arm64 -r 24.10
	rm -rf $(CONTAINERROOTFS)/*
	tar xzf $(OPENWRTIMAGE) -C $(CONTAINERROOTFS)

$(CONTAINERVPNROOTFS):
	@echo "CREATING CONTAINER $(CONTAINERVPN) FROM IMAGE $(NORDVPNIMAGE)"
	lxc-create -n $(CONTAINERVPN) -t download -- -d debian -a arm64 -r bookworm

iptables:
#	Only run this if you have issues with the iptables rules with docker installed
	iptables -D  DOCKER-USER -i lxcbr0 -o eth0 -j ACCEPT || true
	iptables -D  DOCKER-USER -o lxcbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || true
	iptables -t nat -D POSTROUTING -s 10.0.3.0/24 -o eth0 -j MASQUERADE || true
	iptables -I  DOCKER-USER -i lxcbr0 -o eth0 -j ACCEPT
	iptables -I  DOCKER-USER -o lxcbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -t nat -I POSTROUTING -s 10.0.3.0/24 -o eth0 -j MASQUERADE
