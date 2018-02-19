#!/bin/bash
has_mounted_part() {
        local p
        local sysfsdev=$(echo ${1#/dev/} | sed 's:/:!:g')
        # parse /proc/mounts for mounted devices
        for p in $(awk '$1 ~ /^\/dev\// {gsub("/dev/", "", $1); gsub("/", "!", $1); print $1}' \
                        /proc/mounts); do
                [ "$p" = "$sysfsdev" ] && return 0
                [ -e /sys/block/$sysfsdev/$p ] && return 0
        done
        return 1
}

has_holders() {
        local i
        # check if device is used by any md devices
        for i in $1/holders/* $1/*/holders/*; do
                [ -e "$i" ] && return 0
        done
        return 1
}

is_available_disk() {
        local dev=$1
        local b=$(echo $p | sed 's:/:!:g')

        # check if its a "root" block device and not a partition
        [ -e /sys/block/$b ] || return 1

        # check so it does not have mounted partitions
        has_mounted_part $dev && return 1

        # check so its not part of an md setup
        if has_holders /sys/block/$b; then
                [ -n "$USE_RAID" ] && echo "Warning: $dev is part of a running raid" >&2
                return 1
        fi

        # check so its not an md device
        [ -e /sys/block/$b/md ] && return 1

        return 0
}

find_disks() {
        local p=
        # filter out ramdisks (major=1)
        for p in $(awk '$1 != 1 && $1 ~ /[0-9]+/ {print $4}' /proc/partitions); do
                is_available_disk $p && echo "$p"
        done
}
find_disks
