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

function echo_err
{
	echo "$@" 1>&2
}

function disable_syncthing
{
	echo_err "Disabling syncthing@jayman to make this error more noticable…"
	if ! systemctl disable syncthing@jayman
	then
		echo_err "Failed to disable syncthing@jayman."
	fi

}

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
potentially_install \
	@"Server with GUI" \
	git \
	keepassxc \
	inkscape \
	PackageKit \
	python \
	syncthing \
	thunderbird \
	virt-manager

sudo -u jayman gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
sudo -u jayman gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

declare -r git_config=( sudo -u jayman git config --global )
"${git_config[@]}" user.name 'Jason Yundt'
"${git_config[@]}" user.email jason@jasonyundt.email
"${git_config[@]}" alias.f 'fetch --all --prune'

readonly syncthing=( sudo -u jayman syncthing )
if [ ! -d ~jayman/.config/syncthing ]
then
	if ! "${syncthing[@]}" generate --no-default-folder
	then
		echo_err "Failed to generate Syncthing config."
	fi
fi

# The --now is necessary. Syncthing needs to be running in order to add devices.
if systemctl enable --now syncthing@jayman
then
	# Syncthing needs a second to start. Wait for Syncthing’s HTTP API to be up…
	api_available=0
	tries=0
	readonly max_tries=60
	readonly seconds_before_retrying=1
	while [ "$tries" -lt "$max_tries" ]
	do
		sleep 1s
		if "${syncthing[@]}" cli show system &> /dev/null
		then
			# The Syncthing HTTP API is now up!
			api_available=1
			break
		fi
		let tries++
	done

	if [ "$api_available" -eq 1 ]
	then
		readonly save_folder_id=syrpl-vpqnk
		folder_ids=( "$save_folder_id" )
		folder_labels=( "Keep Across Linux Distros!" )
		folder_paths=( .save )
		# These two folders are pretty big, so we shouldn’t
		# share them with the VM.
		if ! hostname | grep Jason-Lemur-Pro-VM-Test > /dev/null
		then
			folder_ids[1]=eheef-uq5hv
			folder_labels[1]="Game Data"
			folder_paths[1]="${folder_labels[1]}"

			folder_ids[2]=mjwge-zeznc
			folder_labels[2]="Projects"
			folder_paths[2]="${folder_labels[2]}"
		fi
		if [ "${#folder_ids[@]}" -eq "${#folder_paths[@]}" ] && [ "${#folder_ids[@]}" -eq "${#folder_labels[@]}" ]
		then
			readonly syncthing_config=( "${syncthing[@]}" cli config )
			readonly already_added_folders="$("${syncthing_config[@]}" folders list)"
			for ((i=0; i < "${#folder_ids[@]}"; i++))
			do
				folder_id="${folder_ids[$i]}"
				if ! echo "$already_added_folders" | grep -Fe "$folder_id" > /dev/null
				then
					"${syncthing_config[@]}" folders add \
						--id "$folder_id" \
						--label "${folder_labels[$i]}" \
						--path "~/Documents/Home/Syncthing/${folder_paths[$i]}"
				fi
			done

			readonly test_vm_id=MRLHROA-JB6ZV7Y-QQORSLQ-SQ5DOBW-3DCCF6Q-C4VWYKL-UFI7EDD-B6THXQB  # Jason-Lemur-Pro-VM-Test
			device_ids=(
				OUHZPCW-LMR3UQN-EI7QIIP-I55S4X3-E3RWW2J-6RTQSVU-GYCWC6X-BL35XQE  # Graphical-Test-VM
				7A735CO-FSRRF2I-FN5WRGV-OHGRWHR-TF4Z47H-OJBHRBA-G7CP7BN-FTLXGAX  # Jason-Desktop-Linux
				DAW6JNR-DHBHAVL-42UVJDB-SENEDDQ-OVLHNH3-XOVKDE4-JXVIQ23-GJBG6QZ  # Jason-Desktop-Windows
				HIUQOJU-CNAGZCU-BHAFKP7-2T4WAO3-XUMWZKC-N2ZXQWD-XSGWNZH-WRGEWAP  # Jason-Laptop-Linux
				QZBHFNE-XJWGGY4-6JXYMD3-D3HVGR2-C64BVH2-6M644XU-RSVRGAS-QZ752Q7  # Server
			)
			readonly hostname="$(hostname)"
			if [ "$hostname" != Jason-Lemur-Pro ]
			then
				device_ids+=( 3PGXPGR-OWRBYZG-JQEQH73-XE7LIUP-F6OEYWJ-IC3DLCW-WHNAU3R-G2P6SAM )  # Jason-Lemur-Pro
			fi
			if [ "$hostname" != Jason-Lemur-Pro-VM-Test ]
			then
				device_ids+=( "$test_vm_id" )
			fi
			readonly already_added_devices="$("${syncthing_config[@]}" devices list)"
			for device_id in "${device_ids[@]}"
			do
				if ! echo "$already_added_devices" | grep -Fe "$device_id" > /dev/null
				then
					if ! "${syncthing_config[@]}" devices add --device-id "$device_id"
					then
						echo_err "Failed to add Syncthing device: $device_id."
					fi
				fi
				for ((i=0; i < "${#folder_ids[@]}"; i++))
				do
					folder_id="${folder_ids[$i]}"
					already_added_devices_for_folder="$("${syncthing_config[@]}" folders "$folder_id" devices list)"
					if ! echo "$already_added_devices_for_folder" | grep -Fe "$device_id" > /dev/null
					then
						# Make sure that the save folder is the only one that’s shared with Jason-Lemur-Pro-VM-Test.
						if [ "$device_id" != "$test_vm_id" ] || [ "$folder_id" = "$save_folder_id" ]
						then
							if ! "${syncthing_config[@]}" folders "$folder_id" devices add --device-id "$device_id"
							then
								echo_err "Failed to share a folder ($folder_id) with a device ($device_id)."
							fi
						fi
					fi
				done
			done
		else
			echo_err "The folder_ids, folder_labels and folder_paths array weren’t all the same length. This should never happen."
			disable_syncthing
		fi
	else
		echo_err "syncthing@jayman sucessfully started, but the HTTP API never became available."
		disable_syncthing
	fi
else
	echo_err "Failed to enable syncthing@jayman."
fi

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
