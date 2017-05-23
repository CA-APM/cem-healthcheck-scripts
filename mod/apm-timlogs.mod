#!/bin/sh
#
# Author: $Author: jmertin $
# Locked by: $Locker: jmertin $
#
# This script will gather all information required for troubleshooting Networking issues
# with the TIM software

# I want it to be verbose.
VERBOSE=true

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
VER="$Revision: 1.48 $"

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

CHECKTIM=`rpm -q tim`
if [ "$CHECKTIM" == "package tim is not installed" ]
then
    if [ -x /etc/wily/cem/tim/bin/tim ]
	then
	log "TIM 9.5 or lower detected"
	TIMV=TIM95
    else
	MSG="TIM 9.6 or newer not detected. Aborting execution of script"
	log $MSG
	errlvl=1
	errors
    fi
else
    log "TIM 9.6 or higher detected"
    TIMV=TIM96
fi

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

log "Collecting TIM relevant data and logs. Please wait"
log "Execution time is approx 10 seconds +"
log "  10min per regular monitoring interface detected OR"
log "  10min in total if Napatech cards are used, valid also for MTP"

title "System information"

entry "Running Kernel: uname -a"
uname -a >> $LogFile

entry "uptime"
uptime >> $LogFile

entry "Release Information"
find /etc -name "*-release" -type f -exec cat {} \; >> $LogFile

if [ -f /etc/sysconfig/selinux ]
then
    entry "SELinux configuration"
    sed -e '/^#/d' -e '/^$/d' /etc/sysconfig/selinux >> $LogFile
fi

if [ `which free  2>/dev/null` ]
then
    entry "Memory Usage: free"
    free >> $LogFile
fi

title "Installed Network Cards: lspci output / filter to Ethernet"
for device in `lspci | grep Ethernet | awk '{ print $1}'`
do
  entry "Device $device"
  lspci -vs $device >> $LogFile
done

### Replace function using ethtool -i eth0 | head -1
title "Driver detail for loaded network card drivers"
for mod in `cat /proc/net/dev | egrep -v "Inter|face|lo:|sit0:" | cut -d ':' -f 1`
do
    entry "Driver for Interface: $mod"
    MODULE=`/usr/sbin/ethtool -i $mod | grep ^driver | cut -d':' -f 2`
    modinfo $MODULE >> $LogFile
done

# Napatech driver directory
if [ -x /opt/napatech ]
then
    NTPV=old
    NPTDIR=/opt/napatech
    NTPDET=yes
elif [ -x /opt/napatech3 ]
then
    NTPV=rev3
    NPTDIR=/opt/napatech3
    NTPDET=yes
fi



# Checking if a Napatech Card is existing
if [ `lsmod | egrep "ntki|nt3gd" | wc -l` -gt 0 ] && [ "$NTPDET" == "yes" ]
then
    title "Napatech Card Details"

    # Preload Napatech libraries for the apps to find the libs
    export LD_LIBRARY_PATH=${NPTDIR}/lib:$LD_LIBRARY_PATH    

    # Check if we are on a MTP and have the buidpcap file
    if [ -x /opt/NetQoS/bin/buildpcap ]
    then
	
	# MTP Detected
	MTP="yes"
    else
	MTP="no"
    fi


    for driv in ntki.ko nt3gd.ko nt3gd_netdev.ko
    do
	if [ -f ${NPTDIR}/driver/${driv} ]
	then
	    entry "Napatech card driver ${driv} info"
	    modinfo ${NPTDIR}/driver/${driv} >> $LogFile
	fi
    done

    if [ ${NTPV} == "old" ]
    then
	# Old Napatech cards drivers and utilization
	entry "Napatech Driver Info"
	${NPTDIR}/bin/DriverInfo >> $LogFile
	${NPTDIR}/bin/DriverLog -mask 0x04 -adapter 0  >> $LogFile
	
	entry "Napatech Card Diagnostics log"
	${NPTDIR}/bin/DriverLog -mask 0x20 -adapter 0 >> $LogFile
	
	entry "Napatech Adapter Error Log"
	${NPTDIR}/bin/DriverLog -mask 0x01 -adapter 0 >> $LogFile
	
	entry "Napatech Interface speed configuration"
	${NPTDIR}/bin/LinkTool -cmd get  >> $LogFile

	# This command locks in 1 out of 2 MTP's.
	# Reason unknown.
	#entry "Napatech Filters"
	#${NPTDIR}/bin/NtplTool -expr "FilterInfo=All"  >> $LogFile
    else
	# product info
	entry "Napatech product Info"
	${NPTDIR}/bin/productinfo >> $LogFile

	# Adapter info
	entry "Napatech adapter Info"
	${NPTDIR}/bin/adapterinfo >> $LogFile

	# Diagnostics
	entry "Napatech diagnostics"
	${NPTDIR}/bin/diagnostics >> $LogFile

	entry "Napatech Adapter Error Log"
	${NPTDIR}/bin/ntlog -m 0x1ff >> $LogFile
	
    fi

