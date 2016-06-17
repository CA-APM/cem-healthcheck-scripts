#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will collect a packet capture and compress it after
# for upload to a case.

# I want it to be verbose.
VERBOSE=true

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
VER="$Revision: 1.1 $"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get Program-Name, shortened Version.
PROGNAME="`basename $0 .sh`"

# Execution PID.
PROG_PID=$$

# Directory we work in.
BASEDIR=`pwd`

# Build Date in reverse - Prefix to builds
DATE=`date +"%Y%m%d"`

# Timeout is 60seconds
TMOUT=60

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

# Define the Hostname
HOSTName=`hostname -s`

# IP
IPAdd=`ifconfig | grep "inet addr:" | head -1 | awk '{ print $2}' | sed -e 's/addr\://g'`

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"
CapFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}.pcap"

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"
PCAPCFG="${BASEDIR}/apm_pcap.cfg"
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


#
###############################################################################
# Log function - very small
DiskSize() {

    # Compute require space in Temp-Space
    # Size in KBytes
    let TMPMINSIZE=($SIZE * 2)
    
    # Checking Disk_size.
    TMPDISK=`df -P -k . | tail -1 | awk '{ print $4 }'`
    
    if [ $TMPDISK -lt $TMPMINSIZE ]
    then
	MSG="Not enough space on current directory. Bailing out !"
	errlvl=1
	errors
    fi
    
} # log function.
###############################################################################

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
echo "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh v$VER (apm-scripts ${RELEASE}-b${BUILD})"
echo " > Preparing for packet capture"

if [ -f $CONFIG ]
then
    . $CONFIG
else
    MSG="No config file found. Bailing out"
    errlvl=1
    errors
fi

# No default configuration file
if [ -f $PCAPCFG ]
then
    . $PCAPCFG
else
    # Size in KBytes
    SIZE=1000000
    echo "SIZE=${SIZE}" > $PCAPCFG
    # Timeout in seconds - if possible to apply
    CTMOUT=600
    echo "CTMOUT=${CTMOUT}" >> $PCAPCFG
    # Default Packet count
    PCOUNT=1000000
    echo "PCOUNT=${PCOUNT}" >> $PCAPCFG
    # Default Capture Interface
    NDEV=eth1
    echo "NDEV=${NDEV}" >> $PCAPCFG
    # Default Feed
    FEED=0
    echo "FEED=${FEED}" >> $PCAPCFG

fi

# Dump current configuration
echo "=== Default settings ==============================================="
echo "   PCAP Size in:              ${SIZE} Kbytes"
echo "   Capture timeout/interval:  ${CTMOUT} seconds"
echo "   Capture number of packets: ${PCOUNT}"
echo "   Network dev/feed to use:   Autotetected on every run" 
echo "===================================================================="

DEFCFG=y
echo -n ">> Use default/stored settings [y/n]?: "
read DEFCFGNew
if [ -n "$DEFCFGNew" -a  "$DEFCFGNew" != "$DEFCFG"  ]
then
    DEFCFG="$DEFCFGNew"
fi


# Check for MTP.
if [ -x /opt/NetQoS/bin/buildpcap ]
then
    SHARK="/opt/NetQoS/bin/buildpcap"
    NSHARK=buildpcap
    TYPE=MTP
else
    if [ -x "`which tshark 2>/dev/null`" ]
    then
	SHARK="`which tshark`"
	NSHARK=tshark
	TYPE=NOMTP
    elif [ -x "`which tethereal 2>/dev/null`" ]
    then
	SHARK="`which tethereal`"
	NSHARK=tethereal
	TYPE=NOMTP
    elif [ -x "`which tcpdump 2>/dev/null`" ]
    then
	SHARK="`which tcpdump`"
	NSHARK=tcpdump
	TYPE=NOMTP
    else
	SHARK="/usr/sbin/tshark_notthere"
	NSHARK=none
	MSG="No supported packet capture program found. Bailing out !"
	TYPE=UNDEF
	errlvl=1
	errors
    fi
fi

echo " > System type: ${TYPE}, capture program: $NSHARK"

