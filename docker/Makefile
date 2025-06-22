.PHONY: build clean container createnetwork run removenetworks
.ONESHELL:
CONFIGDIR:=../config
GLOBALVARS:=$(CONFIGDIR)/vars
DOCKERVARS:=$(CONFIGDIR)/dockervars
include $(GLOBALVARS) $(DOCKERVARS)
export
TMPOPENWRT:=openwrt/tmp
TMPNORDVPN:=nordvpn/tmp

build: build.target

build.target:openwrt/$(OPENWRTIMAGE) openwrt/Dockerfile nordvpn/Dockerfile docker-compose.yml $(TMPNORDVPN) $(TMPNORDVPN)
	@echo "BUILDING SERVICES"
	docker compose build || exit $$?
	docker compose create || exit $$?
	for file in $(CONFIGDIR)/openwrt/*; do \
		envsubst <$${file} >$${file}.mod; \
		docker cp $${file}.mod $(CONTAINERWRT):/etc/config/$$(basename $${file}); \
	done
	rm -rf $(CONFIGDIR)/openwrt/*.mod
	touch build.target

run: build.target /usr/sbin/iw
	@echo "STARTING SERVICES ${LAN_IP}"
	ip l set ${LAN_PARENT} promisc on
	ip l set ${WAN_PARENT} promisc on
	docker compose up -d
ifeq ($(WIFI_ENABLED),true)
	./addwifi.sh add
endif

openwrt/$(OPENWRTIMAGE):$(GLOBALVARS)
	@echo "DOWNLOADING IMAGE $(VERSION) $(ARCH) $(SUBARCH) into $(DOWNLOADNAME)"
	cd openwrt/
	wget https://downloads.openwrt.org/releases/$(VERSION)/targets/$(ARCH)/$(SUBARCH)/$(DOWNLOADNAME) -O $(DOWNLOADNAME)
	mv $(DOWNLOADNAME) $(OPENWRTIMAGE)
	touch $(OPENWRTIMAGE)

removecontainer:
	docker compose down

stop:
	docker compose stop || exit $$?
	rm -rf /run/netns/$(CONTAINERWRT)
ifeq ($(WIFI_ENABLED),true)
	./addwifi.sh remove
endif

clean: stop removecontainer
	@echo "CLEANING UP"
	docker compose rm -f
	rm -rf $(OPENWRTIMAGE) $(DOWNLOADNAME) $(DOWNLOADNAMEPI4)
	rm -rf build.target
	rm -rf $(TMPOPENWRT) $(TMPNORDVPN)
	# rm -rf /run/netns/$(CONTAINERWRT)

$(TMPNORDVPN):
	mkdir -p $(TMPNORDVPN)
	cp $(GLOBALVARS) $(TMPNORDVPN)/vars
	cp ../config/nordvpn/functions.sh $(TMPNORDVPN)/functions.sh

$(TMPOPENWRT):
	mkdir -p $(TMPOPENWRT)
	cp $(GLOBALVARS) $(TMPOPENWRT)/vars

/usr/sbin/iw:
	@echo "Installing iw"
	apt-get update && apt-get install -y iw