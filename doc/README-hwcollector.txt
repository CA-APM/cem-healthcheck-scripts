
===============================================================================
== collect-data.sh ============================================================
===============================================================================

This script will collect information on the Hardware and the Operating 
system it runs on to be added to a known to work database for common 
usage. The data that will be collected is mainly Hardware information
as Manufacturer/Vendor, hardware information as Memory installed, disk 
storage capacity, CPU type and speed, number of network interfaces and
eventual addon cards. If addon-cards are found, this script will try to 
extract some more details on these cards.
The details will be Adapter type description, manufacturer, and what 
extras this card provides.

On top of that - this script will extract the information on the running 
Operating system (and if it was installed from one of the Kickstart Images
provided by CA, which kickstart image it was).

===============================================================================
== When to use ? ==============================================================
===============================================================================

Install the appliance with the provided Operating system and software,
then run this script !


===============================================================================
== How to install and use ? ===================================================
===============================================================================

This is a script that is to be executed from it's location.  Copy the
script to a system to certify, untar the archive, change into the
created directory, execute the script - and answer the questions.

[root@mars ~]$ tar zxvf sysinfo-collector-1.0-71.el5.noarch.tar.gz 
sysinfo-collector-1.0/
sysinfo-collector-1.0/collect-data.sh
sysinfo-collector-1.0/.pci.ids
sysinfo-collector-1.0/.sysinfo_filter.sed
sysinfo-collector-1.0/CHANGELOG
sysinfo-collector-1.0/.sysinfo_yesno.sed
sysinfo-collector-1.0/README.txt
sysinfo-collector-1.0/.build
sysinfo-collector-1.0/mod/
sysinfo-collector-1.0/mod/share.inc
[root@mars ~]$ cd sysinfo-collector-1.0
[root@mars sysinfo-collector-1.0]$ ./collect-data.sh


===============================================================================
== System details extraction started ... ======================================
===============================================================================
> OS: RedHat 5.8


===============================================================================
== Extracting dependency information. This can take a while... ================
===============================================================================
Unsatisfied dependencies for fipscheck-1.2.0-1.el5.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for lynx-2.8.5-28.1.el5_2.1.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for NetworkManager-0.7.0-13.el5.i386: openssl
Unsatisfied dependencies for NetworkManager-0.7.0-13.el5.x86_64: openssl
Unsatisfied dependencies for ipsec-tools-0.6.5-14.el5_5.5.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for distcache-1.4.5-14.1.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for mod_ssl-2.2.3-43.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit), openssl >= 0.9.7f-4, openssl >= 0.9.8e-12.el5_4.4
Unsatisfied dependencies for openldap-2.3.43-25.el5_8.1.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for gnupg-1.4.5-14.el5_5.1.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for bind-utils-9.3.6-20.P1.el5_8.1.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for wget-1.11.4-3.el5_8.2.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for openldap-2.3.43-25.el5_8.1.i386: libcrypto.so.6, libssl.so.6
Unsatisfied dependencies for curl-7.15.5-15.el5.i386: libcrypto.so.6, libssl.so.6, openssl
Unsatisfied dependencies for python-libs-2.4.3-46.el5_8.2.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for stunnel-4.15-2.el5.1.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for libpcap-0.9.4-15.el5.x86_64: openssl
Unsatisfied dependencies for pam_ccreds-3-5.i386: libcrypto.so.6
Unsatisfied dependencies for wpa_supplicant-0.5.10-9.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for sendmail-8.13.8-8.1.el5_7.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit), openssl
Unsatisfied dependencies for curl-7.15.5-15.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit), openssl
Unsatisfied dependencies for ntp-4.2.2p1-15.el5_7.1.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for quota-3.13-5.el5.x86_64: libssl.so.6()(64bit)
Unsatisfied dependencies for m2crypto-0.16-8.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for pyOpenSSL-0.6-2.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for libpcap-0.9.4-15.el5.i386: openssl
Unsatisfied dependencies for pam_ccreds-3-5.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for bind-libs-9.3.6-20.P1.el5_8.1.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for postgresql-libs-8.1.23-5.el5_8.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for gnome-vfs2-2.16.2-8.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)
Unsatisfied dependencies for tcpdump-3.9.4-15.el5.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for cyrus-sasl-2.1.22-5.el5_4.3.x86_64: libcrypto.so.6()(64bit)
Unsatisfied dependencies for httpd-2.2.3-43.el5.x86_64: libcrypto.so.6()(64bit), libssl.so.6()(64bit)


