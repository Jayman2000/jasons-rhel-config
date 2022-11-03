#!/usr/bin/env bash
# This file is for setup tasks that should succeed even if the system
# has no network connection.

function copy_and_set_metadata
{
	src="$1"
	dest="$2"
	make_executable="$3"

	touch "$dest"
	chown root:root "$dest"
	chmod u=r,g=,o= "$dest"
	cp --no-preserve=all "$src" "$dest"
	"$make_executable" && chmod u+x "$installation_path"

}

declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name "Jason Yundt"
"${git_config[@]}" user.email "jason@jasonyundt.email"

declare -r installation_path=/usr/local/bin/offline-setup.sh
# Thanks, Hiks Gerganov
# <https://www.baeldung.com/linux/bash-get-location-within-script#bash-script-location>
declare -r this_scripts_path="${BASH_SOURCE}"
if [ "$this_scripts_path" != "$installation_path" ]
then
	copy_and_set_metadata \
		"$this_scripts_path" \
		/usr/local/bin/offline-setup.sh \
		true
fi

declare -r share_directory=/usr/local/share/jasons-rhel-config
mkdir --parents --mode='u=rx,g=,o=' "$share_directory"
chown root:root "$share_directory"

if [ -e ./packages.txt ]
then
	copy_and_set_metadata \
		./packages.txt \
		"$share_directory/packages.txt" \
		false
fi
