# apm-scripts rel1.20-89

**Purpose**: Provides scripts to collect data for troubleshooting an APM 9.x or later installation  
  _by J. Mertin -- joerg.mertin(-AT-)ca.com_

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




