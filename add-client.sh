#!/bin/bash

BOSS=boss.local # name or IP
PORTBASE=20000
TUNNELGROUP="tunnel"
TUNNELUSERFMT="client-%03d"
TUNNELHOME="/home/$TUNNELGROUP"
SUDO="sudo"

function usage () {
   cat <<EOF
Usage: $0 <client-id>
   where <client-id> is a number (1, 2, 3, ...)
EOF
}

# parse the command line

CLIENTID="$1"
if [ -z "$CLIENTID" ]; then
   usage >&2
   exit 9
fi

set -e

# create the common group

if getent group "$TUNNELGROUP" >/dev/null; then
   echo "Ok, group '$TUNNELGROUP' already exists."
else
   $SUDO groupadd "$TUNNELGROUP"
   echo "Ok, created group '$TUNNELGROUP'."
fi

if [ ! -d "$TUNNELHOME" ]; then
   $SUDO mkdir -p "$TUNNELHOME"
   $SUDO chgrp "$TUNNELGROUP" "$TUNNELHOME"
fi

# create user account for client

TUNNELUSER=$(printf "$TUNNELUSERFMT" "$CLIENTID")
if getent passwd "$TUNNELUSER" >/dev/null; then
   echo "Error, user '$TUNNELUSER' already exists." >&2
   exit 1
fi
$SUDO useradd \
   --base-dir "$TUNNELHOME" \
   --comment "tunnel client $CLIENTID" \
   --gid "$TUNNELGROUP" \
   --create-home --skel skel/ \
   --shell /bin/false \
   "$TUNNELUSER"
echo "Ok, created user '$TUNNELUSER'."

# set up the files for the client

# 1. SSH key pair
cp -a client/ "$TUNNELUSER"/
ssh-keygen -q -t rsa -f "$TUNNELUSER/etc/tunnel/id_rsa" -C "$TUNNELUSER@$(hostname)" -N ""
TMPFILE=$(mktemp)
AUTHKEYFILE="$TUNNELHOME/$TUNNELUSER/.ssh/authorized_keys"
echo -n "restrict,port-forwarding " >> "$TMPFILE"
cat "$TUNNELUSER/etc/tunnel/id_rsa.pub" >> "$TMPFILE"
$SUDO mv "$TMPFILE" "$AUTHKEYFILE" 
$SUDO chown "$TUNNELUSER:$TUNNELGROUP" "$AUTHKEYFILE"
$SUDO chmod 600 "$AUTHKEYFILE"

# 2. tunnel config
PORT=$[PORTBASE+CLIENTID]
sed -i \
   -e "s/BOSS=/BOSS=$BOSS/" \
   -e "s/REMOTEPORT=/REMOTEPORT=$PORT/" \
   -e "s/REMOTEUSER=/REMOTEUSER=$TUNNELUSER/" \
   "$TUNNELUSER/etc/tunnel/config"

# 3. known hosts
cat /etc/ssh/ssh_host_*.pub | while read TYPE PUBKEY COMMENT; do
   echo $BOSS $TYPE $PUBKEY
done > "$TUNNELUSER/etc/tunnel/ssh_known_hosts"

echo "Files for the client are in directory '$TUNNELUSER', please transfer them to the client."

