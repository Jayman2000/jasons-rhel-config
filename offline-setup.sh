#!/usr/bin/env bash
# This file is for setup tasks that should succeed even if the system
# has no network connection.
declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name "Jason Yundt"
"${git_config[@]}" user.email "jason@jasonyundt.email"
