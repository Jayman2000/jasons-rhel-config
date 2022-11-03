#!/usr/bin/env bash
set -x

/usr/local/bin/offline-setup.sh
/usr/local/share/jasons-rhel-config/online-setup.sh

# Make sure that we don’t get stuck in a reboot loop.
systemctl set-default graphical.target

echo "pip:"
sudo -u jayman bash -lc 'pipupgrade --user --yes --pip' &&
	sudo -u jayman bash -lc 'pipupgrade --user --yes --self' &&
	sudo -u jayman bash -lc 'pipupgrade --user --yes'

# Now that phase 1 (non-PackageKit) updates are done, queue phase 2:
echo "pkcon:"
pkcon update --noninteractive --only-download &&
	pkcon offline-trigger --noninteractive
pkcon_exit_status="$?"

if [ "$pkcon_exit_status" = 5 ]
then
	# According to pkcon(1), exit status 5 means “Nothing useful was
	# done.” For the purposes of this script, that shouldn’t count
	# as an error.
	exit 0
else
	exit "$pkcon_exit_status"
fi
