#!/usr/bin/env bash
# This file is for setup tasks that require an Internet connection.

# --nobest prevents DNF from trying to upgrade packages that are already
# installed.
sudo dnf \
	--assumeyes \
	--nobest \
	install \
	$(cat /usr/local/share/jasons-rhel-config/packages.txt)
