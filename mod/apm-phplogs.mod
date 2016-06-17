#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will gather all information required for troubleshooting
# Networking issues with the PHP Agent software

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

# IP
IPAdd=`ifconfig | grep "inet addr:" | head -1 | awk '{ print $2}' | sed -e 's/addr\://g'`

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"
COLLCONFIG="${BASEDIR}/phpagent.cfg"
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
    echo "*** ERROR: Unable to load build info. Abort."
    exit
fi


##########################################################################
# Actual script start
##########################################################################

# Lock program
Lock $LockFile 1

# Root Check
check_useruid

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

# Date + Time
LDATE=`date +"%F @ %T"`

# Log program version.
title "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh v$VER (apm-scripts ${RELEASE}-b${BUILD})"
echo " Data collection script - all this data can help troubleshoot" >> $LogFile
echo " potential issues on the appliance"  >> $LogFile
echo


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

# Get Collector installation pas
if [ -f $COLLCONFIG ]
then
    . $COLLCONFIG
fi

log "Collecting PHP Agent relevant data and logs"
log "Execution time is approx 10 seconds"

title "System information"

entry "Running Kernel: uname -a"
uname -a >> $LogFile

entry "uptime"
uptime >> $LogFile

entry "OS Information"
apmsysinfo >> $LogFile

entry "Memory Usage: free"
free >> $LogFile

entry "SELinux configuration"
sed -e '/^#/d' -e '/^$/d' /etc/sysconfig/selinux >> $LogFile

entry "Apache WebServer relevant software"
rpm -qa | grep httpd | sort -u  >> $LogFile

entry "PHP relevant software"
rpm -qa | grep php | sort -u  >> $LogFile

entry "Zend relevant software"
rpm -qa | grep zend | sort -u  >> $LogFile

# Extract Zend release
EXTMANAGER=`rpm -qa | grep extension-manager-zend`
# Extract Zend Extension Manager
ZENDEXTDIR=`rpm -ql $EXTMANAGER | grep "conf.d$"`

if [ -f ${ZENDEXTDIR}/wily_php_agent.ini ]
then
    entry "wily php agent probe configuration file"
    echo "Data of file: ${ZENDEXTDIR}/wily_php_agent.ini" >> $LogFile
    sed -e '/^;/d' -e '/^$/d' ${ZENDEXTDIR}/wily_php_agent.ini >> $LogFile

    # Extract the logfile directory of the probe Note - the introscope
    # stuff is developped under Windows, hence the \n\r at the end of
    # configuration files... that needs to be removed
    PROBELOGS=`grep ^wily_php_agent.logdir ${ZENDEXTDIR}/wily_php_agent.ini | cut -d '=' -f 2 | sed -e 's/\"//g' | tr -d '\n\r'`
    entry "Seeking log-files in ${PROBELOGS}"
    for logfile in `ls -t ${PROBELOGS}/*`
    do
	entry "File $logfile content"
	cat $logfile >> $LogFile
    done
    
else
    entry "wily_php_agent.ini probe configuration file not found ..."
fi


# DB Path
echo -n " >> Collector installation path [$COLLPATH]: "
read newCOLLPATH
if [ -n "$newCOLLPATH" -a "$COLLPATH" != "$newCOLLPATH"  ]
then
    COLLPATH="$newCOLLPATH"
fi

# Store the path
echo "COLLPATH=\"$COLLPATH\"" > $COLLCONFIG

entry "Collector configuration"
egrep "^introscope|^log4j" ${COLLPATH}/core/config/IntroscopeCollectorAgent.profile >>  $LogFile

# Cycle through log-files found in Collector installation
for collfile in `find ${COLLPATH}/logs/ -name \"*\.log\"`
do
    title "ERROR/WARNINGS in $collfile"
    entry "Errors"
    grep "\[ERROR\]" $collfile >> $LogFile
    
    entry "Warnings"
    grep "\[WARN\]" $collfile >> $LogFile
done

# Checking if system is allowed to create core files
entry "Core file creation status in /etc/security/limits.conf"
grep core /etc/security/limits.conf >> $LogFile

# Checking if system is allowed to create core files
entry "Core file creation status in init file"
grep DAEMON_COREFILE_LIMIT /etc/sysconfig/init >> $LogFile

entry "sysctl-file content"
cat /etc/sysctl.conf >> $LogFile

if [ -f ${BASEDIR}/origin.cfg ]
then
    source ${BASEDIR}/origin.cfg
    chown ${USERNAME}.${GRPNAME} $LogFile
fi

log "Report has been dumped to"
log "File: $LogFile"
echo

# Lock program
Unlock $LockFile
