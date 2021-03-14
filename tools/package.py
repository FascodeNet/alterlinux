#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-3.0
#
# mk-linux419
# Twitter: @fascoder_4
# Email  : m.k419sabuaka@gmail.com
#
# (c) 2019-2021 Fascode Network.
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
exit code:
  0 (latest)           The latest package is installed
  1 (noversion)        Failed to get the latest version of the package, but the package is installed
  2 (nomatch)          The version of the package installed in local does not match one of the latest
  3 (failed)           Package not installed
  4                    Other error
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
        # failed
        if not args.script:
            msg_error(f"{package} is not installed.")
        return 3

    elif pkg_from_sync is None:
        # noversion
        if not args.script:
            msg_warn(f"Failed to get the latest version of {package}.")
        return 1

    if pkg_from_local.version == pkg_from_sync.version:
        # latest
        if not args.script:
            msg_info(f"The latest version of {package} is installed.")
        return 0
    else:
        # nomatch
        if not args.script:
            msg_warn(f"The version of {package} does not match one of the latest.\nLocal: {pkg_from_local.version} Latest: {pkg_from_sync.version}")
        return 2

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
            sys.exit(4)

    handle = pyalpm.Handle(".", "/var/lib/pacman")
    
    for repo in repo_list:
        handle.register_syncdb(repo, 2048)
    
    localdb = handle.get_localdb()
    syncdbs = handle.get_syncdbs()
    
    #if args.script:
    #    result = compare(args.package)
    #    print(" ".join(result))
    #else:
    #    return_code = compare(args.package)
    #    sys.exit(return_code)

    return_code = compare(args.package)
    sys.exit(return_code)