fi


if [ "$TIMV" == "TIM96" ]
then
    # Check where the Description file is.
    DESCFILE="`rpm -ql tim | grep description$`"
else
    DESCFILE="/var/www/cgi-bin/wily/packages/cem/tim/description"
fi


# Extract TIM Versions
if [ -f $DESCFILE ]
then

    if [ "$TIMV" == "TIM96" ]
    then
        # Extract installed TIM directory from RPM DB
	TIMDIR=`rpm -ql tim | grep bin/tim$ | sed -e 's/\/bin\/tim//g'`
	APMPACKET=`rpm -ql apmpacket | grep bin/apmpacket$ | sed -e 's/\/bin\/apmpacket//g'`
    else
	TIMDIR="/etc/wily/cem/tim"
    fi
    if [ `pidof tim` -gt 1 ]
    then
	if [ -x /usr/bin/pstack ]
	then
	    entry "TIM started threads: pstack `pidof tim`"
	    pstack `pidof tim` >> $LogFile
	else
	    entry "pstack not found - skipping tim thread listing"
	    log "pstack not found - skipping tim thread listing"
	fi
    else
	entry "TIM process not found - check it TIM is running"
	log "TIM process not found - check it TIM is running"
    fi

    title "TIM network related data"
    entry "Tim version"
    cat $DESCFILE | tail -1 >> $LogFile

    if [ -x ${TIMDIR}/bin/configtool ]
    then
	entry "Tim settings"
	${TIMDIR}/bin/configtool -f ${TIMDIR}/config/timsettings.db -l >> $LogFile
    fi

    if [ -f ${TIMDIR}/config/balancer.cnf ]
    then
	entry "Balancer configuration"
	egrep -v "^#|^$" ${TIMDIR}/config/balancer.cnf >> $LogFile
    else
	entry "No specific balancer configuration found"
    fi

    # Tim Status
    entry "TIM real time status"
    if [ -x ${TIMDIR}/bin/timmonxml ]
    then
	for KeyW in Pid TotalPackets TotalShortPackets JavaPluginId WatchDog TimCpuUsage Memory SslSessions TotalSslSessions LoginSessions QueuedLoginInfo Connections OutOfOrderTcpByteCount Stats StatsWritten
	do
	    echo -e "$KeyW:\t `${TIMDIR}/bin/timmonxml -value $KeyW`"  >> $LogFile
	done
    fi


    entry "Tim active options: ${TIMDIR}/config/tim.options"
    cat ${TIMDIR}/config/tim.options >> $LogFile

    entry "Configured WebFilters: ${TIMDIR}/config/timconfig.xml"
    grep -v --no-message encoding ${TIMDIR}/config/timconfig.xml >> $LogFile

    if [ `which xsltproc  2>/dev/null` ]
    then
	
	if [ -f ${TIMDIR}/config/clientfilter.xml ]
	then
	    entry "Client filter: ${TIMDIR}/config/clientfilter.xml"
	    /usr/bin/xsltproc ${BASEDIR}/xml2txt.xsl ${TIMDIR}/config/clientfilter.xml  | sed -e '/^ \+$/d' >> $LogFile
	else
	    entry "No Client filter defined: ${TIMDIR}/config/clientfilter.xml"
	fi
	
	entry "Watchdog Configuration: ${TIMDIR}/config/watchdogconfig.xml"
	/usr/bin/xsltproc ${BASEDIR}/xml2txt.xsl ${TIMDIR}/config/watchdogconfig.xml  | sed -e '/^ \+$/d' >> $LogFile
	
	entry "Interface filter: ${TIMDIR}/config/interfacefilter.xml"
	/usr/bin/xsltproc ${BASEDIR}/xml2txt.xsl ${TIMDIR}/config/interfacefilter.xml  | sed -e '/^ \+$/d' >> $LogFile
	
	if [ -f ${TIMDIR}/config/introscopeconfig.xml ]
	then
	    entry "Introscope Config: ${TIMDIR}/config/introscopeconfig.xml"
	    /usr/bin/xsltproc ${BASEDIR}/xml2txt.xsl ${TIMDIR}/config/introscopeconfig.xml  | sed -e '/^ \+$/d' >> $LogFile
	fi
	
	# Check for javaplugins
	if [ -d ${TIMDIR}/config/javapluginconfigs ]
	then
	    entry "Configured Javaplugins"
	    for file in `find ${TIMDIR}/config/javapluginconfigs -type f -name "*.xml"`
	    do
		echo "$file"  >> $LogFile
		/usr/bin/xsltproc ${BASEDIR}/xml2txt.xsl $file  | sed -e '/^ \+$/d' >> $LogFile
	    done
	fi
    else
	title "xsltproc not installed. Please install libxslt package"
	log "xslptroc not installed. Skipping xml/config file data extaction !"
    fi # xsltproc

    
    # Check if we got SSL enabled
    if [ -d ${TIMDIR}/config/webservers ]
    then
	entry "Tim SSLKey: webservers directory listing"
	ls -l ${TIMDIR}/config/webservers >> $LogFile
    else
	entry "No webservers directory found. SSL decription disabled."
    fi

    entry "File in TIM data-out Directory"
    # Check for files in the data out directory
    for dir in autogen btstats defects events recordings stats
    do
	FILES=$(find ${TIMDIR}/data/out/${dir} -type f | wc -l)
	echo "  Files in $dir: $FILES" >> $LogFile
    done
    
    # Check for the protocol stats on the TIM. 5 Second entries
    entry "5 Second protocol statistics"
    /usr/bin/tail -20 `ls -prt ${TIMDIR}/logs/protocolstats1/* | tail -1` | tac >> $LogFile

    entry "5 Minutes protocol statistics"
    /usr/bin/tail -20 `ls -prt ${TIMDIR}/logs/protocolstats/* | tail -1` | tac  >> $LogFile

    if [ -f ${TIMDIR}/logs/timlog.txt ] 
    then
	entry "out-of-order TCP queued bytes"
	tac ${TIMDIR}/logs/timlog*.txt | grep -s "out-of-order" >>  $LogFile

	entry "Dropped packets"
	tac ${TIMDIR}/logs/timlog*.txt | grep -s "ackets dropped" >>  $LogFile
    fi

    if [ -f ${APMPACKET}/logs/apmpacketlog.txt ] 
    then
	entry "apmpacket ERROR|WARNING log"
	tac ${APMPACKET}/logs/apmpacketlog.txt | egrep -i "error|warning" >>  $LogFile
    fi

    
    entry "Check outgoing files - in case there are too many, TESS is not collecting ?"
    find ${TIMDIR}/data -type f -exec ls -l {} \;  >>  $LogFile
