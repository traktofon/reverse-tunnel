#!/bin/bash

cp -r etc/tunnel /etc/
cp etc/systemd/system/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable open-tunnel
systemctl start open-tunnel

