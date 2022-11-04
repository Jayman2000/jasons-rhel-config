#!/usr/bin/env bash
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
                        mode="u=x,g=,o="
                else
                        mode="u=r,g=,o="
                fi
                sudo install \
                        -D \
                        --owner=root \
                        --group=root \
                        --mode="$mode" \
                        "$path" \
                        "/$path"
        fi
done

sudo systemctl set-default updates-phase-1.target
