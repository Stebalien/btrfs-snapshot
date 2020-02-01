# BTRFS Snapshot

A simple set of scripts and systemd units for taking and managing BTRFS snapshots.

* Snapshots are saved to $SUBVOL/.backups every hour.
* Every day, the cleanup unit prunes snapshots based on how old they are:
  * All snapshots from the last 24 hours are kept.
  * One snapshot is kept for each day of the last month.
  * One snapshot is kept per week of the last year.
  * One snapshot is kept per month forever.

Note: These units can be enabled independently.