else
    title "No TIM installation detected"
fi

title "TIM Watchdog and stdout logs"
if [ -f ${TIMDIR}/logs/timwatcherlog ]
then
    entry "dumping last 50 lines of timewatcherlog"
    tail -50 ${TIMDIR}/logs/timwatcherlog >> $LogFile
fi

if [ -f ${TIMDIR}/logs/watchdoglog ]
then
    entry "dumping last 50 lines of watchdoglog"
    tail -50 ${TIMDIR}/logs/watchdoglog >> $LogFile
fi

if [ -f ${TIMDIR}/logs/stdoutlog ]
then
    entry "dumping last 20 lines of stdoutlog"
    tail -20 ${TIMDIR}/logs/stdoutlog >> $LogFile
fi

if [ -f ${TIMDIR}/logs/rclog ]
then
    entry "dumping last 20 lines of rclog"
    tail -20 ${TIMDIR}/logs/rclog >> $LogFile
fi

if [ -f ${TIMDIR}/logs/getDownloadFileNames.log ]
then
    entry "dumping last 20 lines of downloaded files log"
    tail -20 ${TIMDIR}/logs/getDownloadFileNames.log >> $LogFile
fi

if [ -d /nqtmp/tim ]
then
    entry "Checking size of nqtmp/tim"
    du -sh /nqtmp/tim
    entry "Checking number of files in nqtmp/tim"
    find /nqtmp/tim -type f | wc -l
