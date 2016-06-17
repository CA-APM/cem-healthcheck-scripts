#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will gather all information required for troubleshooting Networking issues
# with the TIM software

# I want it to be verbose.
VERBOSE=true

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
VER="$Revision: 1.6 $"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get Program-Name, shortened Version.
PROGNAME="`basename $0 .sh`"

# Execution PID.
PROG_PID=$$

# Directory we work in.
BASEDIR=`pwd`

# Build Date in reverse - Prefix to builds
DATE=`date +"%Y%m%d"`

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

# Define the Hostname
HOSTName=`hostname -s`

# IP - This is just to gfrab the first available IP adress
IPAdd=`ifconfig | grep "inet addr:" | head -1 | awk '{ print $2}' | sed -e 's/addr\://g'`

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"
ISCPCONFIG="${BASEDIR}/iscp.cfg"
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

# Lock program
Lock $LockFile 1

##########################################################################
# Actual script start
##########################################################################

# Check user rights
# check_useruid (Not required)

# Create Title
title "EM/MoM/TESS LOG"

# Date + Time
LDATE=`date +"%F @ %T"`

echo

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

title "`date` by `whoami`@`hostname` - ${PROGNAME}.sh v${VER} (apm-scripts ${RELEASE}-b${BUILD})"
echo " Data collection script - all this data can help troubleshoot" >> $LogFile
echo " potential EM/MoM/TESS issues"  >> $LogFile

# Set a title for the script
title "Details"

if [ -f $CONFIG ]
then
    . $CONFIG
else
    MSG="No config file found. Bailing out"
    errlvl=1
    errors
fi

# Add these to the Log file
echo "Customer Name: $CsrName" >> $LogFile
echo "Customer Name + Mail: $UsrMail" >> $LogFile
echo "Ticket: $SupportTicket" >> $LogFile
entry "One line description of issue"
echo "$Comment" >> $LogFile

# Get ISCP installation path
# OpenSSL requires the port number.
if [ -f $ISCPCONFIG ]
then
    . $ISCPCONFIG
fi

# Introscope Path
echo -n " >> EM/MoM installation path [$ISCPPATH]: "
read newISCPPATH
if [ -n "$newISCPPATH" -a "$ISCPPATH" != "$newISCPPATH"  ]
then
    ISCPPATH="$newISCPPATH"
    echo "ISCPPATH=\"$ISCPPATH\"" > $ISCPCONFIG
fi


title "System information"

entry "Running Kernel: uname -a"
uname -a >> $LogFile

entry "uptime"
uptime >> $LogFile

entry "OS Information"
apmsysinfo >> $LogFile

entry "Memory Usage: free"
free >> $LogFile

title "EM Information"

entry "EM Release"
grep "Introscope Enterprise Manager Release" ${ISCPPATH}/logs/em.log | grep -v ^* | tail -1 >> $LogFile

entry "License file. If empty, the license is most probably not valid"
grep "Found valid license file" ${ISCPPATH}/logs/em.log | grep -v ^* | tail -1 >> $LogFile

entry "EM mode"
grep " mode\.$" ${ISCPPATH}/logs/em.log >> $LogFile

entry "Hot Failover"
grep "Manager.HotFailover" ${ISCPPATH}/logs/em.log >> $LogFile

entry "EM authentication"
grep "Manager.Authentication" ${ISCPPATH}/logs/em.log  >> $LogFile

entry "Java version"
grep "Using Java VM version" ${ISCPPATH}/logs/em.log >> $LogFile

entry "EM directories"
grep "Using Introscope installation at:" ${ISCPPATH}/logs/em.log >> $LogFile
grep "Using data directory:" ${ISCPPATH}/logs/em.log >> $LogFile
echo "Directory content: `du -sh ${ISCPPATH}/data`" >> $LogFile
grep "Using archive directory" ${ISCPPATH}/logs/em.log >> $LogFile
echo "Directory content: `du -sh ${ISCPPATH}/data/archive`" >> $LogFile

entry "EM transaction trace configuration"
grep "Manager.TransactionTracer" ${ISCPPATH}/logs/em.log | tail -10 >> $LogFile

entry "EM Clamp settings"
grep "Clamp" ${ISCPPATH}/logs/em.log | grep SpringOsgiExtenderThread-8 | tail -20 >> $LogFile

entry "EM Async Executor"
grep "PO Async Executor" ${ISCPPATH}/logs/em.log | tail -10 >> $LogFile

entry "EM Collectors - if bouncing, check connectivity or load"
grep "Manager.Cluster"  ${ISCPPATH}/logs/em.log | grep "Added collector" >> $LogFile

entry "EM Data Tiers"
grep "Data tier ." ${ISCPPATH}/logs/em.log | tail -10 >> $LogFile
grep "Data age configured to" ${ISCPPATH}/logs/em.log | tail -10 >> $LogFile

entry "Manager Database"
grep "Manager.Database" ${ISCPPATH}/logs/em.log >> $LogFile

entry "Manager Flat Files"
grep "Manager.FlatFile" ${ISCPPATH}/logs/em.log >> $LogFile

entry "Manager Action"
grep "Manager.Action" ${ISCPPATH}/logs/em.log >> $LogFile

entry "Manager Javascript calculators"
grep "Manager.JavaScriptCalculator" ${ISCPPATH}/logs/em.log >> $LogFile

entry "Manager Management Module"
grep "Manager.ManagementModule" ${ISCPPATH}/logs/em.log >> $LogFile

title "ERROR/WARNINGS"
entry "Errors"
grep "\[ERROR\]" ${ISCPPATH}/logs/*.log >> $LogFile

entry "Warnings"
grep "\[WARN\]" ${ISCPPATH}/logs/*.log >> $LogFile

title "TESS data"

if [ -f ${ISCPPATH}/config/tess-customer.properties ]
then
    # Extracting data from TESS
    entry "tess-customer.properties"
    cat ${ISCPPATH}/config/tess-customer.properties >> $LogFile

else
    entry "No tess-customer.properties found. Skipped"
fi


title "END System Status info"

log "Report has been dumped to"
log "File: $LogFile"
echo

Unlock $LockFile
