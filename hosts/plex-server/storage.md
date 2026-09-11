# Plex-server storage prerequisites (T-001)

Evidence was collected through authorized read-only access on 2026-09-11. No
configuration, schedule, database data, SMART setting, mount, or production
state was changed. The T-001 inventory is sufficient to continue code
implementation; it does not establish production deployment or standby
acceptance.

## Verified observations

### Filesystems, scope, and capacity

`constants.disks` stable ATA whole-disk links match the privileged SMART
identities (not volatile `/dev/sdX` names):

| Role   | Device / stable identity                                | Model / serial                                                    | Mount                                                               |
| ------ | ------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| root   | `sda` / `ata-Samsung_SSD_860_EVO_250GB_S3YJNX0KA37441A` | Samsung SSD 860 EVO 250GB / `S3YJNX0KA37441A`                     | `/` (`sda2`, UUID `e2766e63-46f5-4ddd-8bd6-36572d615226`)           |
| media  | `sdb` / `ata-WDC_WD80EFPX-68C4ZN0_WD-RD3XYHLG`          | WDC WD80EFPX-68C4ZN0 / `WD-RD3XYHLG`                              | `/mnt/media` (`sdb1`, UUID `8059153a-838e-4bfd-82aa-5831c1f5047a`)  |
| backup | `sdc` / `ata-ST1000DM010-2EP102_ZN10VPN1`               | Seagate ST1000DM010-2EP102 / `ZN10VPN1` (FW `CC43`, CMR 7200 rpm) | `/mnt/backup` (`sdc1`, UUID `20af820e-357e-49fe-a62c-38b6039bffc5`) |

All three are SATA physical disks; `zram0` is not physical. `/var/log` and
`/var/lib` resolve to root (`sda2`), physically separate from both HDDs. Prior
inventory verified that prospective `/var/log/sa`, `/var/lib/disk-activity`,
`/var/lib/immich-backup`, and `/var/lib/immich-backup/dumps` are absent; their
existing parents are on root. This does not claim that any path was created.

| Filesystem    | Size | Used | Available |
| ------------- | ---: | ---: | --------: |
| `/`           | 228G |  40G |      176G |
| `/mnt/media`  | 7.3T | 2.1T |      4.9T |
| `/mnt/backup` | 916G |  28K |      870G |

At inventory, `/mnt/backup` contained only `lost+found`; `/mnt/backup/immich`
was not present.

`findmnt -R /mnt/media` found only `sdb1` with the recorded UUID; no nested
mounts were reported. `du -sx --block-size=1 /mnt/media/immich` reports
26,548,133,888 bytes (~24.7 GiB allocated). All Immich media is under
`/mnt/media/immich`: there are no external libraries or relocated folders. This
does not represent sparse expanded sizes. The configured tree contains `upload`, `library`, `encoded-video`, `thumbs`,
`profile`, and `backups`, each with a regular `.immich` marker. The full
`-xdev` symlink scan emitted no paths or errors.

The 24.7 GiB media source and 45 MB validated dump have ample nominal capacity
headroom on `/mnt/backup` (870G free) and root (176G free). This does not use
the media filesystem's total 2.1T used as backup scope. Operational capacity
checks before a copy remain required.

### SMART and smartd

Privileged operator evidence at 2026-09-11 10:52:55 CEST (epoch
`1789116775`; smartctl 7.5, kernel 6.18.41) verified all three identities.
Each is `device.type: sat`, protocol ATA, SMART enabled and available, overall
health passed, exit status 0, with self-test status value 0
(inactive/completed without error). SMART error count is 0 and each 21-entry
self-test log has `error_count_total` 0, with successful short and extended
history.

| Role   | Power / advertised tests                     | Counters                                                                                                         | Temperature | Latest short / extended |
| ------ | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ----------- | ----------------------- |
| root   | ACTIVE or IDLE; 2 / 85 min                   | 27,285 power-on hours; 1,774 cycles; reallocated 0                                                               | 30 C        | 27,276 h / 27,135 h     |
| media  | ACTIVE or IDLE; 2 / 770 min                  | 4,625 hours; 15 start/stop and cycles; 3,015 load cycles; reallocated/pending/offline-uncorrectable/CRC 0        | 42 C        | 4,617 h / 4,487 h       |
| backup | `IDLE_A` (ATA 129, not STANDBY); 1 / 106 min | 27,682 hours; 4,204 start/stop; 1,819 cycles; 4,853 load cycles; reallocated/pending/offline-uncorrectable/CRC 0 | 46 C        | 27,673 h / 27,533 h     |

