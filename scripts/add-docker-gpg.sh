#!/bin/bash
wget -qO - https://download.docker.com/linux/ubuntu/gpg | apt-key add -
wget -qO - https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.io.list

