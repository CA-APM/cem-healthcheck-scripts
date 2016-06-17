===============================================================================
== What data is collected =====================================================
===============================================================================

*.protocolstats: These are status and performance information on the
 TIM currently running. The TIM itself will write down these info on a
 regular base.

Sysinfo.csv: Extracts data as manufacturer details (Dell, Supermicro,
VMWare) to identify the machine type. This will also have some data as
Memory amount, CPU type with number of available cores. All data that
can lead to one specific machine will be anonymized. By example, to
have a unique identifier for each machine, the Hardware Mac Address of
the eth0 interface will be used to compute a MD5 Checksum. This
checksum creation is a one-way process. It can not be done the other
way around and helps just to identify the same machine over time.

This is what the content of the different files will look like:
> eth0_traffic.csv - 3 lines - to compute the bytes per second
  "1";"eth0";"111528";"2399392"
  "2";"eth0";"19672";"7056"
  "3";"eth0";"1136";"0"

> Sysinfo.csv  - 1 Line
  2012-01-17 13:50:56";"3083cb638e50429d273c505842db9687";" X7DWU";" Supermicro";"RedHatEnterpriseES 4 NahantUpdate4";"TIM 4.5.6.1 build 256139";"165";"2764";"8309796";"216160";"2.6.9-42.ELsmp i686 i386 GNU/Linux";"0.00 0.00 0.00 1/398 20046";" Intel(R) Xeon(R) CPU           X5460  @ 3.16GHz";" 3166.856";"4";

> protocolstats - many lines - depending on 5min data or 5sec data
  stored by the TIM, depending on the TIM Version (TIM 5.0/APM9.0.x) and
  APM9.1 differ. APM9.1 has CSV type data already.

  Jan 13 2012 23:55 Packets: 11441 captured, 0 dropped, 11441 analyzed.   Bytes: 9052850 analyzed, 241 Kbps  tim-cpu: 0.1% cpu0: 1.3% cpu1: 5.9% cpu2: 14.0% cpu3: 0.5% mem: 159.73 conns: 161 transets: 4 tranunits: 4 trancomps: 7 ssl-sessions: 0 login-sessions: 10 stats: 163


===============================================================================
== How long does the Fieldpack need to run ?===================================
===============================================================================

The fieldpack only collects data that is already available. The only
time it requires are the "wait" pause of 1Second between 3 polls of
network interface data. This means, if you have 2 network interfaces
(eth0 and eth1) it will require 6seconds + the collecting of the
Sysinfo.csv line data (approx 1sec) then the copying of the
protocolstats files into a target directory and its archiving. Add
another 2secs to it.  So – in total around 10Seconds.


===============================================================================
== What additional load will the Fieldpack induce to the TIM ?=================
===============================================================================

Because this fieldpack will only collect data, and archive it, the
load is very low (expect 1% added CPU load while archiving).Because
the TIM is running as a single-thread and the TIM Hardware usually has
quad-core Cpu's, the TIM process itself will not even notice its
execution, so you can run this fieldpack on a heavily loaded TIM
without interfering with the TIM process.


===============================================================================
== What is the purpose of this fieldpack ? ====================================
===============================================================================

The purpose of this fieldpack is to collect data to be able to compute
a performance curve for the different TIM implementations depending on
the number of configured transactions, expected traffic volume and
transactions to be analyzed.This data will then be used to decently
size a APM (CEM Part) installation in future projects.


===============================================================================
== On which machines should this fieldpack be installed/run ?==================
===============================================================================

Please run this fieldpack on every available TIM that runs in
production and has valid data pssing through.  The more data we
collect, the better the estimation for future sizing.


===============================================================================
== When should the fieldpack be ran ? =========================================
===============================================================================

This fieldpack collects performance data generated/provided by the
TIM. As the TIM keeps the data for 5 days, best is to run it after 5
days of normal operation of the TIM. For the best data to be
collected, make it the end of the last work-day of the week.


===============================================================================
== Why do I get the same data on the download link ? ==========================
===============================================================================

The fieldpack only collects the performance data upon installation. If
you want to collect a new set of data, uninstall the fieldpack through
the provided link, and install it again for it to gather a new set of
data.
An alternative is to go into the fieldpack directory, and execute the
data-collection script "collect-data.sh" as user with root privileges.
