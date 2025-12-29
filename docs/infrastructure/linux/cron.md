---
title: Cron - Comprehensive Guide
description: "Complete guide to using cron for job scheduling in Linux: syntax, examples, best practices, and troubleshooting."
ms.topic: reference
ms.date: 2025-11-29
---

Cron is a time-based job scheduler in Unix-like operating systems. It enables users to schedule jobs (commands or scripts) to run periodically at fixed times, dates, or intervals.

## Quick Start

- Cron runs as a daemon (crond) and executes scheduled tasks based on crontab files
- Each user has their own crontab, plus system-wide crontabs exist
- Jobs run in a minimal environment - always use full paths
- Standard output and errors are emailed to the user (configure MAILTO)

## Cron Syntax

The crontab format consists of six fields:

```text
* * * * * command-to-execute
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, where 0 and 7 are Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Field Values

- `*` - Any value (every minute, hour, day, etc.)
- `,` - List of values (1,3,5)
- `-` - Range of values (1-5)
- `/` - Step values (*/5 means every 5 units)
- `?` - No specific value (some implementations)

### Special Strings

Modern cron implementations support these shortcuts:

- `@reboot` - Run once at startup
- `@yearly` or `@annually` - Run once a year (0 0 1 1 \*)
- `@monthly` - Run once a month (0 0 1 \* \*)
- `@weekly` - Run once a week (0 0 \* \* 0)
- `@daily` or `@midnight` - Run once a day (0 0 \* \* \*)
- `@hourly` - Run once an hour (0 \* \* \* \*)

## Common Cron Patterns

### Basic Scheduling

```bash
# Run every minute
* * * * * /path/to/script.sh

# Run every 5 minutes
*/5 * * * * /path/to/script.sh

# Run every hour at minute 30
30 * * * * /path/to/script.sh

# Run every day at 2:30 AM
30 2 * * * /path/to/script.sh

# Run every Monday at 9:00 AM
0 9 * * 1 /path/to/script.sh

# Run on the 1st of every month at midnight
0 0 1 * * /path/to/script.sh
```

### Advanced Scheduling

```bash
# Run every weekday (Mon-Fri) at 6:00 AM
0 6 * * 1-5 /path/to/backup.sh

# Run every 15 minutes during business hours (9 AM - 5 PM)
*/15 9-17 * * * /path/to/check.sh

# Run at multiple specific times
0 9,12,18 * * * /path/to/script.sh

# Run every quarter (Jan, Apr, Jul, Oct) on the 1st at midnight
0 0 1 1,4,7,10 * /path/to/quarterly-report.sh

# Run twice a day (6 AM and 6 PM)
0 6,18 * * * /path/to/script.sh

# Run every 10 minutes except during the hour of 3 AM
*/10 0-2,4-23 * * * /path/to/script.sh
```

## Managing Crontabs

### User Crontabs

```bash
# Edit current user's crontab
crontab -e

# List current user's crontab
crontab -l

# Remove current user's crontab
crontab -r

# Edit another user's crontab (requires root)
sudo crontab -u username -e

# List another user's crontab
sudo crontab -u username -l
```

### System Crontabs

System-wide crontabs are located in:

- `/etc/crontab` - Main system crontab
- `/etc/cron.d/` - Directory for system cron jobs
- `/etc/cron.hourly/` - Scripts run hourly
- `/etc/cron.daily/` - Scripts run daily
- `/etc/cron.weekly/` - Scripts run weekly
- `/etc/cron.monthly/` - Scripts run monthly

System crontab format includes a username field:

```bash
# /etc/crontab format
# minute hour day month weekday user command
30 2 * * * root /usr/local/bin/backup.sh
```

## Environment Variables

Cron jobs run with a minimal environment. Set variables at the top of your crontab:

```bash
# Set shell (default is /bin/sh)
SHELL=/bin/bash

# Set PATH for commands
PATH=/usr/local/bin:/usr/bin:/bin

# Email results to this address (or set to "" to disable)
MAILTO=admin@example.com

# Set HOME directory
HOME=/home/username

# Custom environment variables
API_KEY=your-secret-key

# Now define your cron jobs
0 2 * * * /path/to/backup.sh
```

## Best Practices

### Use Full Paths

Always use absolute paths for commands and scripts:

```bash
# Good
0 2 * * * /usr/bin/python3 /home/user/scripts/backup.py

