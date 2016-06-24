#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will gather all information required for troubleshooting Networking issues
# with the TIM software

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
# VER="$Revision: 1.6 $"

#
###############################################################################
# Log function - very small
log() {

    # Compute Date for the Logs.
    DATE=`date +"%F"`

    HEAD="${DATE} $PROGNAME:"

    # Be verbose
    ! $VERBOSE || echo "> ${HEAD} $*"
    
} # log function.
###############################################################################
#
# Little Usage help.
usage() {
    echo
    echo -e >&2 "Usage:\t${PROGNAME}.sh "
    echo -e >&2 "\tThis script will collect all possible Data to help"
    echo -e >&2 "\ttroubleshoot networking issues"
    echo -e >&2
    echo
} # function usage

#
##############################################################################
#
errors() {
#DOC: The errors Function is called to control the exit status.
#
: ${errlvl:=9}
: ${MSG:="No Error message - Probably user interruption"}
if [ $errlvl -gt 0 ] ;
    then
    if [ $errlvl = 15 ] ;
    then
        $VERBOSE && echo -e "WARNING: $MSG"
        log "WARNING: $MSG"
    else
        echo -e "\a"
        echo "FATAL:  An error occured in \"${PROGNAME}\". Bailing out..."
        echo -e "ERRMSG: $MSG"
        echo
        Unlock $LockFile
        exit $errlvl
    fi
fi
} # errors Function
#
##############################################################################
#
# Lockfile Generation
Lock() {
# Lockfile to create
tolock="$1"
Action="$2"
#
# Lock file if lockfile does not exist.
if [ -s $tolock ]
then
    # If we have provided a second Var, set Exit status using  it.
    if [ ! -n "$Action" ]
    then
        # Oops, we  found a lockfile. Loop while checking if still exists.
        while [ -s $tolock ]
        do
            sleep 5 ;
        done
        MSG="Creating lockfile $tolock failed after 5 secs"
        # write PID into Lock-File.
        echo $$ > $tolock
        errlvl=$?
        errors
    else
        Pid="`cat $tolock`"
        Exists="`ps auxw | grep \" $Pid \" | grep -c $PROGNAME`"
        if [ $Exists = 1 ]
        then
            MSG="\"$PROGNAME\" already running. Exiting..."
            errlvl=$Action
            errors
        else
            MSG="Found stale lockfile... Removing it..."
            rm -f $tolock
            errlvl=$?
            errors
            MSG="Creating lockfile $tolock failed"
            echo $$ > $tolock
            errlvl=$?
            errors
        fi
    fi
else
    # Lock it
   MSG="Creating lockfile $tolock failed"
    echo $$ > $tolock
    errlvl=$?
    errors
fi
} # Lock
#
##############################################################################
#
Unlock(){
# Name of Lockfile to unlock
unlock="$1"
# Unlock the file.
if [ -s $unlock ]
then
    PID=$$
    if [ "`cat $unlock`" != "$PID" ]
    then
        # Lock it
        echo -e "WARNING: Wrong lock-file PID. Probably a race-condition happened...\n"
    else
        # Removing Lockfile
        rm -f $unlock
    fi
fi
#
} # Unlock
#
##############################################################################
space () {
    MSG="Add space to $LogFile"
    echo "" >> $LogFile
    errlvl=$?
    errors
}

##############################################################################
title () {
    # Set to
    line=""
    lg=`echo $* | wc -c`
    let length=($lg + 4)
    while [ $length -lt 80 ]; 
    do
	line="${line}="
	let length=($length + 1)
    done

    space
    space
    echo "===============================================================================" >> $LogFile

    MSG="Add title: $* to $LogFile"
    echo "== $* $line" >> $LogFile
    errlvl=$?
    errors
    echo "===============================================================================" >> $LogFile

}
##############################################################################
separator () {
    MSG="Add separator to $LogFile"
    echo "================================================================================"  >> $LogFile
    errlvl=$?
    errors

}
##############################################################################
entry () {

    # Set to
    line=""
    lg=`echo $* | wc -c`
    let length=($lg + 8)
    while [ $length -lt 80 ]; 
    do
	line="${line}="
	let length=($length + 1)
    done

    # Add a space
    space
    MSG="Add entry: $* to $LogFile"
    echo "=== $* !  $line"  >> $LogFile
    errlvl=$?
    errors
}

##############################################################################
entrynl () {

    # Set to
    line=""
    lg=`echo $* | wc -c`
    let length=($lg + 8)
    while [ $length -lt 80 ]; 
    do
	line="${line}="
	let length=($length + 1)
    done

    # Add a space
    space
    MSG="Add entry: $* to $LogFile"
    echo "=== $* !  $line"
    errlvl=$?
    errors
}

##############################################################################
apmsysinfo () {

    LSBPRG=`which lsb_release 2>/dev/null`

    # Check if we have a LSB compatible system
    if [ -n "$LSBPRG" ]
    then
	# found LSB data. Using it
	$LSBPRG -a 2> /dev/null
    else
	#Fall back to find a OS File.
	for etcfile in system redhat centos ubuntu debian suse os
	do
	    FILE=/etc/${etcfile}-release
	    if [ -f $FILE ]
	    then
		if [ `cat $FILE | wc -l` -eq 1 ]
		then
		    echo "`cat $FILE`"
		else
		    . $FILE
		    if [ "$etcfile" == "os" ]
			then
			echo "$PRETTY_NAME"
		    else
			echo "Unable to identify Distribution"
		    fi
		fi
		return
	    fi
	done
    fi
}
##############################################################################
check_useruid () {
    USER=`whoami`
    if [ "`id -u $USER`" -ne "0" ]
    then
	echo "Script has to be executed by user root (UID=0) as it requires"
	echo "access to certain system files only root can access !"
	MSG="Wrong user UID"
	errlvl=1
	errors
    fi
}
