#!/bin/sh
#
# Internal ID & Revision:
# $Id: apm-hwcollector.mod,v 1.7 2015/08/11 13:16:00 jmertin Exp $
# $Revision: 1.7 $
#
# File Name & location:
# collect-data.sh
#
# Short description:

# This little script will collect hardware information on the
# currently running system, and in case it has been installed using a
# third-party kickstart Image from te SWAT Team, also provide the
# details on the installation image.
# In case a Napatech card is found - it will also extract detailed
# information on the installed Napatech device.
# Output will be a SQL file ready to be imported into a Compatibility
# DB.
#
# Requirements:
# [Mandatory] - has to be execute as root. Will read the PCI listing
#               and dmidecode to identify the hardware/vendor
# [Mandatory] - LSB Compliant pakages must be installed.
#
# No error handling is implemented to enable this script to run until
# the end even if errors show up. Note - this script performs only
# read operations on the system, and writes the data into one file.
#
# Limitations: Only 1 Napatech card will be identified as it is not
# required to know the number of installed cards. It does not affect
# the installation capability of the system.
#
# -------------------------------------------------------------
#
# Programm Version
VER="$Revision: 1.7 $"
#
# Programm name
PROGNAME="`basename $0 .sh`"
#
# Defining search path.
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
#
# Supported row-data version
VERSION=2
#
# Directory we work in.
BASEDIR=`pwd`

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"
SHAREMOD="${BASEDIR}/mod/apm-share.mod"

# Define the Hostname
HOSTName=`hostname -s`

# Build Date in reverse - Prefix to builds
DATE=`date +"%Y%m%d"`

# IP - This is just to gfrab the first available IP adress
IPAdd=`ifconfig | grep "inet addr:" | head -1 | awk '{ print $2}' | sed -e 's/addr\://g'`

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"
#
LINE="================================================================================" 

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

# Time Stamp - when data was collected
TimeStamp=`date +"%F %T"`
#
# Glue TimeStamp for data-sets.
TimeStampS=`date +%s`
#
# Root Check
check_useruid

# Log program version.
echo "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh v$VER (apm-scripts ${RELEASE}-b${BUILD})"
echo $LINE

if [ -d data ]
then
    echo "!!! Detected old data directory. Purging..."
    rm -rf data
fi

echo
echo "System details extraction started ..."
echo $LINE

# make the collection point
mkdir -p data

# IP - This is just to gfrab the first available IP adress
SYSID=`ifconfig eth0 | grep HWaddr | md5sum | cut -d ' ' -f 1`

echo "VERSION=${VERSION}" > data/capture_version.txt
echo "GLUE=${TimeStampS}" >> data/capture_version.txt
echo "SYSID=${SYSID}" >> data/capture_version.txt
echo "APMSCR=\"apm-scripts-${RELEASE}-b${BUILD}\"" >> data/capture_version.txt

echo "# $TimeStamp $PROGNAME ver$VER (apm-scripts ${RELEASE}-b${BUILD})" > data/systemdata.sql

# Add own pciids file. Updated when generating archive.
PCIIDS="-i .pci.ids"

# Product name
ProdName=`dmidecode -s system-product-name | sed -f .hwdata_filter.sed`

# Vendor
Vendor=`dmidecode -s system-manufacturer | sed -f .hwdata_filter.sed` 

# Get OS-Version
if [ `which lsb_release 2>/dev/null` ]
then
    OSManufacturer=`lsb_release -si`
    OSRelease=`lsb_release -sr`
else
    OSManufacturer=`apmhwdata`    
fi

# Manufacturer/Distribution maker
if [ `echo $OSManufacturer | grep -ic RedHat` -gt 0 ]
then
    OSVendor=RedHat
    PKGTYPE=RPM
elif [ `echo $OSManufacturer | grep -ic CentOS` -gt 0 ]
then
    OSVendor=CentOS
    PKGTYPE=RPM
elif [ `echo $OSManufacturer | grep -ic Suse` -gt 0 ]
then
    OSVendor=Suse
    PKGTYPE=RPM