===============================================================================
== Detecting system hardware ==================================================
===============================================================================
> Raid: LSI Logic / Symbios Logic MegaRAID SAS 2108 [Liberator] (rev 05)
> Network: Broadcom Corporation NetXtreme II BCM5709 Gigabit Ethernet (rev 20)
> Network: Broadcom Corporation NetXtreme II BCM5709 Gigabit Ethernet (rev 20)
> Plattform: IBM System x3690 X5 7148AC1


===============================================================================
== OS installation image ======================================================
===============================================================================

=== Valid responses: "Image Name", Unknown !  =================================
*** You used an official Image for installing this device.
*** Please provide the Image name if you have it.
*** Enter "Unknown" if you don't know, Example "apm-rhel5u5-x86_64-es-dvd.iso"
>>> Image: apm-rhel5u5-x86_64-es-dvd.iso

=== Used image: apm-rhel5u5-x86_64-es-dvd.iso !  ==============================


===============================================================================
== Certification process ======================================================
===============================================================================
Please answer the following questions to enable the
certification process of the Hardware to be processed. 
>>> Detected Hardware: System x3690 X5 7148AC1


===============================================================================
== Operating system installation ==============================================
===============================================================================
*** Did any error showed up during the installation of the Operating
*** system. This also means, that the RedHat installer did
*** not issue any warning.

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> Did the RedHat Installation went Ok ? [y/n/na/u]: y


===============================================================================
== Hardware component functionality, driver compatibility =====================
===============================================================================
*** Have all disks been recognized, and do the network cards
*** provide connectivity as expected ?

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> All hardware does work ? [y/n/na/u]: y


===============================================================================
== Installation Media ejection ================================================
===============================================================================
*** When installing a system with a CDRom, if the media is not
*** ejected after installation, it can result into an installation loop.

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> Was the Installation Media ejected after install: [y/n/na/u]: y


===============================================================================
== System reboot capability ===================================================
===============================================================================
*** The installer may install a different kernel than used during
*** installation. So if the reboot works, the kernel and the hardware
*** are compatible.

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> Did the system reboot correctly after installation ? [y/n/na/u]: y


===============================================================================
== CA Software installation ===================================================
===============================================================================

=== Found Software: Tim 9.1.2.0 build 435778 !  ===============================


===============================================================================
== Target Software installation status ========================================
===============================================================================
*** In this case, all required components are meant.
*** Example in case of the TIM: third-party and tim-complete !

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> Did the installation of "Tim 9.1.2.0 build 435778" went OK ? [y/n/na/u]: y


===============================================================================
== Firstboot: Initial system configuration ====================================
===============================================================================
*** The First Boot Screen gives the Admin to possibility to perform the
*** initial configuration of network interfaces, timezone, firewall etc.

=== Valid responses: y=Yes | n=No | na=Not Available | u=Unknown !  ===========
>>> Did the FirstBoot screen appear ? [y/n/na/u]: y


===============================================================================
== Tester Details =============================================================
===============================================================================
*** In case some questions on the certification process need to
*** be clarified, best is to contact the person who has performed
*** the installation and the testing.
*** Please provide the "Lastname, Firstname <E-Mail>" of that person.
*** This information will solely be used in case there are questions
*** regarding this HW certification data.

=== Valid responses example: Foo, Bar [bar.foo@ca.com] !  =====================
>>> Tester details: Mertin, Joerg [joerg.mertin@ca.com]


===============================================================================
== Testers Comment ============================================================
===============================================================================
*** Anything that would help the certification process, like comments 
*** on what was done to cirvumvent an issue etc. would be welcome.
*** Please don't hit the <ENTER> key to go onto the next line, as it would
*** send the comment.

=== Enter your comment below !  ===============================================
The dependencies are due to replacement of the openssl library by a CA own one.


===============================================================================
== Archive: 20130304-IBM_System_x3690_X5_7148AC1-sysinfo-collector.tar.gz =====
===============================================================================
>>> Please send this archive to joerg.mertin@ca.com for
>>> the hardware details to be included into the TIM/APM
>>> Hardware Compatibility Matrix !!!
>>> The data that will be submitted can be visualized in
>>> the data directory !
================================================================================

[root@mars sysinfo-collector-1.0]# ls -l 20130304-IBM_System_x3690_X5_7148AC1-sysinfo-collector.tar.gz 
-rw-r--r-- 1 root root 2310 Mar  4 19:55 20130304-IBM_System_x3690_X5_7148AC1-sysinfo-collector.tar.gz