fi

if [ -d /nqtmp/headers ]
then
    entry "Checking size of nqtmp/headers"
    du -sh /nqtmp/headers
    entry "Checking number of files in nqtmp/headers"
    find /nqtmp/headers -type f | wc -l
fi

if [ -d /nqtmp/ReceivedFiles ]
then
    entry "Checking size of nqtmp/ReceivedFiles"
    du -sh /nqtmp/ReceivedFiles
    entry "Checking number of files in nqtmp/ReceivedFiles"
    find /nqtmp/ReceivedFiles -type f | wc -l
fi


title "Monitoring network interface stats and traffic analysis"

### TODO ###

### The wireshark -s 1 limits the packet capture size, however
### prevents the analysis on HTTP traffic. Add option/question to the
### user which way he wants to do the analysis.

# Checking what to use or to skip it alltogether.
if [ -f /usr/sbin/tshark ]
then
    SHARK=/usr/sbin/tshark
    NSHARK=tshark
elif [ -f /usr/sbin/tethereal ]
then
    SHARK=/usr/sbin/tethereal
    NSHARK=tethereal
else
    SHARK="/usr/sbin/tshark_notthere"
    NSHARK=none
    title "Wireshark (tshark) not installed. Skipping packet capture analysis !"
    log "Wireshark (tshark) not installed. Skipping packet capture analysis !"
fi