elif [ `echo $OSManufacturer | grep -ic Ubuntu` -gt 0 ]
then
    OSVendor=Ubuntu
    PKGTYPE=DEB
elif [ `echo $OSManufacturer | grep -ic Debian` -gt 0 ]
then
    OSVendor=Debian
    PKGTYPE=DEB
else
    OSVendor=Unknown
    PKGTYPE=NONE
fi

# OS Release for inclusion into Plattform Tag
OSRunTag="$OSVendor $OSRelease"
echo "> OS: $OSRunTag"

# Total Memory to the System
MemTot=`cat /proc/meminfo | grep MemTotal: | awk '{print $2}'`
MemTotGB=`echo "scale=3; $MemTot / 1024 / 1024" | bc`
# CPU Info
#CPUInfo=`dmidecode -s processor-version | head -1`
CPUInfo=`cat /proc/cpuinfo | grep "model name" | head -1 | cut -d ':' -f 2 | sed -f .hwdata_filter.sed`
# CPU Info
#CPUSpeed=`dmidecode -s processor-frequency | head -1 | awk '{print $1}'`
CPUSpeed=`cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d ':' -f 2 | sed -f .hwdata_filter.sed`
# CPUCores / Number of CPU Cores 
CPUCores=`cat /proc/cpuinfo | grep processor | wc -l`
# Number of network interfaces
NetInts=`lspci | egrep -i "network|ethernet | grep controller" | wc -l`
# Disk size
DiskSize=`cat /proc/partitions | grep da$ | head -1 | awk '{print $3}'`
let DiskSizeGB=($DiskSize / 1024 / 1024)

echo "> Extracting dependency information. This can take a while..."

if [ "$PKGTYPE" == "RPM" ]
then
    rpm -qaV 2> /dev/null | grep "Unsatisfied dependencies" > data/dependency.check
    cat data/dependency.check

    title "Computing RPM list"
    rpm -qa --nosignature --queryformat '%{NAME};%{VERSION};%{RELEASE};%{ARCH}\n' > data/rpmlist.txt
fi

echo "> Detecting system hardware"

# Check for Napatech cards in system
Napatech=`lspci | grep "Napatech" | wc -l`

if [ ${Napatech} -gt 0 ]
then
    lspci $PCIIDS | grep Napatech  > data/napatech.card.details.txt
    NptID=`head -1 data/napatech.card.details.txt | awk '{print $1}'`

    NapatechMan="Napatech"
    NapatechDesc=`grep Napatech data/napatech.card.details.txt | head -1 | cut -d ':' -f 3 | sed -f .hwdata_filter.sed`
    NapatechNum=`cat data/napatech.card.details.txt | wc -l`

    if [ -x /opt/napatech/bin/AdapterInfo ]
    then
	# Make sure we can work with the Napatech Libs.
	export LD_LIBRARY_PATH=/opt/napatech/lib:$LD_LIBRARY_PATH

	# Extract the Adapterinfo
	/opt/napatech/bin/AdapterInfo >> data/napatech.card.details.txt

	if [ "$OSRelease" == "4" ]
	then
	    NapatechSer=`lspci -n -s $NptID | awk '{print $4}'`
	else
	    NapatechSer=`lspci -n -s $NptID | awk '{print $3}'`
	fi
	NapatechSpec=`grep "Adapter type" data/napatech.card.details.txt | head -1 | cut -d ':' -f 2 | sed -f .hwdata_filter.sed`

	# Make the SQL Query
	echo "INSERT INTO ks_addon SET ks_glue_id=\"${TimeStampS}\",ks_addon_type=\"Network capture card\",ks_addon_identifier=\"${NapatechSer}\",ks_addon_manufacturer=\"${NapatechMan}\",ks_addon_description=\"${NapatechDesc}\",ks_addon_num=\"${NapatechNum}\",ks_addon_specifics=\"${NapatechSpec}\";" >> data/systemdata.sql

	echo "> Napatech: $NapatechDesc"

    else
	NapatechSer=""
	NapatechSpec="Unknown"
    fi

else
    NapatechSer=""
fi

