#!/bin/bash
#
# Internal ID & Revision:
# $Id: apm-perfdata.mod,v 1.16 2015/09/10 08:39:58 jmertin Exp $
# $Revision: 1.16 $
#
# File Name & location:
# /etc/cron.hourly/collect-data.sh
#
# Short description:
# This little script will generate Data information for displaying
# it in as /etc/issue on the system login-screen.
# -------------------------------------------------------------
#
# Programm Version
VER="$Revision: 1.16 $"
#
# Programm name
PROGNAME="`basename $0 .sh`"
#
# Get process ID for ourself :)
PROG_PID=$$
#
# Defining search path.
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
#
PID_DIR="/var/run"
#
# Directory we will write all data into
BASEDIR=`pwd`

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

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
    echo "*** ERROR: Unable to load shared functions. Abort."
    exit
fi

##########################################################################
# Actual script start
##########################################################################

# Lock program
Lock $LockFile 1

# Check user rights
check_useruid

echo
echo ">>> $LDATE `whoami`@`hostname` - ${PROGNAME}.sh v$VER (apm-scripts ${RELEASE}-b${BUILD})"
echo "> Collecting TIM performance data. Please wait"

CHECKTIM=`rpm -q tim`
if [ "$CHECKTIM" == "package tim is not installed" ]
then
    if [ -f /etc/wily/cem/tim/config/license.encrypted ]
	then
	echo "> TIM 9.5 or lower detected"
	TIMV=TIM95
    else
	MSG="> TIM 9.6 or newer not detected. Aborting execution of script"
	echo $MSG
	errlvl=1
	errors
    fi
else
    echo "> TIM 9.6 or higher detected"
    TIMV=TIM96
fi

if [ "$TIMV" == "TIM96" ]
then
    # Extract installed TIM directory from RPM DB
    TIMDIR=`rpm -ql tim | grep bin/tim$ | sed -e 's/\/bin\/tim//g'`
    # Used TIM Version
    TIMVer=`rpm -qv tim`
else
    TIMDIR="/etc/wily/cem/tim"
    DESCFILE="/var/www/cgi-bin/wily/packages/cem/tim/description"
    TIMVer=`cat $DESCFILE | tail -1`
fi

# Supported row-data version
VERSION=2

# Time Stamp - when data was collected
TimeStamp=`date +"%F %T"`
# Anonymized identifier
Identifier=`ifconfig | grep HWaddr | head -1 | md5sum | cut -d ' ' -f 1`
# Product name
ProdName=`dmidecode | grep "Product Name" | head -1 | cut -d ':' -f 2`
# Vendor
Vendor=`dmidecode | grep Manufacturer | head -1 | cut -d ':' -f 2` 
# Get OS-Version
OSRelease=`apmsysinfo`

if [ -f ${TIMDIR}/config/domainconfig.xml ]
then
    # Configured Business Transactions
    TranSetDef=`grep -o "TranSetDef id=" ${TIMDIR}/config/domainconfig.xml  | wc -l`
    # Configured Parameters
    ParamDef=`grep -o "ParameterDef name=" ${TIMDIR}/config/domainconfig.xml  | wc -l`
    # Configured tranunits
    CompDef=`grep -o "TranCompDef cacheable=" ${TIMDIR}/config/domainconfig.xml  | wc -l`
    # Configured components 
    CompDefnonCacheable=`grep -o "TranCompDef cacheable=\"0" ${TIMDIR}/config/domainconfig.xml  | wc -l`
    # Configured components 
    CompDefCacheable=`grep -o "TranCompDef cacheable=\"1" ${TIMDIR}/config/domainconfig.xml  | wc -l`

else
    TranSetDef=0
    ParamDef=0
    CompDef=0
    CompDefnonCacheable=0
    CompDefCacheable=0
fi

# Check active plugin count
if [ `find ${TIMDIR}/config/javapluginconfigs -name \"*\.xml\" | wc -l` -gt 0 ]
then
    JavaPlugins=`grep -o "enable=\"1" ${TIMDIR}/config/javapluginconfigs/*.xml | wc -l`
