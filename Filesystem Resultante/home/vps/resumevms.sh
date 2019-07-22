#!/bin/bash
# Restart VMs saved earlier

STATUSFILE=/home/vps/vm-status

# If no status file exists then apparently there are no VMs to resume.
if [ ! -f $STATUSFILE ]; then exit; fi

while read VM; do
  vboxmanage startvm $VM --type headless
done <$STATUSFILE