# Raid Interface Cards in system
Raid=`lspci | grep -i "raid" | wc -l`

if [ ${Raid} -gt 0 ]
then

    # Check out on standard network cards
    for RaidID in `lspci $PCIIDS | egrep -i "raid" | awk '{print $1}'`
    do

	lspci $PCIIDS -v -s $RaidID > data/RaidID-${RaidID}.txt

	if [ "$OSRelease" == "4" ]
	then
	    RaidSer=`lspci -n -s $RaidID | awk '{print $4}'`
	else
	    RaidSer=`lspci -n -s $RaidID | awk '{print $3}'`
	fi
	RaidMan=`grep controller data/RaidID-${RaidID}.txt | cut -d ':' -f 3 | awk '{print $1}'`
	RaidDesc=`grep "controller" data/RaidID-${RaidID}.txt | cut -d ':' -f 3 | sed -f .hwdata_filter.sed`
	RaidSpec=`grep "Subsystem" data/RaidID-${RaidID}.txt | cut -d ':' -f 2 | sed -f .hwdata_filter.sed`
	
        # Make the SQL Query
	echo "INSERT INTO ks_addon SET ks_glue_id=\"${TimeStampS}\",ks_addon_type=\"RAID controller\",ks_addon_identifier=\"${RaidSer}\",ks_addon_manufacturer=\"${RaidMan}\",ks_addon_description=\"${RaidDesc}\",ks_addon_num=\"1\",ks_addon_specifics=\"${RaidSpec}\";" >> data/systemdata.sql

	echo
	echo "> Raid: $RaidDesc"
    done
fi

# Check out on standard network cards
for netID in `lspci $PCIIDS | egrep -i "network|ethernet" | awk '{print $1}'`
do
    lspci $PCIIDS -v -s $netID > data/netID-${netID}.txt

    if [ "$OSRelease" == "4" ]
    then
	NetSer=`lspci -n -s $netID | awk '{print $4}'`
    else
	NetSer=`lspci -n -s $netID | awk '{print $3}'`
    fi

    NetMan=`grep controller data/netID-${netID}.txt | cut -d ':' -f 3 | awk '{print $1}'`
    NetDesc=`grep "controller" data/netID-${netID}.txt | cut -d ':' -f 3 | sed -f .hwdata_filter.sed`
    NetSpec=`grep "Subsystem" data/netID-${netID}.txt | cut -d ':' -f 2 | sed -f .hwdata_filter.sed`

    if [ `echo $NetDesc | grep -c Napatech` -lt 1 ]
    then
	echo "INSERT INTO ks_addon SET ks_glue_id=\"${TimeStampS}\",ks_addon_type=\"Network card\",ks_addon_identifier=\"${NetSer}\",ks_addon_manufacturer=\"${NetMan}\",ks_addon_description=\"${NetDesc}\",ks_addon_num=\"1\",ks_addon_specifics=\"${NetSpec}\";" >> data/systemdata.sql
    fi

done

# Plattform stuff
echo "INSERT INTO ks_plattform SET ks_plattform_ts=\"${TimeStamp}\",ks_plattform_prod_name=\"${ProdName}\",ks_plattform_vendor=\"${Vendor}\",ks_plattform_os=\"$OSRunTag\",ks_plattform_net_ints=\"${NetInts}\",ks_plattform_memory=\"${MemTotGB}\",ks_plattform_raid_controller=\"${Raid}\",ks_plattform_disk_capacity=\"${DiskSizeGB}\",ks_plattform_cpu_type=\"${CPUInfo}\",ks_plattform_cpu_speed=\"${CPUSpeed}\",ks_plattform_cpu_cores=\"${CPUCores}\",ks_plattform_glue=\"${TimeStampS}\";" >> data/systemdata.sql

echo "> Plattform: ${Vendor} ${ProdName}"

