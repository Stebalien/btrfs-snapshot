#!/bin/bash

set -eu
shopt -s nullglob

identity="$(id -u)-$(id -g)"
check_owner() {
    local id mode
    read -r id mode < <(stat "$1" -c "%u-%g %#a")
    # We must own it, and nobody else can write (and no sticky!)
    [[ "$id" == "$identity" ]] && [[ $(( "$mode" & !0755 )) -eq 0 ]]
}

err() {
    local ret=$?
    if [[ $ret -eq 0 ]]; then
        ret=1
    fi
    echo "$@" >&2
    return $ret
}


[[ "$#" -eq 1 ]] || err "Must be called with exactly one argument: the subvolume to snapshot."

backup_dir="./.backups"
temp_dir="${backup_dir}/.temp"
lock_file="${backup_dir}/.lock"

cleanup() {
    # Cleanup any left behind temporary directories
    if [[ -d "${temp_dir}" ]]; then
        if [[ -d "${temp_dir}/snapshot" ]]; then
            btrfs subvolume delete "${temp_dir}/snapshot"  || err "Failed to delete temporary snapshot."
        fi
        rmdir "${temp_dir}" || err "Failed to delete temporary directory."
    fi
}


# Make sure the backup volume exists and that we're the owner.
# We CD into it to avoid TOCTOU issues.
cd "$1" || err "Failed to change directory into the subvolume: $1"
check_owner "." || err "Refusing to snapshot a directory we don't own."

# Check/create the backups directory.
test -d "${backup_dir}" || btrfs subvolume create "${backup_dir}"
check_owner "${backup_dir}" || err "Refusing use a backup dir we don't own."

# Lock
exec 4<> "${lock_file}"
flock -n 4 || err "Failed to take lock."

# Cleanup before doing anything
cleanup
