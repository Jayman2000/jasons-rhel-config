1. Make sure that the system you’re going to install Red Hat Enterprise
Linux on meets [RHEL 9’s system requirements](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/performing_a_standard_rhel_9_installation/index#system-requirements-reference_installing-RHEL).
2. Generate a `ks.cfg` file by running `generate_kickstart.py`.
3. Make sure that you have a copy of the latest version of the RHEL 9
installation DVD image.
4. Verify the integrity of that image.
5. Follow [these instructions](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/starting-kickstart-installations_installing-rhel-as-an-experienced-user#starting-a-kickstart-installation-automatically-using-a-local-volume_starting-kickstart-installations).
6. Once the system shuts itself down, remove the install disk.
7. If you’re no longer going to use the disk that has the `OEMDRV` partiton, then remove that disk.
8. Turn the system on.