# OS Stuff starts here
if [ -f /etc/CA/CA_BUILD.hist ]
then
    # We have a UpClone Image - we can extract some data
    ImageString=`grep "Build Target:" /etc/CA/CA_BUILD.hist | cut -d ':' -f 5 | sed -f .hwdata_filter.sed`
    ImageString2=`grep "Source Dir:" /etc/CA/CA_BUILD.hist | cut -d ':' -f 5 | sed -f .hwdata_filter.sed`


    # Build Number
    IsoBuild=`grep "Source IsoBuild " /etc/CA/CA_ALL | head -1 | awk '{print $6}' | sed -f .hwdata_filter.sed`

    # ACtual ISO CD Build number
    CDBuild=`grep "Start Build:" /etc/CA/CA_BUILD.hist | cut -d ':' -f 5 | sed -f .hwdata_filter.sed`

    # Build Tag
    BuildTag=`grep "Build Tag:" /etc/CA/CA_BUILD.hist | sed -e 's/_//g' | cut -d ':' -f 5  | sed -f .hwdata_filter.sed`

else
    # We have a dumb Image/RedHat.
    ImageString="Unknown"
    IsoBuild="N/A"
    CDBuild="N/A"
    BuildTag="NULL"

fi

echo
echo "OS installation image"
echo "$LINE" 

if [ -d /etc/CA ]
then
    echo "*** Field provided installation image detected"
    echo "*** Extracting data"
    ImageComment="Field made Image"

else
    echo "*** You used an official Image for installing this device."
    echo "*** Please provide the Image name if you have it."
    echo "*** Enter \"Unknown\" if you do not know, Example \"apm-rhel5u5-x86_64-es-dvd.iso\"" # '
    entrynl "Valid responses: \"Image Name\", Unknown"
    echo -n ">>> Image: "
    read ImageString
    ImageComment="Official CA Image"

fi

# This is to determine the initial installation release. If it exists, take it.
# An Update of the OS will change the lsb_release string.
if [ -f /etc/CA/.mkiso ]
then
    source /etc/CA/.mkiso
    ImageRel=`echo $RHREL | sed -f .cleanos.sed`
    if [ -z "$ImageRel" ]
    then
      ImageRel=`echo $CENTOS | sed -f .cleanos.sed`
    fi
fi

# If everyting is empty, fall-back to lsb_data
if [ -z "$ImageRel" ]
then
    ImageRel="`lsb_release -sr`"
fi

# Save it for Tar-Log-File
ImageRelTar="$ImageRel"

ImageStringCleaned=`echo "${ImageString2} ${ImageString}" | sed -f .hwdata_filter.sed`

ImageOS=`lsb_release -si`
Arch=`uname -i`

# installation image stuff
echo "INSERT INTO ks_image SET ks_image_ts=\"${TimeStamp}\",ks_image_string=\"$ImageStringCleaned\",ks_isobuild=\"${IsoBuild}\",ks_image_build=\"${CDBuild}\",ks_image_os=\"${OSVendor}\",ks_image_os_rel=\"$ImageRel\",ks_image_os_type=\"${ImageOS}\",ks_image_os_arch=\"${Arch}\",ks_image_build_tag=\"${BuildTag}\",ks_image_plattform_glue=\"${TimeStampS} \",ks_image_comment=\"$ImageComment\" ON DUPLICATE KEY UPDATE ks_image_plattform_glue = CONCAT(ks_image_plattform_glue,\"${TimeStampS} \");" >> data/systemdata.sql

ANSWERS="Valid responses: y=Yes | n=No | na=Not Available | u=Unknown"

# Asking some questions to the Certification process.
echo
echo $LINE
echo "Certification process"
echo $LINE
echo "Please answer the following questions to enable the"
echo "certification process of the Hardware to be processed. "
echo ">>> Detected Hardware: $ProdName"

echo
echo $LINE
echo "Operating system installation"
echo "*** Did any error showed up during the installation of the Operating"
echo "*** system. This also means, that the $OSVendor installer did"
echo "*** not issue any warning."
entrynl $ANSWERS
echo -n ">>> Did the $OSVendor Installation went Ok ? [y/n/na/u]: "
read InstallOk
InstallOk=`echo $InstallOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

echo
echo $LINE
echo "Hardware component functionality, driver compatibility"
echo "*** Have all disks been recognized, and do the network cards"
echo "*** provide connectivity as expected ?"
entrynl $ANSWERS
echo -n ">>> All hardware does work ? [y/n/na/u]: "
read DriversOk
DriversOk=`echo $DriversOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

