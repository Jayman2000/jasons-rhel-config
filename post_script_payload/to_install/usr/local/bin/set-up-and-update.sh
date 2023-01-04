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

declare -r dnf_install=( dnf install --nobest --assumeyes )
function potentially_install
{
	local to_install=( )
	for package in "$@"
	do
		# If the package isn’t installed…
		if ! rpm -q "$package"
		then
			to_install+=( "$package" )
		fi
	done
	if [ "${#to_install[@]}" -gt 0 ]
	then
		"${dnf_install[@]}" "${to_install[@]}"
	fi
}

function pkcon_exit_status_ok
{
	# According to pkcon(1), exit status 5 means “Nothing useful was
	# done.” For the purposes of this script, that shouldn’t count
	# as an error.
	[ "$*" = 0 ] || [ "$*" = 5 ]
}

potentially_install subscription-manager
if ! rpm -q epel-release
then
	# These commands came from the installation instructions for
	# EPEL on RHEL 9:
	# <https://docs.fedoraproject.org/en-US/epel/#_rhel_9>
	subscription-manager repos --enable "codeready-builder-for-rhel-9-$(arch)-rpms"
	"${dnf_install[@]}" 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm'
fi
potentially_install git PackageKit @"Server with GUI" python

sudo -u jayman gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name 'Jason Yundt'
"${git_config[@]}" user.email jason@jasonyundt.email
"${git_config[@]}" alias.f 'fetch --all --prune'

pkcon refresh --noninteractive
es="$?"

if pkcon_exit_status_ok "$es"
then
	pkcon update --noninteractive --only-download
	es="$?"
	if pkcon_exit_status_ok "$es" && pkcon offline-get-prepared
	then
		pkcon offline-trigger --noninteractive
		es="$?"
	fi

fi

if pkcon_exit_status_ok "$es"
then
	exit 0
else
	exit "$es"
fi
