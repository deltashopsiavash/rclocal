#!/bin/bash

clear
echo "====== GRE Tunnel Setup ======"

read -p "Select mode (IR / KH): " MODE

if [[ "$MODE" == "IR" ]]; then
    read -p "Enter IR local IP: " IR_IP
    read -p "How many KH servers?: " COUNT

    i=1
    while [ $i -le $COUNT ]
    do
        read -p "Enter KH$i IP: " KH_IP

        TUN="gre$i"
        NET="10.10.$((i*10)).0"
        IR_TUN_IP="10.10.$((i*10)).1/30"

        echo "Setting $TUN -> $KH_IP"

        ip tunnel del $TUN 2>/dev/null

        ip tunnel add $TUN mode gre remote $KH_IP local $IR_IP ttl 255
        ip link set $TUN mtu 1400
        ip addr add $IR_TUN_IP dev $TUN
        ip link set $TUN up

        sysctl -w net.ipv4.conf.$TUN.rp_filter=0

        i=$((i+1))
    done

    iptables -I INPUT -p gre -j ACCEPT
    iptables -I OUTPUT -p gre -j ACCEPT

    echo "IR setup done ✅"


elif [[ "$MODE" == "KH" ]]; then
    read -p "Enter KH local IP: " KH_IP
    read -p "Enter IR IP: " IR_IP
    read -p "Tunnel number (1,2,3...): " NUM

    TUN="gre$NUM"
    NET="10.10.$((NUM*10)).0"
    KH_TUN_IP="10.10.$((NUM*10)).2/30"

    ip tunnel del $TUN 2>/dev/null

    ip tunnel add $TUN mode gre remote $IR_IP local $KH_IP ttl 255
    ip link set $TUN mtu 1400
    ip addr add $KH_TUN_IP dev $TUN
    ip link set $TUN up

    sysctl -w net.ipv4.conf.$TUN.rp_filter=0

    iptables -I INPUT -p gre -j ACCEPT
    iptables -I OUTPUT -p gre -j ACCEPT

    echo "KH setup done ✅"

else
    echo "Invalid mode ❌"
fi

echo ""
echo "Check tunnels:"
ip -br addr | grep gre
