# Openwrt with nordpvn in container
Openwrt router running in docker or lxc container on Raspberry PI 4B+.

## Why
I wanted a router with nordvpn to avoid installing a VPN on all machines. 
This is necessary because once the Nordvpn application is installed, it is very hard to use your own local DNS server. Everything is routed via the Nordvpn DNS-servers which are not aware of the local network configuration. You can configure your own DNS-server in Nordvpn, but this cannot be a local DNS-server. You will have to do that via a device which is accessible via Meshnet.

## Issues during development
I first tried to install Nordvpn in a docker container running on Openwrt. But I could not get this working. There were issues with the firewall (fw3/fw4) used by Openwrt and iptables used by Nordvpn. Even when bypassing the firewall issue I could not get Nordvpn started in the docker container. 
Also the lxc version available on Openwrt was an option, but this appeared to be an old poorly maintained version, so I did not go on with that.
Then I decided to run Openwrt and Nordvpn in containers, e.g. lxc or docker. Because I was running from a raspberry Pi 4B+, I started of with the Openwrt image for that machine. But that gave issues with the Wireless part. It seems that the hostapd was not working properly in a docker/lxc container. At that time I almost gave up. But than I made a final attempt and instead of the Raspberry Pi 4B+ image, I switched to the armv8 version. And now the hostapd was working as expected.

# Installation
You can choose to run the docker version or the lxc version.

## Configuration
There are several configuration files. Copy the following files:

    cp vars.example vars
    cp nordvpnvars.example nordvpnvars

Change the secret values between <> in these files. And adjust other parameters to your needs.

`dockervars`
Adjust these variables if the defaults do not apply. Not used in lxc containers.

`lxcvars`
Adjust these variables if the defaults do not apply. Not used in docker containers.

`vars`
This file contains general variables, some parameters depend on values which will be set in the makefile by importing dockervars or lxcvars. 

`nordvpnvars`
This file contains the nordvpn specific variables. You should change the following variables:
- MESHROUTING
    - A list of nordvpn device names separated by ';' which are allowed to access the network (always via vpn)
- MESHLOCAL
    - A list of nordvpn device names separated by ';' which are allowed to access local resources to the router (always via vpn)
- TOKEN
    - An access token to login without userid password. Can be generated via the nordvpn website. (See: [Nordvpn token](https://support.nordvpn.com/hc/en-us/articles/20286980309265-How-to-use-a-token-with-NordVPN-on-Linux))
- NORDVPNNICKNAME
    - The name of the nordvpn container. It can be used as an alternative to regularly changing names like <userid>-pyrenees.nord
- VPNCONNECT
    - The country or server to which you want to connect.

## Networking
You need to configure one network adapter to get access to your machine. I reserved an IP4-address ending with .2 to achieve this. IP4-address ending with .1 was reserved for testing in Virtual Box containers. This is allocated by Virtual Box. Feel free to adjust this in the 'config/vars'.

### Wireless adapters
You can configure multiple WiFi-adapters to use in Openwrt. They will be moved into the network namespace of the docker/lxc containers. This is also the reason why the autostart feature of docker and lxc do not work, because on restart the Wifi-adapters are not automatically moved to the containers. This is achieved by running the 'make run' command, which starts the 'addwifi.sh' script.

## Install Docker version
You must have docker installed before you can continue with installation.

You can run the following commands:

`make build`
`make run`
`make install`

The build step will create the docker networks and containers. 
The run step will start the docker containers. In a few seconds your system should be up and running. Note: there are some delays, to allow the containers to startup and configure themselves.
If everything is working fine, you can run the install step, which will add the run step to the crontab. 

## Install lxc version
You can run the following commands:

`make build`
`make run`
`make install`

The build step will install lxc if not already installed. It also creates the lxc-containers.
The run step will start the lxc containers. In a few seconds your system should be up and running. Note: there are some delays, to allow the containers to startup and configure themselves.
If everything is working fine, you can run the install step, which will add the run step to the crontab. 

# Bypass VPN
In some cases you might want to bypass the VPN. For example: some applications do not allow access via VPN. In that case you can configure this via Policy Based Routing (Services>Policy Routing).
Under Policies add the machine/subnet which needs direct access to the internet. Configure it with interface-name 'novpn'. 

# Issues
## Ipv6
Nordvpn currently does not support Ipv6. It will disable Ipv6 traffic on the machine/container in which it installed. This will give issues in this setup, because Openwrt is running in different container, and when it uses Ipv6 locally and for the clients connected, this traffic will bypass the vpn or will disappear in a 'black-hole', which will cause timeouts. So I decided to turn of Ipv6 in Openwrt and in the docker networks.
Once Nordvpn supports Ipv6, it should be sufficient to enable Ipv6 in the 'config/vars' file by setting IPV6_ENABLED to true.
