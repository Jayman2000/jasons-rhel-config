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

readonly hostname="$(hostname)"

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

function set_up_epel_rhel
{
	potentially_install subscription-manager
	# These commands came from the installation instructions for
	# EPEL on RHEL 9:
	# <https://docs.fedoraproject.org/en-US/epel/#_rhel_9>
	subscription-manager repos --enable "codeready-builder-for-rhel-9-$(arch)-rpms"
	"${dnf_install[@]}" 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm'
}

function set_up_epel_centos
{
	# These commands came from the installation instructions for
	# EPEL on CentOS Stream 9:
	# <https://docs.fedoraproject.org/en-US/epel/#_centos_stream_9>
	dnf config-manager --set-enabled crb
	"${dnf_install[@]}" epel-release epel-next-release
}

function test_system
{
	echo "$hostname" | grep -i test > /dev/null
	return "$?"
}

function should_add_syncthing_device
{
	if [ ! -v already_added_devices ]
	then
		echo_err \
			"ERROR: should_add_syncthing_device() was" \
			"called before already_added_devices was set." \
			"This should never happen."
	fi
	if [ "$#" -ne 2 ]
	then
		echo_err \
			"ERROR: should_add_syncthing_devices() was" \
			"called with $# arguments. It should only" \
			"ever be called with 2 arguments."
	fi
	local device_id="$1"
	local device_hostname="$2"

	( ! echo "$already_added_devices" | grep -Fe "$device_id" > /dev/null ) \
		&& [ "$hostname" != "$device_hostname" ]
	return "$?"
}

if ! rpm -q epel-release
then
	if cat /etc/system-release | grep -P '^Red Hat Enterprise Linux' > /dev/null
	then
		set_up_epel_rhel
	else
		set_up_epel_centos
	fi
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
		if ! test_system
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


			device_ids=( )
			device_hostnames=( )

			device_ids+=( WEHPXTB-ZFPDAJ4-NRSLXVG-FOJENRH-WVNGVKK-7YUUJUZ-OM7CUG7-NJFTKQU )
			device_hostnames+=( Graphical-Test-VM )

			device_ids+=( KADJ4K2-U73CLZH-L6ADY3J-FRFPVUH-HQF3NQZ-472YGQU-K43NZWS-LLDX5AX )
			device_hostnames+=( Jason-Desktop-Linux )

			device_ids+=( IJ7DGZZ-HEOL43C-4RCWITD-QCATRWR-HPTWFR3-XTTYEZW-QUV4CBL-5P7AGQF )
			device_hostnames+=( Jason-Desktop-Windows )

			device_ids+=( HIUQOJU-CNAGZCU-BHAFKP7-2T4WAO3-XUMWZKC-N2ZXQWD-XSGWNZH-WRGEWAP )
			device_hostnames+=( Jason-Laptop-Linux )

			device_ids+=( QZBHFNE-XJWGGY4-6JXYMD3-D3HVGR2-C64BVH2-6M644XU-RSVRGAS-QZ752Q7 )
			device_hostnames+=( Server )

			device_ids+=( J5UN6OL-YTQM5PO-ARP3I77-EZIHIXS-Y4QNWDS-OSUTZLP-TES6TDP-TCOAKAV )
			device_hostnames+=( Jason-Lemur-Pro )

			device_ids+=( DACPZKJ-GMT2UG7-WDYKPBX-KOK3LEF-BLTKCEM-FJGP2L6-7GXB24S-2GPLQQC )
			device_hostnames+=( Jason-Lemur-Pro-VM-Test-CentOS )

			readonly device_ids device_hostnames


			readonly already_added_devices="$("${syncthing_config[@]}" devices list)"
			for (( device_index=0; device_index < "${#device_ids[@]}"; device_index++ ))
			do
				device_id="${device_ids[$device_index]}"
				device_hostname="${device_hostnames[$device_index]}"

				if should_add_syncthing_device "$device_id" "$device_hostname"
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
