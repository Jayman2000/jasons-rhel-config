#!/usr/bin/env bash
# Make sure that we don’t get stuck in a reboot loop.
systemctl set-default graphical.target

sudo dnf install --assumeyes --nobest $(< /usr/local/share/jasons-rhel-config/packages.txt)

# Now that phase 1 (non-PackageKit) updates are done, queue phase 2:
pkcon update --noninteractive --only-download
pkcon_exit_status="$?"

# According to pkcon(1), exit status 5 means “Nothing useful was done.”
# For the purposes of this script, that shouldn’t count as an error.
if [ "$pkcon_exit_status" = 0 ] || [ "$pkcon_exit_status" = 5 ]
then
	pkcon offline-trigger --noninteractive
	pkcon_exit_status="$?"
	if [ "$pkcon_exit_status" = 5 ]
	then
		exit 0
	fi
exit "$pkcon_exit_status"
