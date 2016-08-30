#!/bin/bash
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will check the remote supported ciphers of
# a remote webserver

# Programm Version
VER="$Revision: 1.11 $"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get Program-Name, shortened Version.
PROGNAME="`basename $0 .sh`"

# Directory we work in.
BASEDIR=`pwd`

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

# Build Date in reverse - Prefix to builds
CDATE=`date +"%Y%m%d"`

# Define the Hostname
HOSTName=`hostname -s`

# IP
IPAdd=`ifconfig eth0 | grep "inet addr:" | awk '{ print $2}' | sed -e 's/addr\://g'`

# Delay between Cipher check - default 1sec.
DELAY=1
#

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"

# Load shared functions
SHAREMOD="${BASEDIR}/mod/apm-share.mod"

if [ -f $SHAREMOD ]
then
    . $SHAREMOD
else
    echo "*** ERROR: Unable to load shared functions. Abort."
    exit
fi

BUILDF="${BASEDIR}/.build"
if [ -f $BUILDF ]
then
    . $BUILDF
else
    echo "*** ERROR: Unable to load build details. Abort."
    exit
fi

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${CDATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"

##############################################################################

# Lock program
Lock $LockFile 1

# OpenSSL requires the port number.
PORT=443

echo
title "`date` by `whoami`@`hostname` - ${PROGNAME}.sh v${VER} (apm-scripts ${RELEASE}-b${BUILD})"
log "This script will verify the compatible ciphers of the host it is run "
log "and the provided remote host "
echo -n " >> Remote host [IP or FQDN]: "
read SERVER

echo -n " >> Port the HTTPS Server is reachable [$PORT]: "
read newPORT
if [ -z "$PORT" -a  "$PORT" != "$newPORT"  ]
then
    PORT="$newPORT"
fi

# Check if we have an existing host
IP="`host $SERVER | head -1`" 2> /dev/null
errlvl=$?

if [ $errlvl -gt 0 ]
then
  echo "Failed IP Check - Can't reach host, bailing out !"
  echo " !! IP Check: $SERVER -> $IP"
  exit 1
else
  echo " >> IP Check: $SERVER -> $IP"
fi

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

# Check if we already ran this script - if not - ask some stuff to include ito the report.
if [ -f $CONFIG ]
then

    log "Loading $CONFIG"

    . $CONFIG
    
    # Add these to the Log file
    echo "Customer Name: $CsrName" >> $LogFile
    echo "Customer Name + Mail: $UsrMail" >> $LogFile
    echo "Ticket: $SupportTicket" >> $LogFile
    entry "One line description of issue"
    echo "$Comment" >> $LogFile

fi

MSG="Creating success logfile ${LogFile}.success"
echo -n > ${LogFile}.success
errlvl=$?
errors

MSG="Creating failure logfile ${LogFile}.failed"
echo -n > ${LogFile}.failed
errlvl=$?
errors

# Root Check
# check_useruid

# Date + Time
LDATE=`date +"%F @ %T"`

# Check for psql
if [ ! `which openssl` ]
then
    MSG="No openssl binary detected. Aborting"
    errlvl=1
    errors
fi


# Log program version.
title "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh version $VER"
entry "This script will check the supported ciphers of a remote webserver"
title "IP Check: $SERVER"
echo " -> $IP" >> $LogFile

echo "Extracting site certificate"
openssl s_client -host $SERVER -port $PORT -showcerts </dev/null &> ${LogFile}.certificate

echo "Computing modulus and md5sum of modulus"
openssl x509 -noout -modulus -in ${LogFile}.certificate > ${LogFile}.modulus
echo -n "MD5 Checksum: " >> ${LogFile}.modulus
openssl x509 -noout -modulus -in ${LogFile}.certificate | md5sum >> ${LogFile}.modulus


# Getting a list of the ciphers supported by the current openssl program
ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo "Obtaining cipher list from $(openssl version)."
echo "Checking ${SERVER}:${PORT} cipher match"
for cipher in ${ciphers[@]}
do

    SUPP=""
    if [ `echo $cipher | egrep -c 'ECDGH|ECDH|EDH|DHE|ADH|GCM|CAMELLIA'` -gt 0 ]
    then
	SUPP="(Not by TIM)"
    fi

    echo -n "Testing $cipher... "
    result=$(echo -n | openssl s_client -cipher "$cipher" -connect ${SERVER}:${PORT}  2>&1)
    # For debugging - uncoment the line below.	
    #echo "result: $result"

    if [[ "$result" =~ ":error:" ]]
    then
	echo "*** Testing $cipher... -> Failed !" >> ${LogFile}.failed
	echo "No"
    elif [[ "$result" =~ "write:errno=" ]]
    then
	echo "*** Testing $cipher... -> Failed ! " >> ${LogFile}.failed
	echo "No"
    elif [[ "$result" =~ "Connection refused" ]]
    then
	echo "*** Testing $cipher... -> Connection refused !" >> ${LogFile}.failed
	echo "No"
    else
	echo ">>> Testing $cipher... -> Cipher compatible ! $SUPP" >> ${LogFile}.success
	echo "Yes"
    fi
    #echo ">>> Answer: $result"
    sleep $DELAY
done

title "Supported ciphers by $SERVER"
MSG="Adding data of supported ciphers to logfile"
cat ${LogFile}.success >> ${LogFile}
errlvl=$?
errors

MSG="Removing ${LogFile}.success"
rm -f ${LogFile}.success
errlvl=$?
errors

MSG="Adding data of NOT supported ciphers to logfile"
title "NOT Supported ciphers by $SERVER"
errlvl=$?
errors
cat ${LogFile}.failed >> ${LogFile}

MSG="Removing ${LogFile}.failed"
rm -f ${LogFile}.failed
errlvl=$?
errors

MSG="Adding certificate modulus and MD5Sum"
title "Server $SERVER certificate modulus and MD5 Checksum"
errlvl=$?
errors
cat ${LogFile}.modulus >> ${LogFile}

MSG="Adding raw certificate"
title "Server $SERVER certificate"
errlvl=$?
errors
cat ${LogFile}.certificate >> ${LogFile}

MSG="Removing ${LogFile}.certificate"
rm -f ${LogFile}.certificate ${LogFile}.modulus
errlvl=$?
errors

# Logfile - all info will go in there.
NewLogFile="${BASEDIR}/${CDATE}_${PROGNAME}_${HOSTName}_${IPAdd}_${SERVER}.log"
MSG="Renaming Logfile failed"
mv $LogFile $NewLogFile
errlvl=$?
errors

LogFile=$NewLogFile

log "Logfile written to $LogFile"
echo

# Lock program
Unlock $LockFile
