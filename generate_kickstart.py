from crypt import crypt
from getpass import getpass
from sys import stderr

pw = getpass("Root password: ")
if len(pw) <= 5:
    print("WARNING: Short password.")
# The official Red Hat docs recommend using Python’s crypt module to do
# this. See <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user#rootpw-required_kickstart-commands-for-system-configuration>.
pw = crypt(pw)

with open("ks.cfg", 'w') as file:
    file.write(f"""
# The goal of this project is to make it so that I can install RHEL
# completely automatically. I want this kickstart file to fail if user
# interaction is required because I want to know when user interaction
# is required so that I can eliminate it.
cmdline

lang en_US
rootpw --iscrypted {pw}

%packages
@^Server with GUI
%end
"""
    )

print("Successfully generated a new ks.cfg.")
