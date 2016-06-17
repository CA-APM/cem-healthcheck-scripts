#!/bin/bash
#
# Author: $Author: jmertin $
# Locked by: $Locker:  $
#
# This script will check the remote supported ciphers of
# a remote webserver

# Programm Version
VER="$Revision: 1.17 $"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get Program-Name, shortened Version.
PROGNAME="`basename $0 .sh`"

# Directory we work in.
BASEDIR=`pwd`

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

# Build Date in reverse - Prefix to builds
DATE=`date +"%Y%m%d"`

# Define the Hostname
HOSTName=`hostname -s`

# IP
IPAdd=`ifconfig | grep -v lo | grep "inet addr:" | head -1 | awk '{ print $2}' | sed -e 's/addr\://g'`

# Configuration file
CONFIG="${BASEDIR}/apm_stats.cfg"
DBCONFIG="${BASEDIR}/apm_psqldb.cfg"

# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}_${HOSTName}_${IPAdd}.log"

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
    echo "*** ERROR: Unable to load build details. Abort."
    exit
fi

##############################################################################

# Lock program
Lock $LockFile 1

# OpenSSL requires the port number.
if [ -f $DBCONFIG ]
then
    . $DBCONFIG
else
    PSQLPATH="/apps/CA/apmdatabase"
    DBNAME="cemdb"
    DBUSER="admin"
fi

DBPWD="quality"

MSG="Creating logfile $LogFile"
echo -n > $LogFile
errlvl=$?
errors

echo
title "`date` by `whoami`@`hostname` - ${PROGNAME}.sh v${VER} (apm-scripts ${RELEASE}-b${BUILD})"
# Log program version.
entry "This script will extract data from the APM DB for later analysis"
log "It has to be executed on the system hosting the PostgreSQL DB"

# DB Path
echo -n " >> PostgreSQL DB installation path [$PSQLPATH]: "
read newPSQLPATH
if [ -n "$newPSQLPATH" -a  "$PSQLPATH" != "$newPSQLPATH"  ]
then
    PSQLPATH="$newPSQLPATH"
fi

if [ -d $PSQLPATH ]
then
    if [ -f ${PSQLPATH}/pg_env.sh ]
    then
	. ${PSQLPATH}/pg_env.sh
    else
	echo " !! pg_env.sh not found in provided PSQLPATH. Fallback activated"
	export PATH=${PSQLPATH}/bin:$PATH
	export PGDATA=${PSQLPATH}/data
	export PGDATABASE=postgres
	export PGUSER=postgres
	export PGPORT=5432
	export PGLOCALEDIR=${PSQLPATH}/share/locale
	export MANPATH=$MANPATH:${PSQLPATH}/share/man
    fi
fi
echo "PSQLPATH=$PSQLPATH" > $DBCONFIG

echo -n " >> Database name used by APM [$DBNAME]: "
read newDBNAME
if [ -z "$DBNAME" -a  "$DBNAME" != "$newDBNAME"  ]
then
    DBNAME="$newDBNAME"
fi
echo "DBNAME=$DBNAME" >> $DBCONFIG

echo -n " >> Database user [$DBUSER]: "
read newDBUSER
if [ -z "$DBUSER" -a  "$DBUSER" != "$newDBUSER"  ]
then
    DBUSER="$newDBUSER"
fi
echo "DBUSER=$DBUSER" >> $DBCONFIG

echo " ** The DB User password is not stored anywhere. The example PWD below is just the default"
echo -n " >> Database user password [$DBPWD]: "
read -s newDBPWD
if [ "$DBPWD" != "$newDBPWD"  ]
then
    DBPWD="$newDBPWD"
fi

echo

# Check if we already ran this script - if not - ask some stuff to include ito the report.
if [ -f $CONFIG ]
then

    log "Loading $CONFIG"

    . $CONFIG
    
    title "Details"
    # Add these to the Log file
    echo "Customer Name: $CsrName" >> $LogFile
    echo "Customer Name + Mail: $UsrMail" >> $LogFile
    echo "Ticket: $SupportTicket" >> $LogFile
    echo "Database path: $PSQLPATH" >> $LogFile
    echo "Database name: $DBNAME" >> $LogFile
    echo "Database user: $DBUSER" >> $LogFile
    entry " >> One line description of issue"
    echo "$Comment" >> $LogFile

