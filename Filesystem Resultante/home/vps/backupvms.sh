#!/bin/bash

# Loop through all VirtualBox VMs, pause, export,
# and restore them to their original states.
#
# Vorkbaard, 2012-02-01, 2018-02-09

# =============== Set your variables here ===============

EXPORTDIR=/home/vps/INSTALL/BackupVPS/
LOGFILE=/home/vps/INSTALL/BackupVPS/logs/export.log
MYMAIL=root
VBOXMANAGE="/usr/bin/VBoxManage -q"

# =======================================================

# Generate a list of all VMs

for VM in $(vboxmanage list vms | rev | cut -d' ' -f1 | rev)
do
  ERR="nothing"
  SECONDS=0

  # Get VM's friendly name
  FRIENDLYNAME=$(vboxmanage showvminfo --machinereadable $VM | grep "name=" | cut -d'"' -f2)

  # Delete old $LOGFILE file if it exists
  if [ -e $LOGFILE ]; then rm $LOGFILE; fi

  # Get the vm state
  VMSTATE=$(vboxmanage showvminfo $VM --machinereadable | grep "VMState=" | cut -f 2 -d "=")
  echo "$VM's state is: $VMSTATE."

  # If the VM's state is running or paused, save its state
  if [[ $VMSTATE == \"running\" || $VMSTATE == \"paused\" ]]; then
    vboxmanage controlvm $VM savestate
    if [ $? -ne 0 ]; then ERR="saving the state"; fi
  fi

  # Export the vm as appliance
  if [ "$ERR" == "nothing" ]; then
    vboxmanage export $VM --output $EXPORTDIR/$VM-new.ova &> $LOGFILE
    if [ $? -ne 0 ]; then
      ERR="exporting"
    else
      # Remove old backup and rename new one
      if [ -e $EXPORTDIR/$VM.ova ]; then rm $EXPORTDIR/$VM.ova; fi
      mv $EXPORTDIR/$VM-new.ova $EXPORTDIR/$VM.ova
      # Get file size
      FILESIZE=$(du -h $EXPORTDIR/$VM.ova | cut -f 1)
    fi
  else
    echo "Not exporting because the VM's state couldn't be saved." &> $LOGFILE
  fi

  # Resume the VM to its previous state if that state was paused or running
  if [[ $VMSTATE == \"running\" || $VMSTATE == \"paused\" ]]; then
    vboxmanage startvm $VM --type headless
    if [ $? -ne 0 ]; then ERR="resuming"; fi
    if [ $VMSTATE == \"paused\" ]; then
      vboxmanage controlvm $VM pause
      if [ $? -ne 0 ]; then ERR="pausing"; fi
    fi
  fi

  # Calculate duration
  duration=$SECONDS
  duration="Operation took $(($duration / 60)) minutes, $(($duration % 60)) seconds."

  # Notify the admin
  if [ "$ERR" == "nothing" ]; then
    MAILBODY="Virtual Machine $FRIENDLYNAME was exported succesfully!"
    MAILBODY="$MAILBODY"$'\n'"$duration"
    MAILBODY="$MAILBODY"$'\n'"Export filesize: $FILESIZE"
    MAILSUBJECT="VM $VM succesfully backed up"
  else
    MAILBODY="There was an error $ERR VM $VM."
    if [ "$ERR" == "exporting" ]; then
      MAILBODY=$(echo $MAILBODY && cat $LOGFILE)
    fi
    MAILSUBJECT="Error exporting VM $VM"
  fi

  # Send the mail
  echo "$MAILBODY" | mail -s "$MAILSUBJECT" $MYMAIL

  # Clean up
  if [ -e $LOGFILE ]; then rm $LOGFILE; fi

done
