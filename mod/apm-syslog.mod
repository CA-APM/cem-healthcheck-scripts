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
VER="$Revision: 1.31 $"

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
    echo "*** ERROR: Unable to load shared functions. Abort."
    exit
fi

# Default storage Manager installation directory
STORMANDIR=/usr/StorMan

# Lock program
Lock $LockFile 1

##########################################################################
# Actual script start
##########################################################################

# Harddisk information
# Identity harddisk major devices, and existing partitions.
DISKS=`cat /proc/partitions | awk '{ print $4 }' | sed -e '/^name$/d' -e '/^$/d' -e '/^[a-z][a-z][a-z][0-9]/d'`

# Partitions
PARTITIONS=`mount | grep -v none | egrep "ext|xfs" | awk '{print $1}'`

# Check user rights
check_useruid

# Create Title
title "sysStat LOG"

# Date + Time
LDATE=`date +"%F @ %T"`

echo
# Log program version.
log "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh v$VER (apm-scripts ${RELEASE}-b${BUILD})"

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

title "`date` by `whoami`@`hostname` - ${PROGNAME}.sh v${VER} (apm-scripts ${RELEASE}-b${BUILD})"
echo " Data collection script - all this data can help troubleshoot" >> $LogFile
echo " potential system issues"  >> $LogFile

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


title "System information"

entry "Running Kernel: uname -a"
uname -a >> $LogFile

entry "uptime"
uptime >> $LogFile

entry "OS Information"
apmsysinfo >> $LogFile


entry "Memory Usage: free"
free >> $LogFile
echo -n "% Percent used RAM: " >> $LogFile
free | awk 'FNR == 3 {print $3/($3+$4)*100}' >> $LogFile
echo -n "% Percent free RAM: " >> $LogFile
free | awk 'FNR == 3 {print $4/($3+$4)*100}' >> $LogFile

entry "Processes using SWAP (If empty list - very good !): "
for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | grep -v "0 kB$" | grep " kB$" | sort -k 2 -n -r >> $LogFile

entry "Top run - shows current running applications"
top -b -n 1 >> $LogFile

entry "ipc facilities"
ipcs -l >> $LogFile

entry "Loaded kernel modules / drivers"
lsmod >> $LogFile

entry "dma calls"
cat /proc/dma >> $LogFile

entry "Interrupts list"
cat /proc/interrupts >> $LogFile

title "Running network configuration"
entry "Running network configuration: ifconfig -a"
ifconfig -a >> $LogFile

entry "Routing Table: route -n"
route -n >> $LogFile

entry "NameServer configuration: /etc/resolv.conf"
cat /etc/resolv.conf | grep nameserver >> $LogFile

entry "Summary statistics for each network protocol: netstat -s"
netstat -s >> $LogFile

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

title "System accesses"

entry "Who is logged in"
who -HwuT >> $LogFile

entry "Last logged users (stripped)"
lastlog | egrep -v "**Never logged in**" >> $LogFile

entry "Last login entries"
last | tac - | tail -n 32 | tac - >> $LogFile

title "Filesystem and controller drivers"
for driver in ext2 ext3 ext4 xfs zfs aacraid
do
    if [ `lsmod | grep -c $driver` -gt 0 ]
    then
	entry "Driver info for: $driver"
	modinfo $driver | grep -v "^alias:" >> $LogFile
    fi
done

title "Filesystems"
entry "File system disk space usage: df -h"
df -h >> $LogFile

entry "File system inode usage: df -i"
df -i >> $LogFile

# Disks
for disk in $DISKS
  do
    entry "Partition table for $disk"
    /sbin/fdisk -l /dev/$disk >> $LogFile 2> /dev/null
done

if [ `which hdparm  2>/dev/null` ]
then
    # Disks
    for part in $PARTITIONS
    do
	entry "Disk/Mem access speed"
	hdparm -tT $part >> $LogFile 2> /dev/null
	sleep 1
	hdparm -tT $part >> $LogFile 2> /dev/null
	sleep 1
	hdparm -tT $part >> $LogFile 2> /dev/null
    done
else
    entry "Skipped disk read access speed test - missing hdparm !"
fi

if [ `which iotop 2>/dev/null` ]
then
    entry "Checking application read/write ops"
    iotop -b -q -a -o -n 5  >> $LogFile 2> /dev/null
else
    entry "Skipped application read/write ops - missing iotop !"
fi

if [ `which iostat 2>/dev/null` ]
then
    entry "Checking system iostats"
    iostat -x  >> $LogFile 2> /dev/null
else
    entry "Skipped system iostats - executable not found !"
fi

entry "fstab file content"
cat /etc/fstab >> $LogFile

# Checking what mount options the diks are using
entry "Mount information of all partitions"
/bin/mount | grep "^\/dev" >> $LogFile

