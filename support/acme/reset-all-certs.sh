#!/usr/bin/env bash

################################################################################
# Backup all ACME certificates then delete and recreate them.
set -eu
set -o pipefail

################################################################################
# Take a backup:
name="acme-$(date +%Y-%m-%d.%s).tar.gz"
echo "Creating backup as /var/lib/$name"
tar -C /var/lib -czf "$name" acme

################################################################################
# Prevent ACME services from running right now:
echo "Stopping all ACME services..."
systemctl stop "acme-*" --all

################################################################################
# Delete all certificates then re-generate them one at a time:
rm -rf "/var/lib/acme"
systemd-tmpfiles --create

readarray -t units < <(
  systemctl list-units -t timer --full --all --plain --no-legend "acme-*" |
    cut -d' ' -f1 |
    sed 's/\.timer$//'
)

for unit in "${units[@]}"; do
  echo "Manually generating cert with service $unit..."
  systemctl start "$unit.service"
done

################################################################################
# Re-enable the timers so certs get renewed:
for unit in "${units[@]}"; do
  systemctl start "$unit.timer"
done