# If we have a Napatech card installed - check out which interface is running
if [ "$NAPATECH" == "set" ]
then

    if [ -x $SHARK ]
    then

	# Check if we are on a MTP and have the buidpcap file
	if [ -x /opt/NetQoS/bin/buildpcap ]
	then

	    # define time boundaries for data extraction at MTP
	    DATEsEND=`date +%s`

	    let DATEsEND="$DATEsEND - 60"
	    DATEEND=`date --date="@${DATEsEND}" +"%Y%m%d-%T"`

	    let DATEsSTART="${DATEsEND} - 600" # Capture 10 Minute of data for analysis 
	    DATESTART=`date --date="@${DATEsSTART}" +"%Y%m%d-%T"`

            title "Performing packet capture: 1Gbyte or 10Min of traffic"
	    
	    # Identify data feed for TIM
	    FEED=`ls -drt /nqtmp/tim/? | cut -d '/' -f 4 | tail -1`

	    log "Capturing 1 Minute packet capture for traffic analysis ${DATESTART} -> ${DATEEND}"
	    entry "buildpcap --start-datetime ${DATESTART} --end-datetime ${DATEEND} --feed $FEED --output-file /tmp/tlscap.pcap"
	    /opt/NetQoS/bin/buildpcap --start-datetime ${DATESTART} --end-datetime ${DATEEND} --feed $FEED --payload-bytes 0 --max-file-kb 1000000 --output-file /tmp/tlscap.pcap 

	elif [ ${NTPV} == "old" ] 
	then
            # identify the network feed the napatech card provides us.
            dev=`LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -D | grep ntxc | awk '{ print $2 }'`

            # We need to stop the TIM - the napatech card won't preovide us
            # any data if TIM is running.
            /etc/rc.d/rc.tim stop

            title "Performing packet capture: 1Gbyte or 10Min of traffic"
    
	    # Checking Disk_size.
	    TMPDISK=`df -P -k /tmp | tail -1 | awk '{ print $4 }'`
	    
	    if [ $TMPDISK -gt 2000000 ]
	    then
	        # Perform the packet capture
		LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -q -a duration:600 -c 1000000 -i $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
	    else
		echo "*** Only headers captured due to small /tmp space !!!"  >> $LogFile
		# Perform the packet capture, only headers
	        LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -q -s 1 -a duration:600 -c 1000000 -i $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
		HTTPCHECK=disabled
		
		fi
            # Restart the TIM process
            /etc/rc.d/rc.tim start
	    
	elif [ ${NTPV} == "rev3" ] # We got a Napatech rev 3 driver package (new)
	then
            # identify the network feed the napatech card provides us.
            dev=`LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -D | grep ntxc | awk '{ print $2 }'`
	    for device in `LD_PRELOAD=/opt/napatech3/lib/libpcap.so /usr/sbin/tshark -D | grep timport | awk '{ print $2 }'`
	    do
		dev="${dev}-i $device "
	    done

            # We need to stop the TIM - the napatech card won't preovide us
            # any data if TIM is running.
            service apmpacket stop

            title "Performing packet capture: 1Gbyte or 10Min of traffic"
    
	    # Checking Disk_size.
	    TMPDISK=`df -P -k /tmp | tail -1 | awk '{ print $4 }'`
	    
	    if [ $TMPDISK -gt 2000000 ]
	    then
	        # Perform the packet capture
		LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -q -a duration:600 -c 1000000 $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
	    else
		echo "*** Only headers captured due to small /tmp space !!!"  >> $LogFile
		# Perform the packet capture, only headers
	        LD_PRELOAD=${NPTDIR}/lib/libpcap.so $SHARK -q -s 1 -a duration:600 -c 1000000 $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
		HTTPCHECK=disabled
		
		fi
            # Restart the TIM process
            service apmpacket start
	    
	fi

	# Do actual analysis here
	echo "Depending on the size of the pcap, the available memory and CPU cycles"  >> $LogFile
	echo "the total traffic quality analysis can take up to 30Minutes..."  >> $LogFile
        echo -n "Packet capture file size: " >> $LogFile
	ls -psh /tmp/tlscap.pcap >> $LogFile


	if [ "$HTTPCHECK" == "disabled" ]
	then
	    entry "HTTP traffic analysis disabled, as only headers were captured !" 
	else
	    # Do actual analysis here
            entry "HTTP Stats: $NSHARK -q -r /tmp/tlscap.pcap -z http,stat,"
            $SHARK -q -r /tmp/tlscap.pcap -z http,stat, >> $LogFile  2> /dev/null
	fi
	entry "Packet Length: $NSHARK -q -r /tmp/tlscap.pcap -z plen,tree"
        $SHARK -q -r /tmp/tlscap.pcap -z plen,tree >> $LogFile  2> /dev/null
        
        entry "Packet type: $NSHARK -q -r /tmp/tlscap.pcap -z ptype,tree"
        $SHARK -q -r /tmp/tlscap.pcap -z ptype,tree >> $LogFile  2> /dev/null
	
        entry "IO Stats: $NSHARK -q -r /tmp/tlscap.pcap -z io,phs,"
        $SHARK -q -r /tmp/tlscap.pcap -z io,phs >> $LogFile  2> /dev/null
	
        entry "Expert analysis info: $NSHARK -q -r /tmp/tlscap.pcap -z expert,note,tcp"
        $SHARK -q -r /tmp/tlscap.pcap -z expert,note,tcp >> $LogFile  2> /dev/null
	
	entry "SSL/TLS Version check"
	echo -n "SSL v3.0 packets: " >> $LogFile 
	$SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0300' | wc -l >> $LogFile  2> /dev/null
	echo -n "TLS v1.0 packets: " >> $LogFile 
	$SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0301' | wc -l >> $LogFile  2> /dev/null
	echo -n "TLS v1.1 packets: " >> $LogFile 
	$SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0302' | wc -l >> $LogFile  2> /dev/null
	echo -n "TLS v1.2 packets: " >> $LogFile 
	$SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0303' | wc -l >> $LogFile  2> /dev/null
	
	entry "Manual TCP analysis"
	echo "Total segments:        "`$SHARK -r /tmp/tlscap.pcap | wc -l` >> $LogFile
	echo "Out of Order segments: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Out\-Of\-Order\]' | wc -l` >> $LogFile
	echo "ACKed unseen Segment: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ ACKed\ unseen\ segment\]' | wc -l` >> $LogFile
	echo "TCP Retransmission: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Retransmission\]' | wc -l` >> $LogFile
	echo "Duplicate ACK: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Dup\ ACK\ ' | wc -l` >> $LogFile

	entry "Checking full communication. Check bidirectional traffic flow"
	$SHARK -r /tmp/tlscap.pcap -t ad -R '(tcp.port==80 or tcp.port==443)' | head -100 >> $LogFile 2> /dev/null

	entry "Searching for content type containing text"
	$SHARK -r /tmp/tlscap.pcap -t ad -R "http.response and http.content_type[0:4] == \"text\"" -z "proto,colinfo,http.content_length,http.content_length" -z "proto,colinfo,http.content_type,http.content_type" >> $LogFile  2> /dev/null
        entry "Hosts Stats: $NSHARK -q -r /tmp/tlscap.pcap -z ip_hosts,tree"
        $SHARK -q -r /tmp/tlscap.pcap -z ip_hosts,tree >> $LogFile  2> /dev/null

	# Cleaning up
	rm -f /tmp/tlscap.pcap /tmp/etherXX*

    fi

