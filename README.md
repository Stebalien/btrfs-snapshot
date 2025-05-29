# BTRFS Snapshot

A simple set of scripts and systemd units for taking and managing BTRFS snapshots. There actual project like [Snapper](http://snapper.io/) and [yabsnap](https://github.com/hirak99/yabsnap), but this one does exactly what I need reliably and predictably with no frills, GUIs, etc.

## Installation

You can install this project with a standard make & make install invocation:

```bash
make
sudo make install
```

You should then enable the various units. E.g., to backup your home directory on a schedule, you can run:

```bash
systemctl enable --user --now "$(systemd-escape "$HOME" --template btrfs-snapshot@.timer)"
systemctl enable --user --now "$(systemd-escape "$HOME" --template btrfs-snapshot-cleanup@.timer)"
```

(assuming your home directory is on its own BTRFS subvolume)

## Interval

Snapshots are taken to `$SUBVOL/.backups` every hour by the `btrfs-snapshot@.timer` unit. The interval can be configured by modifying/replacing the timer unit.

## Snapshot Cleaning

Snapshots are cleaned when they're taken:

- All files specified by `$SUBVOL/.backupignore` are removed. This file lists files rooted at `$SUBVOL` with no patterns or globbing for now.
- All directories containing a `CACHEDIR.TAG` file are deleted.
- All git repositories are cleared of ignored files/directories. I.e., `git clean -Xd` is run in every git repository.

## Snapshot Pruning

If the snapshot cleanup unit (`btrfs-snapshot-cleanup@.timer`) is enabled, snapshots will be pruned once a day as follows:

* All snapshots from the last 24 hours are kept.
* One snapshot is kept for each day of the last month.
* One snapshot is kept per week of the last year.
* One snapshot is kept per month forever.
