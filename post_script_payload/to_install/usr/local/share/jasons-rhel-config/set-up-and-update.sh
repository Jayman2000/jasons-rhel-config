#!/usr/bin/env bash
# Make sure that we don’t get stuck in a reboot loop.
systemctl set-default graphical.target
if [ "$?" != 0 ]
then
	# For what ever reason, we couldn’t set the default target to
	# graphical.target. Hopefully, the _default_ default target is
	# good enough.
	rm /etc/systemd/default.target
fi
