#!/bin/bash

case "$COMMAND" in
  ADD)
    # Download rootfs for container
    apt install -y debootstrap
    debootstrap --variant=minbase bionic container1

    # Init container
    chroot container1 bash
    apt update
    apt install -y curl nginx iproute2
    rm /var/www/html/index.nginx-debian.html
    echo "Welcome from container1" >> /var/www/html/index.html

    # Create two namespaces
    ip netns add con1

    # Run container1 within its namespace
    unshare --pid --fork --net=/var/run/netns/con1 --mount-proc=$PWD/container1/proc chroot container1 bash

    # Check pid namepsace
    ps aux # bash should have pid 1

    # Enable nginx server and enable lo interface
    ip link set dev lo up
    service nginx start
    curl 127.0.0.1 # Should return welcome page

    # Create bridge network interface (switch)
    ip link add bridge0 type bridge
    ip addr add 180.10.0.1/24 dev bridge0
    ip link set bridge0 up

    # Create virtual network interface to link container1 to bridge0
    ip link add veth1 type veth peer name veth1-br
    ip link set veth1 netns con1
    ip netns exec con1 ip addr add 180.10.0.2/24 dev veth1
    ip link set veth1-br master bridge0

    # Enable all network interfaces
    ip netns exec con1 ip link set dev veth1 up
    ip link set dev veth1-br up
    ip link set dev bridge0 up
    
    # Add route to container1 to reach host
    ip netns exec con1 ip route add default via 180.10.0.1

    # Check From host
    curl 180.10.0.2 # Should return "Welcome from container1" message

    # Check From container1
    curl 10.0.2.15:3000 # Should return "Welcome from host" if nodejs app is enabled using pm2, update ip by your host one (eth0)

    ;;
esac
