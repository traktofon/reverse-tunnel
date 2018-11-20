reverse-tunnel
==============

Helper scripts to set up and manage reverse SSH tunnels, for
managing client machines behind a NAT etc.

Terminology:
- the client machines will be called `client-001` etc.
- the machine that manages the clients is called `boss`.


Setup on `boss`
---------------

A client machine needs a user account on `boss` in order to
connect to it and open the tunnel. In principle all clients could
share the same account on `boss` but that seems insecure.

To set up this user account for client with id `xyz`, run

    ./add-client.sh xyz

This does the following:
- create the  group `tunnel` for the client accounts (if needed)
- create the client account without shell access
- create an SSH key pair for the client, and install the public key in the client account
- prepare a set of files in the directory `client-xyz`, which should be transferred to the client

In addition, it is recommended to add the following snippet to the OpenSSH
server configuration file `/etc/ssh/sshd_config`:
```
# sshd settings for reverse-tunnel accounts
Match group tunnel
    ChrootDirectory /home/tunnel
    ForceCommand /usr/sbin/nologin
    KbdInteractiveAuthentication no
    PasswordAuthentication no
    PubkeyAuthentication yes
    PermitRootLogin no
    PermitTTY no
    X11Forwarding no
    PermitOpen none
```
and then restart/reload sshd.


Setup on `client-xyz`
---------------------

Transfer the directory `client-xyz` to the client.
Run the script `setup.sh` directly in this directory.
This does the following:
- install the config files into `/etc/tunnel/`
- install a systemd service unit `open-tunnel.service` into `/etc/systemd/system`
- tell systemd to find, enable, and start this unit


Connecting
----------

Once the tunnel is started, from the `boss` machine you can ssh to port 20000+xyz on localhost
to reach `client-xyz`.

