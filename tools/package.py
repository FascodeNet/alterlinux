#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-3.0
#
# mk-linux419
# Twitter: @fascoder_4
# Email  : mk419@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# package.py
#

import sys
from argparse import ArgumentParser, RawTextHelpFormatter, SUPPRESS
from os.path import abspath, dirname
from pathlib import Path
from subprocess import run
from typing import Optional

pyalpm_error = False
epilog = """
exit code:
  0 (latest)           The latest package is installed
  1 (noversion)        Failed to get the latest version of the package, but the package is installed
  2 (nomatch)          The version of the package installed in local does not match one of the latest
  3 (failed)           Package not installed
  4                    Other error
"""


try:
    from pyalpm import find_satisfier, Package
    from pycman.config import init_with_config
except:
    pyalpm_error = True


def msg(string: str, level: str) -> None:
    if not args.script:
        run([f"{script_dir}/msg.sh", "-a", "package", "-s", "8", level, string])


def get_from_localdb(package: str) -> Optional[Package]:
    localdb = handle.get_localdb()
    pkg = localdb.get_pkg(package)

    if pkg:
        return pkg
    else:
        for pkg in localdb.search(package):
            if package in pkg.provides:
                return pkg


def get_from_syncdb(package: str) -> Optional[Package]:
    for db in handle.get_syncdbs():
        pkg = db.get_pkg(package)

        if pkg:
            return pkg


def compare(package: str) -> tuple[int,Optional[tuple[str]]]:
    pkg_from_local = get_from_localdb(package)
    pkg_from_sync = get_from_syncdb(pkg_from_local.name) if pkg_from_local else None

    if not pkg_from_local:
        msg(f"{package} is not installed", "error")

        return (3, None)
    elif not pkg_from_sync:
        msg(f"Failed to get the latest version of {package}", "warn")

        return (1, (pkg_from_local.version))

    if pkg_from_local.version == pkg_from_sync.version:
        msg(f"Latest {package} {pkg_from_local.version} is installed", "debug")

        return (0, (pkg_from_local.version))
    else:
        msg(f"The version of {package} does not match one of the latest", "warn")
        msg(f"Local: {pkg_from_local.version} Latest: {pkg_from_sync.version}", "warn")

        return (2, (pkg_from_local.version, pkg_from_sync.version))


if __name__ == "__main__":
    script_dir = dirname(abspath(__file__))

    parser = ArgumentParser(
        usage           = f"{sys.argv[0]} [option] [package]",
        description     = "Check the status of the specified package",
        formatter_class = RawTextHelpFormatter,
        epilog          = epilog
    )

    parser.add_argument(
        "package",
        type = str,
        help = SUPPRESS
    )

    parser.add_argument(
        "-c", "--conf",
        default = Path("/etc/pacman.conf"),
        type    = Path,
        help    = "Path of pacman configuration file"
    )

    parser.add_argument(
        "-s", "--script",
        action = "store_true",
        help   = "Enable script mode"
    )

    args = parser.parse_args()

    if pyalpm_error:
        msg("pyalpm is not installed.", "error")
        sys.exit(4)

    handle = init_with_config(str(args.conf))

    exit_code, info = compare(args.package)

    if args.script and info:
        print(info)

    sys.exit(exit_code)
