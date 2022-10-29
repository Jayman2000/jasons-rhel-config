from collections.abc import Iterable
from crypt import crypt
from getpass import getpass
from pathlib import Path
from re import IGNORECASE, compile as compile_regex
from shlex import quote as shell_quote
from sys import stderr
from typing import Final


CHUNK_DELIMITER : Final = "%end"
NEWLINE : Final = "\n"
PLAYBOOK_FILENAME : Final = "ansible-playbook.yaml"


def echo_chunk(chunk : str, overwrite : bool) -> str:
    return_value = ["echo"]
    if chunk.endswith(NEWLINE):
        chunk = chunk[:-1]
    else:
        return_value.append("-n")
    return_value += (
            shell_quote(chunk),
            ">" if overwrite else ">>",
            '"$dest"'
    )
    return " ".join(return_value)


def shell_commands_to_reproduce_file(path: Path) -> Iterable[str]:
    """
    Note: This will produce a sequence of commands that assumes that the
    dest shell variable has already been initialized.
    """
    # The “newline=''” part helps us reproduce the exact contents of the
    # file located at path. If that file has CRLFs, the reproduction
    # will have CRLFs.
    with path.open(newline='') as file:
        contents = file.read()
    overwrite = True
    chunk_start = 0
    while chunk_start < len(contents):
        # This prevents the script block from inadvertently containing a
        # “%end” (“%end” ends script blocks in kickstart [1]).
        #
        # [1]: <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/kickstart-script-file-format-reference_installing-rhel-as-an-experienced-user#kickstart-file-format_kickstart-script-file-format-reference>
        if contents[chunk_start:].lower().startswith(CHUNK_DELIMITER):
            yield echo_chunk(contents[chunk_start], overwrite)
            chunk_start += 1
        else:
            chunk_end = contents.find(CHUNK_DELIMITER, chunk_start)
            # If the delimiter wasn’t found…
            if chunk_end == -1:
                chunk_end = len(contents)
            yield echo_chunk(contents[chunk_start:chunk_end], overwrite)
            chunk_start = chunk_end
        overwrite = False


org = getpass("Organization id: ")
key = getpass("Activation key: ")
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

rhsm --organization={org} --activation-key="{key}"

ignoredisk --only-use=disk/by-path/virtio-pci-0000:05:00.0
clearpart --all
autopart

lang en_US
rootpw --iscrypted {pw}

%packages
@^Server with GUI
# Requirements for the below post script.
## For systemctl and systemd-path:
systemd
## For ansible-playbook:
ansible-core
%end

%post --log=/root/ks-post.log
# For whatever reason, multi-user.target is the default, even if you
# choose “Server with GUI”.
systemctl set-default graphical.target

dest_dir="$(systemd-path user-shared)/jasons-rhel-config"
mkdir -p "$dest_dir"
dest="$dest_dir/"{shell_quote(PLAYBOOK_FILENAME)}

{NEWLINE.join(shell_commands_to_reproduce_file(Path(PLAYBOOK_FILENAME)))}

ansible-playbook "$dest"
%end

poweroff
"""
    )

print("Successfully generated a new ks.cfg.")
