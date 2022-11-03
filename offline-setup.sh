#!/usr/bin/env bash
# This file is for setup tasks that should succeed even if the system
# has no network connection.
declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name "Jason Yundt"
"${git_config[@]}" user.email "jason@jasonyundt.email"

declare -r installation_path=/usr/local/bin/offline-setup.sh
# Thanks, Hiks Gerganov
# <https://www.baeldung.com/linux/bash-get-location-within-script#bash-script-location>
declare -r this_scripts_path="${BASH_SOURCE}"
if [ "$this_scripts_path" != "$installation_path" ]
then
	touch "$installation_path"
	chown root:root "$installation_path"
	chmod u=r,g=,o= "$installation_path"
	cp --no-preserve=all "$this_scripts_path" "$installation_path"
	chmod u+x "$installation_path"
fi

declare -r share_directory=/usr/local/share/jasons-rhel-config
mkdir --parents --mode='u=rx,g=,o=' "$share_directory"
chown root:root "$share_directory"
