#!/bin/bash

# uploads the binary to the iPhone
IPHONE_IP="192.168.1.133"
SSH_USER="root"
SSH_OPTS="-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"

echo "Entering ssh in $SSH_USER@$IPHONE_IP..."

ssh $SSH_OPTS $SSH_USER@$IPHONE_IP

