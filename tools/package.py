#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-3.0
#
# mk-linux419
# Twitter: @fascoder_4
# Email  : m.k419sabuaka@gmail.com
#
# (c) 2019-2020 Fascode Network.
#
# package.py
#

import argparse, os, subprocess, sys, time

repo_list = [
    "core",
    "extra",
    "community",
    "multilib",
    "alter-stable"
]

epilog = """
script mode output:
  latest        The latest package is installed
  noversion     Failed to get the latest version of the package, but the package is installed
  nomatch       The version of the package installed in local does not match one of the latest
  failed        Package not installed
"""

def msg_info(string):
    subprocess.run([f"{script_dir}/msg.sh", "-a", "package.py", "info", string])

def msg_warn(string):
    subprocess.run([f"{script_dir}/msg.sh", "-a", "package.py", "warn", string])

def msg_error(string):
    subprocess.run([f"{script_dir}/msg.sh", "-a", "package.py", "error", string])

def get_from_localdb(package):
    return localdb.get_pkg(package)

def get_from_syncdb(package):
    for db in syncdbs:
        pkg = db.get_pkg(package)

        if pkg is not None: break
    
    return pkg

def compare(package):
    pkg_from_local = get_from_localdb(package)
    pkg_from_sync = get_from_syncdb(package)

    if pkg_from_local is None:
        if args.script:
            return ["failed"]
        else:
            msg_error(f"{package} is not installed.")
            return 1
    elif pkg_from_sync is None:
        if args.script:
            return ["noversion"]
        else:
            msg_warn(f"Failed to get the latest version of {package}.")
            return 1
    
    if pkg_from_local.version == pkg_from_sync.version:
        if args.script:
            return ["latest", pkg_from_local.version]
        else:
            msg_info(f"The latest version of {package} is installed.")
            return 0
    else:
        if args.script:
            return ["nomatch", pkg_from_local.version, pkg_from_sync.version]
        else:
            msg_warn(f"The version of {package} does not match one of the latest.\nLocal: {pkg_from_local.version} Latest: {pkg_from_sync.version}")
            return 1

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))

    parser = argparse.ArgumentParser(
        usage=f"{sys.argv[0]} [option] [package]",
        description="Check the status of the specified package",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=epilog
    )

    parser.add_argument(
        "package",
        type=str,
        help=argparse.SUPPRESS
    )

    parser.add_argument(
        "-s", "--script",
        action="store_true",
        help="Enable script mode"
    )

    args = parser.parse_args()

    try:
        import pyalpm
    except:
        if args.script:
            print("error")
            exit()
        else:
            msg_error("pyalpm is not installed.")
            sys.exit(1)

    handle = pyalpm.Handle(".", "/var/lib/pacman")
    
    for repo in repo_list:
        handle.register_syncdb(repo, 2048)
    
    localdb = handle.get_localdb()
    syncdbs = handle.get_syncdbs()
    
    if args.script:
        result = compare(args.package)
        print(" ".join(result))
    else:
        return_code = compare(args.package)
        sys.exit(return_code)