if [ "$TYPE" == "MTP" ]
then

    # Size in MBytes
    let DISPSIZE=($SIZE / 1000)

    if [ "$DEFCFG" == "n" ]
    then
	echo -n ">> PCAP Size [${SIZE}] in Kbytes: "
	read SIZENew
	if [ -n "$SIZENew" -a  "$SIZENew" != "$SIZE"  ]
	then
	    SIZE="$SIZENew"
	    sed -i '/^SIZE/d' $PCAPCFG
	    echo "SIZE=${SIZE}" >> $PCAPCFG
	    # Size in MBytes
	    let DISPSIZE=($SIZE / 1000)
	    let TMPMINSIZE=($SIZE * 2)
	fi
    fi
    # Check the Disk Size
    DiskSize
    
    # We are on a MTP
    if [ "$DEFCFG" == "n" ]
    then
	echo -n ">> PCAP extraction duration [${CTMOUT}] in seconds: "
	read CTMOUTNew
	if [ -n "$CTMOUTNew" -a  "$CTMOUTNew" != "$CTMOUT"  ]
	then
	    CTMOUT="$CTMOUTNew"
	    sed -i '/^CTMOUT/d' $PCAPCFG
	    echo "CTMOUT=${CTMOUT}" >> $PCAPCFG
	fi
    fi
    
    # define time boundaries for data extraction at MTP
    DATEsEND=`date +%s`

    let DATEsEND="$DATEsEND - 60"
    DATEEND=`date --date="@${DATEsEND}" +"%Y%m%d-%T"`
    
    let DATEsSTART="${DATEsEND} - ${CTMOUT}" # Capture 10 Minute of data for analysis 
    DATESTART=`date --date="@${DATEsSTART}" +"%Y%m%d-%T"`
    
    # Checking number of existing feeds
    FEEDcnt=`ls -drt /nqtmp/tim/? | cut -d '/' -f 4 | wc -l`

    if [ $FEEDcnt -eq 0 ]
    then
	# This should not happen. No Feed - no data to TIM, no packet
	# capture
	echo "** No data feed detected (No TIM installation ?) "
	echo -n "** Please provide feed to use [0..8]: "
	read FEEDNew
	if [ -n "$FEEDNew" -a  "$FEEDNew" != "$FEED"  ]
	then
	    FEED="$FEEDNew"
	    sed -i '/^FEED/d' $PCAPCFG
	    echo "FEED=${FEED}" >> $PCAPCFG
	fi

	MSG="No data feed found. Bailing out!"
	errlvl=1
	errors

    elif [ $FEEDcnt -eq 1 ]
    then
	
	# Identify data feed for TIM
	FEED=`ls -drt /nqtmp/tim/? | cut -d '/' -f 4 | tail -1`
    else
	echo "** More than one Data Feed found"
	echo -n "** Please choose feed to use : "
	# Check if we have one interface or more detected.
	echo `ls -drt /nqtmp/tim/? | cut -d '/' -f 4`

	echo -n ">> Napatech Feed to use [${FEED}]: "
	read FEEDNew
	if [ -n "$FEEDNew" -a  "$FEEDNew" != "$FEED"  ]
	then
	    FEED="$FEEDNew"
	    sed -i '/^FEED/d' $PCAPCFG
	    echo "FEED=${FEED}" >> $PCAPCFG
	fi
    fi
    
    echo " > Extracting Max ${DISPSIZE}MBytes of data from Storage, feed $FEED"
    echo " > Requesting ${CTMOUT}secs of data from ${DATESTART} to ${DATEEND}"
    echo " > Using NetQoS buildpcap to extract packet capture. Please wait !"
    echo "================================================================================"
    
    echo "Launching: "
    echo "/opt/NetQoS/bin/buildpcap --start-datetime ${DATESTART} --end-datetime ${DATEEND} --feed $FEED --max-file-kb $SIZE --output-file $CapFile"
    # Actual capture
    /opt/NetQoS/bin/buildpcap --start-datetime ${DATESTART} --end-datetime ${DATEEND} --feed $FEED --max-file-kb $SIZE --output-file $CapFile
    
