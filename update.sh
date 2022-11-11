#!/usr/bin/env bash
cd post_script_payload && ./entry-point
readonly exit_status="$?"
if [ "$exit_status" -eq 0 ]
then
	echo "Reboot to finish updating."
else
	echo "Failed to enqueue updates."
fi
exit "$exit_status"