Root has historical `CRC_Error_Count` 21; this is not proof of a current cable
fault. Backup's ATA power query works while awake, but an actual standby
transition, non-waking query while asleep, and weekly sleep behavior remain
**UNVERIFIED**.

Existing smartd policy is unchanged. Operator journals for September 10 and 11
show scheduled short tests at 02:04:32 on `sda`, `sdb`, and `sdc`, with all
successfully reported at approximately 02:34:32/33. This confirms coverage of
all inventoried disks; the ~30-minute reporting interval is polling, not a
test-duration measurement.

For later T-005 only, the deadline formula `max(2 * advertised, advertised +
60)` gives initial bounds of 61 minutes (short) and 212 minutes (long). These
are neither measured durations nor activated configuration.

### Runtime metadata and native dumps

Immich server version is `3.1.0`. Read-only PostgreSQL evidence reports server
`17.11`, database size 223 MB, and `TimeZone` `GMT`; host timezone is
`Europe/Paris`. These are distinct: do not change the PostgreSQL timezone or
infer the Immich scheduler timezone from either. Installed extensions are
`cube` 1.5, `earthdistance` 1.2, `pg_trgm` 1.6, `plpgsql` 1.0, `unaccent` 1.1,
`uuid-ossp` 1.1, `vchord` 1.1.1, and `vector` 0.8.6.

The native-backup UI is enabled with cron `0 2 * * *` and retention `14`.
Fourteen finalized routine native dumps are present from 2026-08-29 through
2026-09-11 inclusive, with displayed daily mtimes around 02:00:08. The
observed daily 02:00 `+0200` dump time is consistent with the host timezone,
but the effective application timezone is not fully confirmed; PostgreSQL
remains `GMT` and must not be changed.

The validated reference dump is
`immich-db-backup-20260911T020000-v3.1.0-pg17.11.sql.gz`: it is a regular,
non-symlink file; `gzip` exited 0; SHA-256 is
`f523d38272a9745b10ab95fcef0aef52eab3c3224b659ddc5e4a8b4a07fc5c54`; size is
45,477,496 bytes; and mtime is `2026-09-11 02:00:07.991828271 +0200`. This is
an existing validated routine dump used only as the reference, not a newly
fabricated or triggered job.

Gzip integrity does not prove a restore or SQL semantic scope. The pinned
native implementation uses a single-database `pg_dump` per the existing plan;
no cluster dump was attempted. A manual native-job rehearsal is deferred by the
user until the first supervised backup. Future runtime must select a fresh,
finalized routine dump by pattern, never hardcode this reference filename.

## Repeatable read-only collection

The original unprivileged SMART `smartctl -n standby -j -a` and `-c` attempts
for `sda`, `sdb`, and `sdc` were denied opening the devices. They are historical
access denials, not current SMART unknowns. Privileged collection used
standby-safe ATA SMART queries; no query starts a test or changes power state.
Useful read-only checks include:

```sh
findmnt -R /mnt/media
findmnt -rn -M /mnt/backup -o SOURCE,UUID,TARGET
df -hPT / /mnt/media /mnt/backup
du -sx --block-size=1 /mnt/media/immich
find /mnt/media/immich -xdev -type l -print
sudo -u postgres psql -h /run/postgresql -d immich -X -Atqc "SELECT current_setting('server_version'), current_setting('TimeZone'), pg_size_pretty(pg_database_size(current_database())); SELECT extname || ':' || extversion FROM pg_extension ORDER BY extname;"
smartd_exe="$(readlink -f /proc/$(systemctl show -p MainPID --value smartd.service)/exe)"
"${smartd_exe%/sbin/smartd}/sbin/smartctl" -n standby -j -a /dev/disk/by-id/ata-ST1000DM010-2EP102_ZN10VPN1
```

## Pending prerequisites and fail-closed gate

The effective application timezone remains unconfirmed, and the manual native
job rehearsal remains deferred until the first supervised backup. Standby
acceptance remains for later validation. Gzip integrity alone does not prove
restorability or SQL semantic scope.

Later deployment must fail closed as appropriate and account for propagated
deletions and for a live rsync copy after a database-first dump being
non-atomic; neither demonstrates restorability.