# Bad - may not work
0 2 * * * python3 backup.py
```

### Redirect Output

Capture output and errors for debugging:

```bash
# Redirect stdout and stderr to a log file
0 2 * * * /path/to/script.sh >> /var/log/script.log 2>&1

# Redirect only errors
0 2 * * * /path/to/script.sh 2>> /var/log/script-errors.log

# Discard all output
0 2 * * * /path/to/script.sh > /dev/null 2>&1

# Send output to logger (syslog)
0 2 * * * /path/to/script.sh 2>&1 | logger -t myscript
```

### Locking to Prevent Overlaps

Prevent multiple instances from running simultaneously:

```bash
# Using flock (file locking)
* * * * * /usr/bin/flock -n /tmp/myjob.lock /path/to/script.sh

# Using a PID file in the script
0 */4 * * * /path/to/script-with-pidfile.sh
```

Example script with PID file:

```bash
#!/bin/bash
PIDFILE=/var/run/myscript.pid

if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "Script already running"
    exit 1
fi

echo $$ > "$PIDFILE"
trap "rm -f $PIDFILE" EXIT

# Your script logic here
# ...
```

### Testing Cron Jobs

```bash
# Test the command directly first
/path/to/script.sh

# Set a temporary cron job to run every minute for testing
* * * * * /path/to/test-script.sh >> /tmp/test.log 2>&1

# Check cron daemon is running
systemctl status cron       # Debian/Ubuntu
systemctl status crond      # RHEL/CentOS

# Restart cron daemon
sudo systemctl restart cron
```

### Security Considerations

```bash
# Restrict crontab access - allow only specific users
# Add usernames to /etc/cron.allow (one per line)
echo "username" | sudo tee -a /etc/cron.allow

# Deny specific users
# Add usernames to /etc/cron.deny
echo "baduser" | sudo tee -a /etc/cron.deny

# Set proper permissions on scripts
chmod 700 /path/to/script.sh
chown user:user /path/to/script.sh
```

## Common Use Cases

### Backups

```bash
# Daily database backup at 2 AM
0 2 * * * /usr/bin/mysqldump -u root -p'password' mydb > /backup/mydb_$(date +\%Y\%m\%d).sql

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 /usr/local/bin/full-backup.sh

# Hourly incremental backup
0 * * * * /usr/local/bin/incremental-backup.sh
```

### System Maintenance

```bash
# Clear temporary files daily at midnight
0 0 * * * find /tmp -type f -mtime +7 -delete

# Update package cache daily
0 3 * * * apt-get update -q > /dev/null 2>&1

# Rotate logs weekly
0 0 * * 0 /usr/sbin/logrotate /etc/logrotate.conf

# Check disk space every 6 hours
0 */6 * * * /usr/local/bin/check-disk-space.sh
```

### Monitoring and Alerts

```bash
# Check website availability every 5 minutes
*/5 * * * * /usr/local/bin/check-website.sh

# Monitor system resources every 10 minutes
*/10 * * * * /usr/local/bin/monitor-resources.sh

# Send daily system report
0 8 * * * /usr/local/bin/daily-report.sh | mail -s "Daily Report" admin@example.com
```

### Data Processing

```bash
# Process log files hourly
0 * * * * /usr/local/bin/process-logs.sh

# Generate reports at end of business day
0 18 * * 1-5 /usr/local/bin/generate-reports.sh

# Import data every 30 minutes during business hours
*/30 9-17 * * * /usr/local/bin/import-data.sh
```

## Troubleshooting

### Check Cron Logs

```bash
# Debian/Ubuntu
grep CRON /var/log/syslog
tail -f /var/log/syslog | grep CRON

# RHEL/CentOS
grep CRON /var/log/cron
tail -f /var/log/cron

# Check for cron execution
journalctl -u cron -f
```

### Common Issues

**Job not running:**

- Verify cron daemon is running: `systemctl status cron`
- Check syntax: Use [crontab.guru](https://crontab.guru) for validation
- Ensure script has execute permissions: `chmod +x script.sh`
- Check user has crontab access: `/etc/cron.allow` and `/etc/cron.deny`
- Verify environment variables and paths

**Script works manually but not via cron:**

- Add `set -x` to script for debugging
- Specify full paths to all commands
- Set PATH variable in crontab
- Check for interactive shell dependencies
- Redirect output to see errors: `>> /tmp/debug.log 2>&1`

**Email not working:**

- Install mail utility: `apt-get install mailutils`
- Configure MAILTO variable
- Check mail logs: `/var/log/mail.log`
- Verify MTA is configured

**Wrong timezone:**

- Set TZ variable: `TZ=America/New_York`
- Check system timezone: `timedatectl`
- Cron uses system timezone by default

### Debugging Template

```bash
# Add to top of crontab for debugging
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=your-email@example.com

