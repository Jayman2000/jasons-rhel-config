from collections.abc import Iterable
from crypt import crypt
from getpass import getpass
from itertools import chain
from pathlib import Path, PurePosixPath
from re import IGNORECASE, compile as compile_regex
from shlex import quote as shell_quote
from sys import stderr
from typing import Final, Optional


CHUNK_DELIMITER : Final = "%end"
NEWLINE : Final = "\n"


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


def shell_commands_to_reproduce_file(path : Path) -> Iterable[str]:
    """
    path should be relative to this file.
    """
    input_path = path
    output_path = PurePosixPath(path)
    if output_path.is_absolute():
        raise ValueError("output_path should be relative not absolute.")

    set_dest_dir_command = 'dest_dir="$(systemd-path user-shared)/jasons-rhel-config/"'
    if len(path.parts) > 1:  # If the path contains more than just a filename.
        set_dest_dir_command += shell_quote(str(output_path.parent)) + "/"
    yield set_dest_dir_command
    yield 'mkdir -p "$dest_dir"'
    yield 'dest="$dest_dir"' + shell_quote(str(output_path.name))
    # The “newline=''” part helps us reproduce the exact contents of the
    # file located at path. If that file has CRLFs, the reproduction
    # will have CRLFs.
    with input_path.open(newline='') as file:
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


def encrypted_password(username : str) -> str:
    password = getpass(f"Password for {username}: ")
    if len(password) <= 5:
        print("WARNING: Short password.")
    # The official Red Hat docs recommend using Python’s crypt module
    # to do this. See <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user#rootpw-required_kickstart-commands-for-system-configuration>.
    password = crypt(password)
    if '"' in password:
        print(
            "WARNING: Encrypted password contains a quotation mark. "
            + "This will probably result in a kickstart file with "
            + "invalid syntax or a user with an invalid password.",
            file=stderr
        )
    return password



org = getpass("Organization id: ")
key = getpass("Activation key: ")
rootpw = encrypted_password("root")
jaymanpw = encrypted_password("jayman")


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
rootpw --iscrypted {rootpw}
user --name=jayman --iscrypted --password="{jaymanpw}" --groups=wheel

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

""")

    paths = chain(
        (Path("run-ansible.sh"),),
        Path("ansible").glob("**/*.yaml")
    )
    for path in paths:
        for command in shell_commands_to_reproduce_file(path):
            print(command, file=file)

    file.write("""

cd "$(systemd-path user-shared)/jasons-rhel-config"
chmod +x run-ansible.sh
./run-ansible.sh
%end

poweroff
""")

print("Successfully generated a new ks.cfg.")
