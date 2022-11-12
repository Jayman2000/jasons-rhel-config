1. Make sure that the system you’re going to install Red Hat Enterprise
Linux on meets [RHEL 9’s system requirements](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/performing_a_standard_rhel_9_installation/index#system-requirements-reference_installing-RHEL).
2. Make sure that you have [jasons-kickstart-compiler](https://jasonyundt.website/gitweb?p=jasons-kickstart-compiler;a=summary) installed.
3. Change directory to the root of this repo.
4. Generate a `ks.cfg` file by running `jasons-kickstart-compiler ks.cfg.j2`
5. Make sure that you have a copy of the latest version of the RHEL 9
installation DVD image. If you don’t have a copy, then follow
[these instructions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_a_standard_rhel_9_installation/assembly_preparing-for-your-installation_installing-rhel#downloading-a-specific-beta-iso-image_downloading-beta-installation-images).
6. Verify the integrity of that image. The download page for the installation DVD should provides its SHA-256 hash. You can run `sha256sum <path-to-iso> | grep <expected-hash>` to verify the integrity of the image.
7. Create a bootable USB drive using the installation DVD image.
8. Make sure that the system that you’re going to install RHEL on is configured such that you can press a key to choose to boot from a USB drive. The system must not default to booting the USB drive or else you’ll get stuck in an infinite reboot loop.
9. Follow [these instructions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/starting-kickstart-installations_installing-rhel-as-an-experienced-user#starting-a-kickstart-installation-automatically-using-a-local-volume_starting-kickstart-installations).
10. Once the display manager loads, log in.
11. Open a terminal.
12. Generate an SSH key by running `ssh-keygen -t ed25519`
13. Add the public key to `git@jasonyundt.website`’s `authorized_keys`