echo
echo $LINE
echo "Installation Media ejection"
echo "*** When installing a system with a CDRom, if the media is not"
echo "*** ejected after installation, it can result into an installation loop."
entrynl $ANSWERS
echo -n ">>> Was the Installation Media ejected after install: [y/n/na/u]: "
read CDOk
CDOk=`echo $CDOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

echo
echo $LINE
echo "System reboot capability"
echo "*** The installer may install a different kernel than used during"
echo "*** installation. So if the reboot works, the kernel and the hardware"
echo "*** are compatible."
entrynl $ANSWERS
echo -n ">>> Did the system reboot correctly after installation ? [y/n/na/u]: "
read RebootOk
RebootOk=`echo $RebootOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`
echo


# TIM Detection
if [ -f /var/www/cgi-bin/wily/packages/cem/tim/description ]
then
    # Check where the Description file is.
    DESCFILE="/var/www/cgi-bin/wily/packages/cem/tim/description"
else
    CHECKTIM=`rpm -q tim`
    if [ "$CHECKTIM" == "package tim is not installed" ]
    then
	DESCFILE="/var/www/cgi-bin/wily/packages/cem/tim/description"
    else
	DESCFILE="`rpm -ql tim | grep 'description$'`"
    fi
fi

echo $LINE
echo "CA Software installation"

if [ -f $DESCFILE ]
then
    TargetSoftVersion=`cat $DESCFILE | sed -f .hwdata_filter.sed`
    echo "Found Software: $TargetSoftVersion"
    
else
	echo "*** Valid responses: Software release example:  TIM 9.1.5.0"
	echo -n ">>> Which CA Software Version did you install ? : "
	read TargetSoftVersion
	TargetSoftVersion="`echo $TargetSoftVersion | sed -f .hwdata_filter.sed`"
fi

echo
echo $LINE
echo "Target Software installation status"
echo "*** In this case, all required components are meant."
entrynl $ANSWERS
echo -n ">>> Did the installation of \"$TargetSoftVersion\" went OK ? [y/n/na/u]: "
read TargetSoftInstallOk
TargetSoftInstallOk=`echo $TargetSoftInstallOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

echo
echo $LINE
echo "Firstboot: Initial system configuration"
echo "*** The First Boot Screen gives the Admin to possibility to perform the"
echo "*** initial configuration of network interfaces, timezone, firewall etc."
entrynl $ANSWERS
echo -n ">>> Did the FirstBoot screen appear ? [y/n/na/u]: "
read FirstBootOk
FirstBootOk=`echo $FirstBootOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

echo
echo $LINE

if [ -d /etc/CA ]
then
    echo "Console Pre Login system information screen"
    echo "*** The reissue field-pack provides system information on the"
    echo "*** console login screen."
    entrynl $ANSWERS
    echo -n ">>> Did the system information showed up on the console ? [y/n/na/u]: "
    read ReissueOk
    ReissueOk=`echo $ReissueOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

    echo "System hardening check"
    echo "*** The Field provided installation media provides a basic hardening"
    echo "*** of the system. The hardening run can be seen at the end of the"
    echo "*** installation after exiting the firstboot screen."
    echo "*** However, if the system \"forced\" you to change the caadmin password"
    echo "*** after the first login, the system \"has\" been hardened !"
    entrynl $ANSWERS
    echo -n ">>> Has the system been hardened ? [y/n/na/u]: "
    read HardeningOk
    HardeningOk=`echo $HardeningOk | sed -f .hwdata_filter.sed -f .hwdata_yesno.sed`

else
    ReissueOk="N/A"
    HardeningOk="N/A"
fi

DepCheck=`cat data/dependency.check | wc -l`
if [ $DepCheck -gt 0 ]
then
    DepOk="Failed"
else
    DepOk="Ok"
fi

