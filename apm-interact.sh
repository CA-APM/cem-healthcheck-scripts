#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will gather all information required for troubleshooting Networking issues
# with the TIM software

# I want it to be verbose.
VERBOSE=false

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
VER="$Revision: 1.11 $"

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
SHAREMOD="${BASEDIR}/mod/apm-share.mod"

if [ -f $SHAREMOD ]
then
    . $SHAREMOD
else
    echo "*** ERROR: Unable to load shared functions. Abort."
    exit
fi

##########################################################################
# Actual script start
##########################################################################

# Prevent double execution
Lock $LockFile 1

# Create Title
title "LOG Collector Interactive UI"

# Date + Time
LDATE=`date +"%F @ %T"`

# Catch user-name
USER=`whoami`
echo "# This is used to identify the user - in case sudo needs to be used or not" > ${BASEDIR}/origin.cfg
echo "USERNAME=$USER" >> ${BASEDIR}/origin.cfg
echo "GRPNAME=`id -ng $USER`" >> ${BASEDIR}/origin.cfg

# Log program version.
log "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh version $VER"

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

title "`date` by `whoami`@`hostname` - ${PROGNAME}.sh v${VER}"

echo " Data collection script - all this data can help troubleshoot" >> $LogFile
echo " potential issues on the system."  >> $LogFile

# Set a title for the script
title "Details"

# Check if we already ran this script - if not - ask some stuff to include ito the report.
if [ -f $CONFIG ]
then

    log "Config file found. Sourcing info found there"
    log "If you want to reset the data - delete"
    log "$CONFIG"

    . $CONFIG
    
fi

log "The following Data will just be written to the report"
log "to help identify the source and reason of the collected data"
log "Note: a new entry will replace the old one ..."

echo -n " >> Customer Name [$CsrName]: "
read CsrNameNew
if [ -n "$CsrNameNew" -a  "$CsrNameNew" != "$CsrName"  ]
then
    CsrName="$CsrNameNew"
fi
echo -n " >> Name + EMail [$UsrMail]: "
read UsrMailNew
if [ -n "$UsrMailNew" -a  "$UsrMailNew" != "$UsrMail"  ]
then
    UsrMail="$UsrMailNew"
fi
echo -n " >> Support Ticket Nr. [$SupportTicket]: "
read SupportTicketNew
if [ -n "$SupportTicketNew" -a  "$SupportTicketNew" != "$SupportTicket"  ]
then
    SupportTicket="$SupportTicketNew"
fi
space
echo "One line description of issue [Hit ENTER when finished]:"
echo "================================================================================"
if [ -n "$Comment" ] 
then
    echo "$Comment"
fi
read CommentNew
if [ -n "$CommentNew" -a  "$CommentNew" != "$Comment"  ]
then
    Comment="$CommentNew"
fi

echo "Customer Name: $CsrName" > $LogFile
echo "Customer Name + Mail: $UsrMail" >> $LogFile
echo "Ticket: $SupportTicket" >> $LogFile
entry "One line description of issue"
echo "$Comment" >> $LogFile


    # Add all these to a hidden file in root's home
MSG="Creating $CONFIG file"
echo "CsrName=\"$CsrName\"" > $CONFIG
errlvl=$?
errors
echo "UsrMail=\"$UsrMail\"" >> $CONFIG
echo "SupportTicket=\"$SupportTicket\"" >> $CONFIG
echo "Comment=\"$Comment\"" >> $CONFIG

echo

while :;
do
    echo "Chose the action to perform"
    echo "================================================================================"
    for cfgfile in `ls ${BASEDIR}/cfg/*.cfg`
    do
	source $cfgfile
	shortName=`basename $cfgfile .cfg | cut -d '-' -f 2`
	echo " * ${shortName}: $DESC"
    done
    echo "================================================================================"
    echo -n " >> Choose action: "
    read ACTIONstr
    
    # Uppercase everything
    # ACTION=${ACTIONstr^^} # Older BASH does not accept this.
    ACTION=`echo $ACTIONstr | awk '{print toupper($0)}'`
    
    # Exit condition
    if [ "$ACTION" == "EXIT" -o "$ACTION" == "Q" -o "$ACTION" == "QUIT" ]
    then
	    # In case we want to exit
	Unlock $LockFile
	exit
    fi
    if [ -f ${BASEDIR}/cfg/${ACTION}.cfg ]
    then
	clear
	entry "Executing $ACTION"
	source ${BASEDIR}/cfg/${ACTION}.cfg
	USERCHK=`whoami`
	if [ "$USERCHK" != "root" ]
	then
	    ${SUDO} ${BASEDIR}/mod/${EXEC}
	else
	    ${BASEDIR}/mod/${EXEC}
	fi
    fi
    
done

Unlock $LockFile
