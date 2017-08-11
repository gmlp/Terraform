#!/usr/bin/bash
apt-get install ${packages} -y
echo "${nameserver}" >> /etc/resolv.conf
