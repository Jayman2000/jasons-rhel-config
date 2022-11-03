#!/usr/bin/env bash
# This file is for setup tasks that should succeed even if the system
# has no network connection.

function copy_and_set_metadata
{
	local -r src="$1"
	local -r dest="$2"
	local -r make_executable="$3"

	touch "$dest"
	chown root:root "$dest"
	chmod u=r,g=,o= "$dest"
	cp --no-preserve=all "$src" "$dest"
	"$make_executable" && chmod u+x "$dest"

}

function install_files
{
	local -r dest="$1"
	while [ "$#" -gt 1 ]
	do
		shift
		local filename="$1"
		if [[ "$filename" == *.sh ]]
		then
			executable=true
		else
			executable=false
		fi

		echo "$filename" "$executable"

		if [ -e "$filename" ]
		then
			copy_and_set_metadata \
				"$filename" \
				"$dest/$filename" \
				"$executable"
		fi
	done
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

install_files \
	"$share_directory" \
	packages.txt \
	online-setup.sh \
	updates-phase-1.sh

install_files \
	/etc/systemd/system/ \
	updates-phase-1.service \
	updates-phase-1.target