# Partitions
for part in $PARTITIONS
  do
    # Check if it's a ext something filesystem
    if [ `mount | grep "${part}" | grep -c ext` -eq 1 ]
    then
	if [ `which tune2fs 2>/dev/null` ]
	then
	    entry "Device $part Superblock Structure"
	    /sbin/tune2fs -l $part >> $LogFile
	    fi
    elif [ `mount | grep "${part}" | grep -c xfs` -eq 1 ]
    then

	if [ `which xfs_info 2>/dev/null` ]
	then
	    entry "Device $part XFS info"
	    /usr/sbin/xfs_info $part >> $LogFile
	fi
    else
	entry "Device $part skipped - Not a valid extX filesystem"
    fi
done

if [ -x ${STORMANDIR}/arcconf ]
then
    title "Storage Manager trools / MTP Controllers"
    entry "Raid controller details"
    ${STORMANDIR}/arcconf GETVERSION >> $LogFile

    ctrlnum=`${STORMANDIR}/arcconf GETVERSION | head -1 | cut -d ':' -f 2` 2> /dev/null

    for cnt in `seq $ctrlnum`
    do
	entry "Configuration controller $cnt"
	${STORMANDIR}/arcconf GETCONFIG $cnt >> $LogFile
	entry "Controller $cnt DEVICE logs"
	${STORMANDIR}/arcconf GETLOGS $cnt DEVICE tabular >> $LogFile
	entry "Controller $cnt DEAD disk logs"
	${STORMANDIR}/arcconf GETLOGS $cnt DEAD tabular >> $LogFile
    done

else
    title "Storage manager tools not detected. Skipped !"
fi

entry "Home directory sizes: du -sh /home/*"
find /home -maxdepth 1 -type d -exec du -sh {} \;  >> $LogFile

title "User crontabs"
for i in `find /var/spool/cron -type f -name "*" -print | cut -d "/" -f 5`;
  do
    entry "Crontab for User $i"
    crontab -l -u $i >> $LogFile
  done

entry "System cron jobs"
ls -l /etc/cron.*/* >> $LogFile

title "Log files"

entry "Check logfile sizes"
ls -ldhSr /var/log/* | tail -10 >> $LogFile

entry "Real lastlog file size"
du -h /var/log/lastlog  >> $LogFile

# Check all System entry logs etc.
entry "System/OS logfile error|warning messages"
egrep -i "error|warning" /var/log/*.log /var/log/messages /var/log/maillog /var/log/secure /var/log/httpd/*log >> $LogFile 2>&1

# Check vmotion location moves
entry "Check vmotion move: if ID changes, it has been moved (Valid only for vmotion - if empty, good !)"
grep -i "VMCIUtil: Updating context id from" /var/log/messages* >> $LogFile


# In case we have details on installation - provide these
if [ -d /etc/CA ]
then
    title "Installation details"
    
    for cafile in CA_BUILD.hist CA_CHANGELOG .isobuild .mkiso
    do
	if [ -f /etc/CA/$cafile ]
	    then
	    entry "File $cafile"
	    cat /etc/CA/$cafile >> $LogFile
	fi
    done
fi

title "Misc data"

if [ -f /etc/ntp.conf ]
then
    entry "Network time Protocol configuration: /etc/ntp.conf (filtered) "
    cat /etc/ntp.conf | sed -e '/^#/d' -e '/^$/d' >> $LogFile
fi

if [ `which ntpstat 2>/dev/null` ]
then
    entry "Check ntpstats: ntpstats "
    ntpstat >> $LogFile
fi

if [ `which runlevel 2>/dev/null` ]
then
    entry "Current runlevel: runlevel "
    runlevel >> $LogFile
fi

if [ `which chkconfig 2>/dev/null` ]
then
    entry "Configure SysVinit scripts: chkconfig --list "
    chkconfig --list >> $LogFile
fi

if [ `which lspci 2>/dev/null` ]
then
    entry "PCI Listing"
    lspci -v >> $LogFile
fi

if [ `which rpm 2>/dev/null` ]
then
    entry "File check against RPM Database"
    rpm -qaV >> $LogFile 2>&1
fi
    
if [ `which dstat 2>/dev/null` ]
then
    entry "Current running stats: dstat"
    dstat --cpu --top-cpu --top-io --top-bio --disk --net --nocolor 1 10 >> $LogFile
else
    entry "Missing system resource stats - skipped !"
fi

entry "Process table"
ps auxw --forest >> $LogFile

if [ `which dmesg 2>/dev/null` ]
then
    entry "Kernel ring buffer output: dmesg"
    dmesg >> $LogFile
fi

if [ `which dmidecode 2>/dev/null` ]
   then
       entry "DMI Content: dmidecode "
       dmidecode >> $LogFile
fi

if [ -f /etc/sysconfig/hwconf ]
then
    entry "Hardware info: /etc/sysconfig/hwconf "
    cat /etc/sysconfig/hwconf >> $LogFile
fi

if [ `which rpm 2>/dev/null` ]
then
    entry "RPM package List"
    rpm -qa | sort >> $LogFile 
fi

title "END System Status info"

if [ -f ${BASEDIR}/origin.cfg ]
then
    source ${BASEDIR}/origin.cfg
    chown ${USERNAME}.${GRPNAME} $LogFile
fi

log "Report has been dumped to"
log "File: $LogFile"
echo

Unlock $LockFile
