.PHONY: build clean container createnetwork run removenetworks
.ONESHELL:
CONT_TYPE = docker
include ../tools/Makefile.shared
include $(DOCKERVARS) 
export
TMPOPENWRT:=openwrt/tmp
TMPNORDVPN:=nordvpn/tmp

build: build.target /usr/bin/docker

build.target:openwrt/$(OPENWRTIMAGE) openwrt/Dockerfile nordvpn/Dockerfile docker-compose.yml $(TMPNORDVPN) $(TMPOPENWRT) | $(ADGUARDVARS)
	@echo "BUILDING SERVICES"
	docker compose build || exit $$?
	docker compose create || exit $$?
	. $(GLOBALVARS) ; \
	. $(ADGUARDVARS) ; \
	for file in $(CONFIGDIR)/openwrt/*; do \
		envsubst <$${file} >$${file}.mod; \
		if [ "$$(basename $${file})" = "wireless.tpl" ] ; then \
			echo "Skipping template file $${file}"; \
		elif [ "$$(basename $${file})" = "rc.local" ] ; then \
			echo "Skipping rc.local"; \
		else \
			docker cp $${file}.mod $(CONTAINERWRT):/etc/config/$$(basename $${file}); \
		fi; \
	done;

	ADGUARDCONF=$(CONFIGDIR)/adguard/adguardhome.yaml; \
	envsubst <$${ADGUARDCONF} >$${ADGUARDCONF}.mod; \
	docker cp $${ADGUARDCONF}.mod $(CONTAINERWRT):/etc/$$(basename $${ADGUARDCONF}); 

	docker cp $(CONFIGDIR)/forward.ports $(CONTAINERVPN):/

	rm -f $${ADGUARDCONF}.mod
	rm -rf $(CONFIGDIR)/openwrt/*.mod
	touch build.target

run: build.target /usr/sbin/iw setupshim
	@echo "STARTING SERVICES"
	ip l set ${LAN_PARENT} promisc on
	ip l set ${WAN_PARENT} promisc on
	docker compose start
ifeq ($(WIFI_ENABLED),true)
	. $(GLOBALVARS) && $(WIFI_SCRIPT) add
endif
	sleep 10
	docker network connect ${WAN_NETWORK} $(CONTAINERWRT) || true
	RSLT=$$(docker exec $(CONTAINERWRT) /bin/sh -c "netstat -lnp|grep $(LAN_IP):80"); \
	while [ -z "$$RSLT" ]; do \
		echo "Waiting for uhttpd to start..."; \
		sleep 1; \
		docker exec $(CONTAINERWRT) /bin/sh -c "service uhttpd restart"; \
		RSLT=$$(docker exec $(CONTAINERWRT) /bin/sh -c "netstat -lnp|grep $(LAN_IP):80"); \
	done
	docker exec $(CONTAINERVPN) /bin/sh -c "ip r del default dev eth0"
	docker exec $(CONTAINERVPN) /bin/sh -c "dhclient eth0"
	docker exec $(CONTAINERVPN)	/bin/sh -c "ip r add $(LAN_SUBNET) via $(OPENWRT_LOCAL_IP)"

# sleep 8

openwrt/$(OPENWRTIMAGE):$(GLOBALVARS)
	@echo "DOWNLOADING IMAGE $(VERSION) $(ARCH) $(SUBARCH) into $(DOWNLOADNAME)"
	cd openwrt/
	wget https://downloads.openwrt.org/releases/$(VERSION)/targets/$(ARCH)/$(SUBARCH)/$(DOWNLOADNAME) -O $(DOWNLOADNAME)
	mv $(DOWNLOADNAME) $(OPENWRTIMAGE)
	touch $(OPENWRTIMAGE)

removecontainer:
	docker compose down

stop: removeshim
	docker network disconnect ${WAN_NETWORK} $(CONTAINERWRT)
	docker compose stop || exit $$?
	rm -rf /run/netns/$(CONTAINERWRT)
ifeq ($(WIFI_ENABLED),true)
	. $(GLOBALVARS) && $(WIFI_SCRIPT) remove
endif

clean: stop removecontainer
	@echo "CLEANING UP"
	docker compose rm -f
	rm -rf $(OPENWRTIMAGE) $(DOWNLOADNAME) $(DOWNLOADNAMEPI4)
	rm -rf build.target
	rm -rf $(TMPOPENWRT) $(TMPNORDVPN)
	docker rmi tgiesela/openwrt:latest || true
	docker rmi tgiesela/nordvpn:latest || true

$(TMPNORDVPN):
	mkdir -p $(TMPNORDVPN)
	cp -p $(GLOBALVARS) $(TMPNORDVPN)/vars
	cp -p $(CONFIGDIR)/nordvpn/*.sh $(TMPNORDVPN)/
	cp -p $(CONFIGDIR)/nordvpnvars $(TMPNORDVPN)/

$(TMPOPENWRT):
	mkdir -p $(TMPOPENWRT)
	cp -p $(GLOBALVARS) $(TMPOPENWRT)/vars

/usr/sbin/iw:
	@echo "Installing iw"
	apt-get update && apt-get install -y iw

/usr/bin/docker:
	@echo "Installing docker"
	curl -sSL https://get.docker.com | sh