echo
echo $LINE
echo "Tester Details"
echo "*** In case some questions on the certification process need to"
echo "*** be clarified, best is to contact the person who has performed"
echo "*** the installation and the testing."
echo "*** Please provide the \"Last Name, First Name <E-Mail>\" of that person."
echo "*** This information will solely be used in case there are questions"
echo "*** regarding this HW certification data."
entrynl "Valid responses example: Foo, Bar [bar.foo@ca.com]"
echo -n ">>> Tester details: "
read TesterDetails
TesterDetails=`echo $TesterDetails | sed -f .hwdata_filter.sed`

echo
echo $LINE
echo "Testers Comment"
echo "*** Anything that would help the certification process, like comments "
echo "*** on what was done to cirumvent an issue etc. would be welcome."
echo "*** If you need to add more than a one-liner, please send the details in the"
echo "*** mail you attach the certification request log ! Hit [ENTER] to finish"
echo $LINE
echo -n "Text: "
read TesterComment

TesterCommentClean=`echo $TesterComment | tr -cd '[:alnum:] [:space:] [:punct:]' | sed -f .hwdata_filter.sed`

# Gather the Current running OS release
ImageUpdRel=`lsb_release -sr`
if [ "$ImageUpdRel" == "$ImageRel" ]
then
    # In case no upgrade took place - NULL it.
    ImageUpdRel=NULL
fi


# installation image stuff
echo "INSERT INTO ga_test SET ga_test_date=\"${TimeStamp}\",ga_ks_plattform_glue=\"${TimeStampS}\",ga_target_tag=\"${INSTALLTAG}\",ga_os_install=\"$InstallOk\",ga_os_drivers=\"$DriversOk\",ga_os_cdeject=\"$CDOk\",ga_os_hardening=\"$HardeningOk\",ga_target_reissue=\"$ReissueOk\",ga_os_reboot=\"$RebootOk\",ga_target_soft_install=\"$TargetSoftInstallOk\",ga_target_soft_version=\"$TargetSoftVersion\",ga_target_firstboot=\"$FirstBootOk\", ga_os_dependency_check=\"$DepOk\",ga_tester_details=\"$TesterDetails\",ga_os_upgrade=\"$ImageUpdRel\",ga_test_comment=\"$TesterCommentClean\";"  >> data/systemdata.sql


# Glue stuff together.
# -> Update ks_plattform_id through glue identifier in ga_test
echo "UPDATE ga_test SET ga_ks_plattform_id=( SELECT ks_plattform_id FROM ks_plattform WHERE ks_plattform_glue=${TimeStampS} ) WHERE ga_ks_plattform_glue=${TimeStampS};" >> data/systemdata.sql

# -> Update ks_image_id through glue identifier in ga_test
echo "UPDATE ga_test SET ga_ks_image_id=( SELECT ks_image_id FROM ks_image WHERE ks_image_plattform_glue LIKE \"%${TimeStampS}%\" LIMIT 1 ) WHERE ga_ks_plattform_glue=${TimeStampS};" >> data/systemdata.sql


# Make a Tar-Ball of all data
DATE=`date +%Y%m%d`
VName="$Vendor $ProdName"
TarName=`echo "${DATE}-${VName}-${ImageRelTar}" | sed -f .filename_filter.sed`

tar zcf ${TarName}-hwdata-collector.tar.gz data/* &> /dev/null
chmod 644 ${TarName}-hwdata-collector.tar.gz

echo
echo $LINE

if [ -f ${BASEDIR}/origin.cfg ]
then
    source ${BASEDIR}/origin.cfg
    chown -R ${USERNAME}.${GRPNAME} ${BASEDIR}/data
    chown ${USERNAME}.${GRPNAME} ${TarName}-hwdata-collector.tar.gz
fi

echo ">>> Logfile stored in archive file. Please send to CA Support"
echo ">>> for inclusion in the HW Copmpatibility DB."
echo ">>> File: ${TarName}-hwdata-collector.tar.gz"
echo
echo

# Remove logfile - not required.
rm -f $LogFile

# -------------------------------------------------------------
#
# End of /etc/cron.hourly/collect-data.sh
#
