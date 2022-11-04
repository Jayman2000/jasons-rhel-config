from base64 import standard_b64encode
from collections.abc import Iterable
from crypt import crypt
from getpass import getpass
from io import BytesIO
from itertools import chain
from pathlib import Path
from shlex import quote as shell_quote
from sys import stderr
from tarfile import open as open_tarfile
from typing import Final


def encrypted_password(username : str) -> str:
    password = getpass(f"Password for {username}: ")
    if len(password) <= 5:
        print("WARNING: Short password.", file=stderr)
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


def files_in_directory_recursive(directory : Path) -> Iterable[Path]:
    for path in directory.glob("**/*"):
        if path.is_file():
            yield path


PACKAGES : Final = Path(
        "to_install",
        "usr",
        "local",
        "share",
        "jasons-rhel-config",
        "packages.txt"
)
organization_id = getpass("Organization id: ")
activation_key = getpass("Activation key: ")
root_password = encrypted_password("root")
jayman_password = encrypted_password("jayman")
with PACKAGES.open() as packages_file:
    packages = packages_file.read()

# Credit goes to decaf (https://stackoverflow.com/users/1159217/decaf)
# for this idea: <https://stackoverflow.com/a/15858237/7593853>
tar_data = BytesIO()
with open_tarfile(fileobj=tar_data, mode='w') as tar:
   for file_to_add in chain(
           (Path("queue-update.sh"),),
           files_in_directory_recursive(Path("to_install"))
    ):
       tar.add(file_to_add)
b64_tar_data : str = standard_b64encode(tar_data.getvalue()).decode()
if "%end" in b64_tar_data:
    print("ERROR: encoded data contains “%end”. This should never happen.", file=stderr)


with open("ks.cfg", 'w') as kickstart_file:
    kickstart_file.write(f"""
# The goal of this project is to make it so that I can install RHEL
# completely automatically. I want this kickstart file to fail if user
# interaction is required because I want to know when user interaction
# is required so that I can eliminate it.
cmdline

rhsm --organization={organization_id} --activation-key="{activation_key}"

ignoredisk --only-use=disk/by-path/virtio-pci-0000:05:00.0
clearpart --all
autopart

lang en_US
rootpw --iscrypted {root_password}
user --name=jayman --iscrypted --password="{jayman_password}" --groups=wheel

%packages
{packages}
@^Server with GUI
# Requirements for the below post script.
## For systemctl:
systemd
%end

%post --log=/root/ks-post.log
declare -r temporary_directory="$(mktemp -d)"
cd "$temporary_directory"
echo -n {shell_quote(b64_tar_data)} | base64 -d | tar -x
./queue-update.sh
cd /
rm -rf "$temporary_directory"
%end

poweroff
""")

print("Successfully generated a new ks.cfg.")
