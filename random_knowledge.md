## Adding Wireguard Connection

nmcli connection import type wireguard file Downloads/protonvpn.conf

## Starting virtuald network

sudo virsh net-start default