else

    for dev in `grep '<Name>' ${TIMDIR}/config/interfacefilter.xml | sed -e 's/<Name>//g' -e 's/<\/Name>//g' | awk '{ print $1 }'`
    do
	entry "Interface traffic: network-traffic.sh -i $dev -s 1 -c 3"
	${BASEDIR}/network-traffic.sh -i $dev -s 1 -c 3 >> $LogFile
	
	if [ -x $SHARK ]
	then
            title "Performing packet capture: 1Gbyte or 10Min of traffic"

	    # Checking Disk_size.
	    TMPDISK=`df -P -k /tmp | tail -1 | awk '{ print $4 }'`
	    
	    if [ $TMPDISK -gt 2000000 ]
	    then
	        # Perform the packet capture
		$SHARK -q -a duration:600 -c 1000000 -i $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
	    else
		echo "*** Only headers captured due to small /tmp space !!!"  >> $LogFile
	        # Perform the packet capture, only headers
		$SHARK -q -s 1 -a duration:600 -c 1000000 -i $dev -w /tmp/tlscap.pcap >> $LogFile 2> /dev/null
		HTTPCHECK=disabled
	    fi
	    
	    # Do actual analysis here
	    echo "Depending on the size of the pcap, the available memory and CPU cycles"  >> $LogFile
	    echo "the total traffic quality analysis can take up to 30Minutes..."  >> $LogFile
            echo -n "Packet capture file size: " >> $LogFile
	    ls -psh /tmp/tlscap.pcap >> $LogFile

	    if [ "$HTTPCHECK" == "disabled" ]
	    then
		entry "HTTP traffic analysis disabled, as only headers were captured !" 
	    else
	        # Do actual analysis here
		entry "HTTP Stats $dev: $NSHARK -q -r /tmp/tlscap.pcap -z http,stat,"
		$SHARK -q -r /tmp/tlscap.pcap -z http,stat, >> $LogFile  2> /dev/null
            fi

	    entry "Packet Length $dev: $NSHARK -q -r /tmp/tlscap.pcap -z plen,tree"
            $SHARK -q -r /tmp/tlscap.pcap -z plen,tree >> $LogFile  2> /dev/null
            
            entry "Packet type $dev: $NSHARK -q -r /tmp/tlscap.pcap -z ptype,tree"
            $SHARK -q -r /tmp/tlscap.pcap -z ptype,tree >> $LogFile  2> /dev/null
	    
            entry "IO Stats $dev: $NSHARK -q -r /tmp/tlscap.pcap -z io,phs,"
            $SHARK -q -r /tmp/tlscap.pcap -z io,phs >> $LogFile  2> /dev/null
	    
            entry "Expert analysis info $dev: $NSHARK -q -r /tmp/tlscap.pcap -z expert,note,tcp"
            $SHARK -q -r /tmp/tlscap.pcap -z expert,note,tcp >> $LogFile  2> /dev/null
	
	    entry "SSL/TLS Version check for traffic on interface $dev"
	    echo -n "SSL v3.0 packets: " >> $LogFile 
	    $SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0300' | wc -l >> $LogFile  2> /dev/null
	    echo -n "TLS v1.0 packets: " >> $LogFile 
	    $SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0301' | wc -l >> $LogFile  2> /dev/null
	    echo -n "TLS v1.1 packets: " >> $LogFile 
	    $SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0302' | wc -l >> $LogFile  2> /dev/null
	    echo -n "TLS v1.2 packets: " >> $LogFile 
	    $SHARK -r /tmp/tlscap.pcap -R 'ssl.record.version == 0x0303' | wc -l >> $LogFile  2> /dev/null
	    
	    entry "Manual TCP analysis"
	    echo "Total segments:        "`$SHARK -r /tmp/tlscap.pcap | wc -l` >> $LogFile
	    echo "Out of Order segments: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Out\-Of\-Order\]' | wc -l` >> $LogFile
	    echo "ACKed unseen Segment: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ ACKed\ unseen\ segment\]' | wc -l` >> $LogFile
	    echo "TCP Retransmission: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Retransmission\]' | wc -l` >> $LogFile
	    echo "Duplicate ACK: "`$SHARK -r /tmp/tlscap.pcap | grep '\[TCP\ Dup\ ACK\ ' | wc -l` >> $LogFile

	    entry "Checking full communication. Check bidirectional traffic flow"
	    $SHARK -r /tmp/tlscap.pcap -t ad -R '(tcp.port==80 or tcp.port==443)' | head -100 >> $LogFile 2> /dev/null

	    entry "Searching for content type containing text"
	    $SHARK -r /tmp/tlscap.pcap -t ad -R "http.response and http.content_type[0:4] == \"text\"" -z "proto,colinfo,http.content_length,http.content_length" -z "proto,colinfo,http.content_type,http.content_type" >> $LogFile  2> /dev/null

            entry "Hosts Stats $dev: $NSHARK -q -r /tmp/tlscap.pcap -z ip_hosts,tree"
            $SHARK -q -r /tmp/tlscap.pcap -z ip_hosts,tree >> $LogFile  2> /dev/null
	    
	    # Cleaning up
	    rm -f /tmp/tlscap.pcap /tmp/etherXX*

	fi
	
	entry "Interface using driver: ethtool -i $dev"
	ethtool -i $dev >> $LogFile
	
	entry "Ethernet Card Settings: ethtool $dev"
	ethtool $dev >> $LogFile

	entry "Ethernet Card buffer presets: ethtool -g $dev"
	ethtool -g $dev >> $LogFile
	
	entry "Interface statistics: ethtool -S $dev"
	ethtool -S $dev >> $LogFile
	
	entry "Interface offload configuration: ethtool --show-offload $dev"
	ethtool --show-offload $dev >> $LogFile
	
	IntList="IntList${coma} $dev"
	coma=","

    done

