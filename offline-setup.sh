#!/usr/bin/env bash
# This file is for setup tasks that should succeed even if the system
# has no network connection.

declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name "Jason Yundt"
"${git_config[@]}" user.email "jason@jasonyundt.email"

cd to_install
shopt -s nullglob
# Thanks, evilsoup (<https://superuser.com/users/180990/evilsoup>) for
# this answer: <https://superuser.com/a/600621/954602>
shopt -s globstar
for path in **
do
	if [ -f "$path" ]
	then
		if [[ "$path" == *.sh ]]
		then
			mode="u=rx,g=,o="
		else
			mode="u=r,g=,o="
		fi
		install \
			-D \
			--owner=root \
			--group=root \
			--mode="$mode" \
			"$path" \
			"/$path"
	fi &
done
wait
