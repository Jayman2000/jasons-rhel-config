#!/usr/bin/env bash
set -e

function get_field
{
	echo -n "$1" | cut --delimiter=. --fields="$2"
}

cd ansible
for filename in *
do
	target_user="$(get_field "$filename" 2)"
	ansible_file_type="$(get_field "$filename" 3)"

	echo "---"
	echo "Filename: $filename"
	echo "User: $target_user"
	echo "Type: $ansible_file_type"
	echo "---"

	# Having to_run be an array makes our code more robust. It
	# allows us to do
	# 	"${to_run[@]}"
	# which ensures that each item in the array becomes exactly 1
	# word.
	if [ "$ansible_file_type" = playbook ]
	then
		to_run=( ansible-playbook )
	elif [ "$ansible_file_type" = requirements ]
	then
		to_run=(
			ansible-galaxy
			collection
			install
			--requirements-file
		)
	fi
	to_run+=( "$filename" )

	if [ "$USER" = "$target_user" ]
	then
		"${to_run[@]}"
	else
		sudo --user="$target_user" -- "${to_run[@]}"
	fi
done
