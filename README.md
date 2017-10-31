# fieldpack.apm-scripts 1.20-91 by J. Mertin -- joerg.mertin(-AT-)ca.com
Purpose: Provides scripts to collect data for troubleshooting an APM 9.x or later installation

# Description
The apm-scripts can be installed at any location and provide an
interactive interface to collect data for specific needs
(Troubleshooting, Performance/Hardware analysis or Health-check).  

The Log, Performance-data or hardware import files will be located in
the same directory from which the `apm-interact.sh` script was executed.

At this moment, the apm-scripts package provides 9 sub-functions:
 - **CIPHER**: Verify cipher compatibility between local machines
   cryptolybraries and a remote HTTPS Server. It will provide
   compatible cypher list, and if the specific cipher can be decrypted
   by the TIM decryuption engine.
 - **EM**: Extracts logs on APM EM/MoM
 - **HWCOLL**: Collects hardware info for running TIM (RedHat/CentOS
   only). This data can be imported into the hardware Compatibility
   Database.
 - **PCAP**: Generates a packet capture (Will take tethreal, tshark,
   tcpdump or buildpcap - whichever is available). Duration limited
   to 10Minutes, and size to 1GByte.
 - **PHP**: Extracts log information on APM PHP Agent
 - **PSQL**: Checks PostgreSQL DB status and content, and extracts special
   metrics to evaluate the health of the APM installation.
 - **SYS**: Performs a system log extraction (Most data the regular log-collectors don't get).
 - **TIM**: Extracts TIM specific log information
 - **TIMPERF**: Collects performance data on currently running TIM. This
   data can be imported into the performance analysis DB (CA Internal)

For detailed description on the subscripts, please check the doc directory.

## Short Description
The apm-scripts can be installed on any APM system running under Linux
and provide an interactive command line interface to collect data for
specific needs (Troubleshooting, Performance/Hardware analysis or
Health-check).

## APM version
So far - the apm-scripts have been tested with APM v9.0 up to 10.x installations
running under RedHat/CentOS Linux 5.x / 6.x

## Installation Instructions

#### Prerequisites

- CentOS/RedHat 5.x or 6.x (It can run on other distributions, but has
  been primarily targeted at CentOS/RedHat type systems)
- APM EM 9.x, TIM 9.x or newer
- The apm-scripts can require root-access for certain data
  extraction. In that case the credentials will be requested
- The "Bourne-Again SHell" (bash) is required (/bin/sh needs to point
  to the bash).
- Consider installing mtr, wireshark and pstack by issuing the
  following commands:  
  `~# sudo yum install wireshark mtr pstack`  
  This will greatly increase the outcome of the data-collection log and
  permit a preliminary analysis of the traffic quality coming in
  through the SPAN Port

_Note: if prelinking messages show up, your system did not prelink the
  binaries with the existing libraries.  
  Consider prelinking by running the following command:  
  `~# sudo prelink -a`  
  from the command line._

#### Installation

Install the script-collection by unpacking it into a directory of your
choice, or cloning it through github.

`[caadmin@localhost ~]$ unzip ~/Downloads/fieldpack.apm-scripts-master.zip`


#### Configuration

The CLUI will request data if required. Running the script
`apm-interact.sh` the first time will request optional information as
Customer Name, contact EMail and Ticket/Case number if existing. This
data will be written into the resulting data-logfile.

_Note: the data is stored in a text-file inside the same directory and
sourced to provide defaults on the next execution of the script. This
is also done for every called subroutine._

#### Usage Instructions

The script provides a command-line interface and tries to guess most
of the data required itself. In case there are choices or unknown
elements, the user will have to enter the data interactively

_Note: In case the script does require superuser access, it will ask
so using sudo prior the subroutine call._

After executing `./apm-interact.sh` (_Note the **`./`** in front_), the user
will be presented with the following CLUI:
```
[caadmin@localhost ~]$ cd fieldpack.apm-scripts-master/
[caadmin@localhost fieldpack.apm-scripts-master]$ ./apm-interact.sh  
[sudo] password for caadmin:   
 >> Customer Name [CA Test]:  
 >> Name + EMail [demo.user@nodomain.com]:  
 >> Support Ticket Nr. [123456]:  
One line description of issue: 
================================================================================  
health-check data capture

Chose the action to perform  
================================================================================  
 * CIPHER: Verify cipher compatibility between this TIM and a remote HTTPS Server  
 * EM: Extracts logs on APM EM/MoM  
 * EXIT: Exit data collection  
 * HWCOLL: Collects hardware info for running TIM (RedHat/CentOS only)  
 * PCAP: Generates a packet capture  
 * PHP: Extracts log information on APM PHP Agent  
 * PSQL: Checks PostgreSQL DB status and content  
 * SYS: Performs a system log extraction  
 * TIM: Extracts log information on APM TIM  
 * TIMPERF: Collects performance data on currently running TIM  
================================================================================  
 >> Choose action: 
```
Choose the action to perform: em or EM to extract logs for a EM installation.  
_Note: The commands are case insensitive. You can also type q or Q to exit._

Please only execute the data-collection where it makes sense:

| FUNCTION | TIMPERF | TIM | SYS | PSQL | EM | CIPHER | HWCOLL | PCAP |
|---------:|:-------:|:---:|:---:|:----:|:--:|:------:|:------:|:----:|
| TIM	   |	X    |  X  |  X  |      |    |   X    |   X    |   X  |
| MTP 	   |	X    |  X  |  X  |      |    |   X    |   X    |   X  |
| EM 	   |	     |     |  X  |      |  X |   X    |   X    |      |
| MoM	   |	     |     |  X  |   X  |  X |   X    |   X    |      |
|TESS v4.5 |	     |     |  X  |   X  |  X |   X    |   X    |      |


_Note2: All systems and applications are different. Sometimes a
program will not be found at the right location or the arguments of
the programs have changed through a new version. In that case - errors
may show up during data collection, but these will be interpreted as
non fatal and hopefully the next function will be executed. In case
the execution stops, open an issue_

## Limitations
This script-collection is only meant to run on RedHat/CentOS 5.x or
6.x. It may run on other Linux distributions, but that is no garantee.



## License
This field pack is provided under the [Eclipse Public License, Version
1.0](https://github.com/CA-APM/fieldpack.apm-scripts/blob/master/LICENSE).

## Support
This document and associated tools are made available from CA
Technologies as examples and provided at no charge as a courtesy to
the CA APM Community at large. This resource may require modification
for use in your environment. However, please note that this resource
is not supported by CA Technologies, and inclusion in this site should
not be construed to be an endorsement or recommendation by CA
Technologies. These utilities are not covered by the CA Technologies
software license agreement and there is no explicit or implied
warranty from CA Technologies. They can be used and distributed freely
amongst the CA APM Community, but not sold. As such, they are
unsupported software, provided as is without warranty of any kind,
express or implied, including but not limited to warranties of
merchantability and fitness for a particular purpose. CA Technologies
does not warrant that this resource will meet your requirements or
that the operation of the resource will be uninterrupted or error free
or that any defects will be corrected. The use of this resource
implies that you understand and agree to the terms listed herein.

Although these utilities are unsupported, please let us know if you
have any problems or questions by adding a comment to the CA APM
Community Site area where the resource is located, so that the
Author(s) may attempt to address the issue or question.

Unless explicitly stated otherwise this field pack is only supported
on the same platforms as the regular APM Version. See [APM
Compatibility Guide](http://www.ca.com/us/support/ca-support-online/product-content/status/compatibility-matrix/application-performance-management-compatibility-guide.aspx).


### Support URL
https://github.com/CA-APM/fieldpack.apm-scripts/issues


## Categories
Database Reporting Server Monitoring




# Manual Changelog
```
Tue May 23 11:36:40 CEST 2017
- Added nqtmp directory content size, and # of files

Thu Apr 28 18:41:38 CEST 2016
- Added pcap UI capability

Mon Feb 29 16:26:47 CET 2016
- Added balancer configuration
- Various changes to make the scripts run inside a docker
  container.

Fri Jan 15 16:53:47 CET 2016
- remote the NtplTool call. Runs on one out of 2 MTP's
  only. Reason unknown.

Thu Oct 15 13:11:08 CEST 2015
- Added extraction of apmpacket log, warning/error lines only

Fri Oct  9 15:36:41 CEST 2015
- Added a top directive to show currently running programs
- More fine tuning
- Extracting some information from Filesystem drivers
- Added code to check for out of order segments in pcap/tshark check

Wed Sep 30 16:19:05 <jmertin@antigone> - 1.20-78
- Support for xfs filesystem info gathering
- Added filter for Bidirectional traffic displa in tshark

Thu Sep 10  2015  <jmertin@antigone> - 1.20-77
- Added support for the napatech nt3g drivers
- Changed interface detection function to reflect the new naming
  schemes

Tue Aug 11  2015  <jmertin@antigone> - 1.20-77
- Reduced error messages dumped to console
- fixed minor bugs (user feedback)
- remoted ntpq - it left the console in locked mode and wouldn't
  exit after exection.
- Added ntpstat view to repalce ntpq.

Thu Jul  2  2015 <jmertin@antigone> - 1.20-77
- Adapted apm-syslog to include apm-scripts version
- Added check for applications using SWAP.
- Added check on ntp status and vmotion host migration detection.

Wed Jul  1  2015 <jmertin@antigone> - 1.20-76
- Added hdparm system read speed check

Mon Jun 29 2015 <jmertin@antigone> - 1.20-76
- Added support for non-suid root scripts
- Changed Sizing to performance (performance data collection)

Fri Jun 26 2015 <jmertin@antigone> - 1.20-75
- Released build 75
- Finalized sysinfo collector module, renamed to hwcoll.
- Added apm-scripts version info into all logs.

Wed Jun 24 2015 <jmertin@antigone> - 1.20-74
- Added sysinfo-collector code, to extract data for the HW Compat
  DB. Still experimental. Need ton adapt the sysinfo-code to the
  shared-code base

Tue Jun 23 2015 <jmertin@antigone> - 1.20-74
- Added Data-directory wipe before new timperf data is collected.
- Changed Display of DF output

Thu Apr  2 2015 <jmertin@antigone> - 1.20-73
- Changed the way the Napatech card data is collected
- Added Storage Manager readout code to SYS call for MTP
- Packaging, Changelog updated
- Added workaround for missing pg_env.sh data on old installations

Tue Feb 24 2015 Joerg Mertin  <jmertin@titan> - 1.20-72
- Added workaround for pg_env.sh configuration script not found on
  old installations

Thu Feb 19 2015 by <jmertin@titan> - Version 1.20-71
- Fix for tshark interface loop which was not found when non regular
  network interfaces are in use.

Wed Nov 19 2014 by <jmertin@titan> - Version 1.20-70
- Added certificate export and modulus computation of remote 
  certificate in CIPHER module
- Network interface traffic detection routine changed
-  PSQL data queries added

Fri Dec 19 2014 Joerg Mertin  <jmertin@titan> - 1.20-69
- Initial apmPHP function
- replaced lsb_release gathering using internal apmsysinfo 
  function

Sun Sep 28 2014 Joerg Mertin  <jmertin@titan> - 1.20-69
- Removed some checks to be done on MTP's, as these lock the script
  when 2 Napatech cards are installed in Master/Slave configuration
  (8Ports).
- Some fine tuning on Interface messages

Wed Sep 17 2014 Joerg Mertin  <jmertin@titan> - 1.20-68
- Changed the TIM 9.5/9.6 detection to be based on the timsettings.db
  instead of looking for the license file.

Fri Sep 12 2014 Joerg Mertin  <jmertin@titan> - 1.20-63
- Added complementary check on /tmp size for packet capture.
  If less than 2 GB available, only headers will be captured

Mon Sep  8 2014 Joerg Mertin  <jmertin@titan> - 1.20-63
- Added 2 more DB checks. Cache hit ratio and index usage

* Thu Sep 4 2014 Joerg Mertin  <jmertin@titan> - 1.20-63
- Added additional tshark analysis report
- Added additional extraction of TIM log data

* Wed Jul 30 2014 Joerg Mertin  <jmertin@titan> - 1.20-62
- Packet capture now working for Single TIM, Single TIM with napatech
  Capture card and Multiport collector using buildpcap
- Added MTP automatic Napatech card feed detection for buildcap
- Added expert analysis report creation on packet capture
- Added modinfo extraction for ntki driver (Napatech - not in the
  usual path)
- Made sure the packet capture is not taking into account the payload,
  and increased the limit in capture time. This will increase the time
  to take a packet capture and analysis, however the data will be way
  more accurate.

* Mon Jul 28 2014 Joerg Mertin  <jmertin@titan> - 1.20-46
- Backported changes to run on APM 9.5 and older
- Implemented some error-code redirections
- Fine tuned packet capture analysis. Created on packet capture to be
  analyzed later on.

* Fri Jul 25 2014 Joerg Mertin  <jmertin@titan> - 1.20-39
- Ported apm-scripts to APM 9.6 TIM
- Change apm-scripts to also provide check-ciphers, apm-perf/sizing 
  collection, EM/TESS data collection.
- Provided a simple CLI UI for collection execution

================================================================================
```
