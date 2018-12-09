#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

TRUNCATE TABLE dim_council_member
go

UPDATE jobcontrol SET last_run_date = '01/01/1999' WHERE [name] = 'DIM_COUNCIL_MEMBER'
go
EOF

#
# Set the number of months from 01/01/1998 to now, the loop will run for this many months
#
NUM_MONTHS=$(((`date +%s` - `date -d '01 Jan 1999' +%s`)/(3600*24*30)))

for ((ctr = 1; ctr <= $NUM_MONTHS; ctr++))
do

    echo "Started run for ctr = $ctr at - " `date`

    tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD < ../sql/init.m_dim_council_member.sql > /tmp/init.m_dim_council_member.sql.$ctr

    tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

UPDATE jobcontrol SET last_run_date = DATEADD(MM, 1, last_run_date) WHERE [name] = 'DIM_COUNCIL_MEMBER'
go
EOF

    echo "Completed run for ctr = $ctr at - " `date`

done

echo "Completed $0 at - " `date`