fi

title "Running network configuration"

entry "Running network configuration: ifconfig -a"
ifconfig -a >> $LogFile

entry "Routing Table: route -n"
route -n >> $LogFile

entry "NameServer configuration: /etc/resolv.conf"
cat /etc/resolv.conf | grep nameserver >> $LogFile

log "Tracepath/traceroute - if blocked by Firewalls can make this script"
log "run for up to 5 minutes. So be patient."

# Identify Gateway IP
GW=`route -n | tail -1 | awk '{print $2}'`

# Make sure gateway is set.
if [ "$GW" != "0.0.0.0" ]
    then
    if [ -x /usr/sbin/mtr ]
	then
	entry "Trace/Ping Gateway: mtr $GW"
	mtr -n -c 3 --report $GW >> $LogFile
    else
	title "mtr not installed. Consider installing MTR for more detail"
	log "mtr not installed. Consider installing MTR for more detail"
	entry "Ping Gateway: ping $GW"
	ping -n -c 3 $GW >> $LogFile
    fi
else
    entry "no valid gateway IP found. Skipped"
fi


entry "Summary statistics for each network protocol: netstat -s"
netstat -s >> $LogFile

# Make sure we have a nameserver
NS=`cat /etc/resolv.conf | grep nameserver | tail -1 | awk '{print $2}'`
if [ "$NS" != "0.0.0.0" -a -n "$NS" ]
then
    if [ -x /usr/sbin/mtr ]
	then
	entry "Trace/Ping Nameserver (last entry): mtr $NS"
	mtr -n -c 3 --report $NS >> $LogFile
    else
	entry "Ping Nameserver (last entry): ping $NS"
	ping -n -c 3 $NS >> $LogFile
    fi
else
    entry "no valid Nameserver IP found. Skipped"
fi

entry "Active filters: iptables -L -n"
if [ -f /etc/sysconfig/iptables ]
then
    iptables -L -n >> $LogFile
else
    echo "Iptables not yet configured" >> $LogFile
fi

title "Configured network configuration / System files"

for file in `find /etc/sysconfig/network-scripts -name "ifcfg-eth*"`
do
    entry "Network interfaces cfg: $file"
    cat $file >> $LogFile
done

entry "Network file: /etc/sysconfig/network"
cat /etc/sysconfig/network >> $LogFile

entry "hosts file: /etc/hosts"
cat /etc/hosts | sed -e '/^#/d' -e '/^$/d' >> $LogFile

entry "hosts.deny file: hosts.deny "
cat /etc/hosts.deny | sed -e '/^#/d'  -e '/^$/d' >> $LogFile

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