else
    JavaPlugins="0"
fi

# Total Memory to the System
MemTot=`cat /proc/meminfo | grep "MemTotal" | awk '{ print $2 }'`
# Free Memory to the System
MemFree=`cat /proc/meminfo | grep "MemFree" | awk '{ print $2 }'`
# kernel version
Kernel=`uname -orpi`
# Uptime with system load
Uptime=`cat /proc/loadavg`
# CPU Info
CPUInfo=`cat /proc/cpuinfo | grep "model name" | cut -d ':' -f 2 | head -1`
# CPU Info
CPUSpeed=`cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d ':' -f 2`
# CPUCores / Number of CPU Cores 
CPUCores=`cat /proc/cpuinfo  | grep processor | wc -l`

# Define the Destination Directory to that
DESTDIR=${BASEDIR}/data/${Identifier}

# Remove any old data
if [ -d data/${Identifier} ]
then
    rm -rf data/${Identifier}
fi
# Make the target Directory
mkdir -p ${DESTDIR}

echo "VERSION=${VERSION}" > ${DESTDIR}/capture_version.txt

# Put all that stuff into a csv-file.
echo "\"${TimeStamp}\";\"${Identifier}\";\"${ProdName}\";\"${Vendor}\";\"${OSRelease}\";\"${TIMVer}\";\"${TranSetDef}\";\"${ParamDef}\";\"${CompDef}\";\"${CompDefnonCacheable}\";\"${CompDefCacheable}\";\"${MemTot}\";\"${MemFree}\";\"${Kernel}\";\"${Uptime}\";\"${CPUInfo}\";\"${CPUSpeed}\";\"${CPUCores}\";\"$JavaPlugins\"" > ${DESTDIR}/Sysinfo.csv

# Evaluate the network load on all network interfaces
for dev in `ifconfig -a | grep Ethernet | awk '{ print $1}'`
do
    # Zero the destination file
    cat /dev/null > ${DESTDIR}/${dev}_traffic_in_bps.csv
    for sec in 1 2 3
    do
	readRX1=`/sbin/ifconfig "$dev" | grep "RX bytes" | cut -d: -f2 | awk '{ print $1 }'`
	readTX1=`/sbin/ifconfig "$dev" | grep "TX bytes" | cut -d: -f3 | awk '{ print $1 }'`
	sleep 1
	readRX2=`/sbin/ifconfig "$dev" | grep "RX bytes" | cut -d: -f2 | awk '{ print $1 }'`
	readTX2=`/sbin/ifconfig "$dev" | grep "TX bytes" | cut -d: -f3 | awk '{ print $1 }'`
	let RXbps="($readRX2 - $readRX1) * 8"
	let TXbps="($readTX2 - $readTX1) * 8"
	echo "\"$sec\";\"$dev\";\"$RXbps\";\"$TXbps\"" >> ${DESTDIR}/${dev}_traffic_in_bps.csv
    done
done

# Copy the statistics files into the dest Directory
cp -ar ${TIMDIR}/logs/protocolstats ${DESTDIR}/
cp -ar ${TIMDIR}/logs/protocolstats1 ${DESTDIR}/

# Make a Tar-Ball of all data
cd ${BASEDIR}

DATE=`date +%Y%m%d`
tar zcf ${DATE}-Performance-data-${Identifier}.tar.gz data/* &> /dev/null
chmod 644 ${DATE}-Performance-data-${Identifier}.tar.gz

if [ -f ${BASEDIR}/origin.cfg ]
then
    source ${BASEDIR}/origin.cfg
    chown -R ${USERNAME}.${GRPNAME} ${BASEDIR}/data
    chown ${USERNAME}.${GRPNAME} ${DATE}-Performance-data-${Identifier}.tar.gz
fi

echo "Cleaning up..."
rm -rf ./data

echo "> Performance data has been dumped to"
echo ">>> File: ${DATE}-Performance-data-${Identifier}.tar.gz"
echo

# Lock program
Unlock $LockFile


# -------------------------------------------------------------
#
# End of /etc/cron.hourly/collect-data.sh
#
