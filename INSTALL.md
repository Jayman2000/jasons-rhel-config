1. Decide whether you’re going to install [CentOS Stream 9](https://blog.centos.org/2021/12/introducing-centos-stream-9/) or [Red Hat Enterprise Linux 9](https://www.redhat.com/en/about/press-releases/red-hat-defines-new-epicenter-innovation-red-hat-enterprise-linux-9).
1. Make sure that the system you’re going to use meets [RHEL 9’s system requirements](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/performing_a_standard_rhel_9_installation/index#system-requirements-reference_installing-RHEL).
2. Make sure that you have [jasons-kickstart-compiler](https://jasonyundt.website/gitweb?p=jasons-kickstart-compiler;a=summary) installed.
3. Change directory to the root of this repo.
4. Generate a `ks.cfg` file using jasons-kickstart-compiler:
	- If you’re going to install CentOS, run `jasons-kickstart-compiler centos.cfg.j2`
	- If you’re going to install RHEL, run `jasons-kickstart-compiler rhel.cfg.j2`
5. If you don’t already have one, then download and verify an installation ISO:
	- If you’re going to install CentOS, then
		1. Download the ISO from [here](https://mirrors.centos.org/mirrorlist?path=/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso&redirect=1&protocol=https).
		2. Follow [these instructions](https://wiki.centos.org/TipsAndTricks/sha256sum) to verify the ISO files.
	- If you’re going to install RHEL, then
		1. Follow [these instructions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_a_standard_rhel_9_installation/assembly_preparing-for-your-installation_installing-rhel#downloading-a-specific-beta-iso-image_downloading-beta-installation-images) to download a RHEL installation ISO.
		2. Verify the integrity of that image. The download page for the installation DVD should provides its SHA-256 hash. You can run `sha256sum <path-to-iso> | grep <expected-hash>` to verify the integrity of the image.
6. Create a bootable USB drive using the installation DVD image.
7. Make sure that the system that you’re going to do the installation on is configured such that you can press a key to choose to boot from a USB drive. The system must not default to booting the USB drive or else you’ll get stuck in an infinite reboot loop.
8. Follow [these instructions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/starting-kickstart-installations_installing-rhel-as-an-experienced-user#starting-a-kickstart-installation-automatically-using-a-local-volume_starting-kickstart-installations).
9. Once the display manager loads, log in.
10. Open a terminal.
11. Generate an SSH key by running `ssh-keygen -t ed25519`
12. Add the public key to `git@jasonyundt.website`’s `authorized_keys`
