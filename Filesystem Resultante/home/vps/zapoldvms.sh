#!/bin/bash

#----------Inicializacion
MYMAIL=root
ERR="ninguno"
SECONDS=0

#----------Mover backups mayores a 15 dias al archivo quincenal
/usr/bin/find /home/vps/INSTALL/BackupVPS/ -type f -name '*.ova' -mtime +15 -exec mv {} /home/vps/INSTALL/BackupVPS/archive/twoWeeksAgo/ \;
if [ $? -ne 0 ]; then ERR="moviendo backups mas antiguos que 15 dias al archivo quincenal"; fi
#----------Mover backups mayores a 30 dias al archivo mensual
/usr/bin/find /home/vps/INSTALL/BackupVPS/archive/twoWeeksAgo/ -type f -name '*.ova' -mtime +30 -exec mv {} /home/vps/INSTALL/BackupVPS/archive/aMonthAgo/ \;
if [ $? -ne 0 ]; then ERR="moviendo backups mas antiguos que 30 dias al archivo mensual"; fi
#----------Borrar backups mayores a 40 dias del archivo mensual
/usr/bin/find /home/vps/INSTALL/BackupVPS/archive/aMonthAgo/ -type f -name '*.ova' -mtime +40 -exec rm {} \;
if [ $? -ne 0 ]; then ERR="eliminando backups mas antiguos que 40 dias"; fi

#----------Calculate duration
duration=$SECONDS
duration="La operacion tomo $(($duration / 60)) minutos, $(($duration % 60)) segundos."

#----------Preparar Reporte
if [ "$ERR" == "ninguno" ]; then
   MAILBODY="Backups de VMs antiguas gestionadas correctamente!"
   MAILBODY="$MAILBODY"$'\n'"$duration"
   MAILSUBJECT="Gestion de Backups de VMs exitosa"
 else
   MAILBODY="Ocurrio un error $ERR ."
   MAILSUBJECT="Error gestionando backups antiguos de VMs"
fi

#----------Enviar Reporte
echo "$MAILBODY" | mail -s "$MAILSUBJECT" $MYMAIL