# Temporary debug job - runs every minute
* * * * * date >> /tmp/cron-debug.log 2>&1
* * * * * echo "PATH=$PATH" >> /tmp/cron-debug.log 2>&1
* * * * * /usr/bin/env >> /tmp/cron-debug.log 2>&1
```

## Cron Alternatives

### Systemd Timers

Modern alternative to cron on systemd-based systems:

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

Enable and start:

```bash
sudo systemctl enable backup.timer
sudo systemctl start backup.timer
sudo systemctl list-timers
```

### Anacron

For systems that aren't always on (desktops/laptops):

```bash
# /etc/anacrontab
# period delay job-id command
1 5 daily-backup /usr/local/bin/backup.sh
7 10 weekly-update /usr/local/bin/update.sh
@monthly 15 monthly-cleanup /usr/local/bin/cleanup.sh
```

## Advanced Examples

### Dynamic Scheduling with Variables

```bash
# Run at random time between 2-4 AM (prevent server load spikes)
RANDOM_MINUTE=$(shuf -i 0-59 -n 1)
$RANDOM_MINUTE 2-4 * * * /path/to/script.sh

# Use variables for scheduling
BACKUP_HOUR=2
BACKUP_MINUTE=30
$BACKUP_MINUTE $BACKUP_HOUR * * * /usr/local/bin/backup.sh
```

### Conditional Execution

```bash
# Run only on first Monday of the month
0 9 1-7 * 1 /path/to/monthly-monday.sh

# Run only if system load is low
* * * * * [ $(uptime | awk '{print $10}' | cut -d',' -f1 | cut -d'.' -f1) -lt 2 ] && /path/to/script.sh

# Run only on weekdays, business hours
0 9-17 * * 1-5 /path/to/business-hours.sh
```

### Chained Jobs

```bash
# Run second job only if first succeeds
0 2 * * * /path/to/job1.sh && /path/to/job2.sh

# Run cleanup regardless of job success/failure
0 2 * * * /path/to/job.sh; /path/to/cleanup.sh
```

## Tools and Utilities

### Useful Commands

```bash
# Validate cron syntax online
# Visit: https://crontab.guru

# List all users with crontabs
sudo ls -la /var/spool/cron/crontabs/

# Show next scheduled runs (requires cron parser)
crontab -l | grep -v '^#' | cron-parser

# Check cron logs in real-time
sudo tail -f /var/log/syslog | grep CRON
```

### Cron Helpers

```bash
# Install cron-utils for better logging
sudo apt-get install cron-utils

# Use chronic from moreutils to suppress output unless there's an error
0 2 * * * chronic /path/to/script.sh

# Use ts from moreutils to add timestamps to output
0 2 * * * /path/to/script.sh | ts '[%Y-%m-%d %H:%M:%S]' >> /var/log/script.log
```

## Quick Reference

### Time Specification Cheat Sheet

| Schedule | Cron Expression | Special String |
|----------|----------------|----------------|
| Every minute | `* * * * *` | - |
| Every 5 minutes | `*/5 * * * *` | - |
| Every hour | `0 * * * *` | `@hourly` |
| Every day at midnight | `0 0 * * *` | `@daily` or `@midnight` |
| Every Sunday at midnight | `0 0 * * 0` | `@weekly` |
| First day of month at midnight | `0 0 1 * *` | `@monthly` |
| January 1st at midnight | `0 0 1 1 *` | `@yearly` or `@annually` |
| Every reboot | - | `@reboot` |

### Day of Week Reference

| Value | Day |
|-------|-----|
| 0 or 7 | Sunday |
| 1 | Monday |
| 2 | Tuesday |
| 3 | Wednesday |
| 4 | Thursday |
| 5 | Friday |
| 6 | Saturday |

## Further Reading

- [man crontab](https://man7.org/linux/man-pages/man5/crontab.5.html) - Official crontab manual
- [man cron](https://man7.org/linux/man-pages/man8/cron.8.html) - Cron daemon documentation
- [crontab.guru](https://crontab.guru) - Interactive cron expression generator
- [Cron How-To](https://help.ubuntu.com/community/CronHowto) - Ubuntu community documentation
- [Systemd Timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html) - Modern alternative to cron