elif [ "$TYPE" == "NOMTP" ]
then

    # We are on a TIM/HPTIM
    if [ "$DEFCFG" == "n" ]
    then
	echo -n ">> Number of packets to capture [${PCOUNT}]: "
	read PCOUNTNew
	if [ -n "$PCOUNTNew" -a  "$PCOUNTNew" != "$PCOUNT"  ]
	then
	    PCOUNT="$PCOUNTNew"
	    sed -i '/^PCOUNT/d' $PCAPCFG
	    echo "PCOUNT=${PCOUNT}" >> $PCAPCFG
	fi
    fi

    # Packets are usually max 1.5KB - but average gives us around 1KB...
    SIZE=$PCOUNT
    # Check the Disk Size
    DiskSize

    # check the TIM Version to identify the location of the interface configuration file
    CHECKTIM=`rpm -q tim`
    if [ "$CHECKTIM" == "package tim is not installed" ]
    then
	if [ -f /etc/wily/cem/tim/config/interfacefilter.xml ]
	then
	    intcfg=/etc/wily/cem/tim/config/interfacefilter.xml
	    ADEV=yes
	else
	    echo "** Unable to identify TIM. Falling back to manual Interface selection"
	    ADEV=no
	fi
    else
	intcfg=`rpm -ql tim | grep interfacefilter.xml`
	ADEV=yes
    fi

    # Go working on the UI
    if [ "$ADEV" == "yes" ]
    then
	# Check if we have one interface or more detected.
	devcnt="`grep '\<Name\>' $intcfg | sed -e 's/[<,>,\/]//g' -e 's/Name//g' | awk '{ print $1 }' | wc -l`"
    else
	# Manual mode
	devcnt=0
    fi

    # Manual mode
    if [ $devcnt -eq 0 ]
    then
	echo "** No Mirror interface found in cfg. Please provide it manually !"
	echo -n ">> Interface name for packet capture [${NDEV}]: "
	read NDEVNew
	if [ -n "$NDEVNew" -a  "$NDEVNew" != "$NDEV"  ]
	then
	    NDEV="$NDEVNew"
	    sed -i '/^NDEV/d' $PCAPCFG
	    echo "NDEV=${NDEV}" >> $PCAPCFG
	fi
    elif [ $devcnt -eq 1 ]
    then
	sed -i '/^NDEV/d' $PCAPCFG	
	NDEV="`grep '\<Name\>' $intcfg | tail -1 | sed -e 's/[<,>,\/]//g' -e 's/Name//g' | awk '{ print $1 }'`" 
	echo "NDEV=${NDEV}" >> $PCAPCFG
	echo " > Capture device is: $NDEV"
    else
	echo "** More than one capture interface found ! Only one can be used."
	echo -n "** Please choose interface to use from: "
	# Check if we have one interface or more detected.
	echo `grep '\<Name\>' $intcfg | sed -e 's/[<,>,\/]//g' -e 's/Name//g' | awk '{ print $1 }'`
	
	echo -n ">> Capture interface [${NDEV}]: "
	read NDEVNew
	if [ -n "$NDEVNew" -a  "$NDEVNew" != "$NDEV"  ]
	then
	    NDEV="$NDEVNew"
	    sed -i '/^NDEV/d' $PCAPCFG
	    echo "NDEV=${NDEV}" >> $PCAPCFG
	fi
	
    fi
    
    case "$NSHARK" in
	tshark)

	    # We are on a MTP
	    if [ "$DEFCFG" == "n" ]
	    then
		echo -n ">> Timeout for packet capture [${CTMOUT}secs]: "
		read CTMOUTNew
		if [ -n "$CTMOUTNew" -a  "$CTMOUTNew" != "$CTMOUT"  ]
		then
		    CTMOUT="$CTMOUTNew"
		    sed -i '/^CTMOUT/d' $PCAPCFG
		    echo "CTMOUT=${CTMOUT}" >> $PCAPCFG
		fi
	    fi

	    echo "================================================================================"    
	    echo "Launching: "
	    echo "$SHARK -q -a duration:${CTMOUT} -c ${PCOUNT} -i $NDEV -w $CapFile"
	    $SHARK -q -a duration:${CTMOUT} -c ${PCOUNT} -i $NDEV -w $CapFile
	    break;;
	tethereal)
	    echo "   Hit [Ctrl-C] to interrupt the collection process (can take long)"
	    echo "================================================================================"    
	    echo "Launching: "
	    echo "$SHARK -q -c ${PCOUNT} -s 0 -i $NDEV -w $CapFile"
	    $SHARK -q -c ${PCOUNT} -s 0 -i $NDEV -w $CapFile
	    break;;
	tcpdump)
	    echo "   Hit [Ctrl-C] to interrupt the collection process (can take long)"
	    echo "================================================================================"    
	    echo "Launching: "
	    echo "$SHARK -q -c ${PCOUNT} -s 0 -i $NDEV -w $CapFile"
	    $SHARK -q -c ${PCOUNT} -s 0 -i $NDEV -w $CapFile
	    break;;
    esac

    # Zipping file
    gzip -9 $CapFile

    
else
    MSG="Unknown error condition. Should not happen. Bailing out !"
    errlvl=1
    errors
fi

echo "Packet capture in: ${CapFile}.gz"
echo

# Lock program
Unlock $LockFile
