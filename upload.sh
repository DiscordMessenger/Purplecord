#!/bin/bash

# uploads the binary to the iPhone
IPHONE_IP="192.168.1.133"
SSH_USER="root"
APP_NAME="Purplecord"
APP_PATH="./.theos/obj/debug/$APP_NAME.app"
SSH_OPTS="-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"

echo "Deploying $APP_NAME to $SSH_USER@$IPHONE_IP..."

scp $SSH_OPTS -r $APP_PATH $SSH_USER@$IPHONE_IP:/Applications
ssh $SSH_OPTS $SSH_USER@$IPHONE_IP <<EOF
chmod -R 755 /Applications/$APP_NAME.app
chown -R root:wheel /Applications/$APP_NAME.app
killall SpringBoard
EOF