fi

# Date + Time
LDATE=`date +"%F @ %T"`

# Check for psql
if [ ! `which psql` ]
then
    MSG="No psql binary detected. Aborting"
    errlvl=1
    errors
fi

title "Database information Entries/Size"
if [ `which psql` ]
then
    entry "running Postgres instances"
    ps auxww | grep ^postgres >> $LogFile
    
    entry "Postgres and DB versions" 
    psql --version | head -1 >> $LogFile
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_db_versions from ts_domains;' >> $LogFile
    
    entry "Active Queries" 
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'SELECT pg_stat_get_backend_pid(s.backendid) AS procpid, pg_stat_get_backend_activity(s.backendid) AS current_query FROM (SELECT pg_stat_get_backend_idset() AS backendid) AS s;' >> $LogFile
    
    entry "Active DB Locks"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select * from pg_locks;' >> $LogFile
    
    entry "Collector status"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_entity.ts_hostname, ts_entity.ts_em_type, ts_entity.ts_port, ts_services_def.ts_display_name from ts_entity, ts_services_def, ts_entity_service where ts_entity_service.ts_entity_id=ts_entity.ts_id and ts_entity_service.ts_service_id=ts_services_def.ts_id;'  >> $LogFile

    entry "Existing entities"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select * from ts_entity;'  >> $LogFile

    entry "DB Activity" 
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select * from pg_stat_activity;' >> $LogFile
    
    entry "User Status"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_active as "Active Users",ts_soft_delete as "Soft Deleted User",count(*) from ts_users GROUP BY ts_active,ts_soft_delete;'  >> $LogFile

    entry "User Group Status"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_soft_delete as "Soft Deleted Group",count(*) from ts_user_groups GROUP BY ts_soft_delete;'  >> $LogFile

    entry "Recorded Sessions / Advanced Recorder"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_soft_delete as Deleted,count(*) AS "Recorded Transactions" from ts_recording_sessions group by ts_soft_delete;' >> $LogFile
    
    entry "Defined Business Processes"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_soft_delete as Deleted,count(*) as "Business Processes" from ts_transet_groups group by ts_soft_delete;' >> $LogFile
    
    entry "Defined Transactions"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_soft_delete as Deleted,count(*) AS "Transactions" from ts_transets group by ts_soft_delete;' >> $LogFile
    
    entry "Defined Components"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select ts_soft_delete as Deleted,count(*) AS "Components" from ts_trancomps group by ts_soft_delete;' >> $LogFile
    
    entry "${DBNAME} size" 
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'SELECT SUM(relpages * 8 / 1024) AS "MB" FROM pg_class;' >> $LogFile

    entry "${DBNAME} Cache hit ratio" 
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit)  as heap_hit, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;' >> $LogFile
    
    entry "PostgreSQL Data file size"
    du -sh $PGDATA >> $LogFile
    
    entry "Last aggregated row"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'select max(ts_last_aggregated_row) from ts_st_ts_us_dly;' >> $LogFile

    entry "Vacuum information"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c 'SELECT relname, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze FROM pg_stat_user_tables;' >> $LogFile

    entry "${DBNAME} number of data entries" 
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c "SELECT to_char(SUM(reltuples),'999G999G999G999') AS \"Count\" FROM pg_class;" >> $LogFile
    
    entry "PostgreSQL table stats"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c "SELECT relname, to_char(reltuples,'999G999G999G999') AS \"Count\", relpages * 8 / 1024 AS \"MB\" FROM pg_class ORDER BY relpages DESC;" >> $LogFile

    entry "PostgreSQL index usage"
    PGUSER=${DBUSER} PGPASSWORD="${DBPWD}" psql -q -d ${DBNAME} -c "SELECT relname, 100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used, n_live_tup rows_in_table FROM pg_stat_user_tables WHERE seq_scan + idx_scan > 0 ORDER BY n_live_tup DESC;" >> $LogFile

else
    echo "No usable psql binary found. Abort"
fi

log "Logfile written to $LogFile"
echo

# Lock program
Unlock $LockFile
