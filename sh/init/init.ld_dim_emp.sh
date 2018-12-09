#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

sqlcmd -S $DEVDB_IP -U $DBUSER -P $DBPSWD -d $DBNAME << EOF
-- USE poc
-- go

TRUNCATE TABLE dim_emp
go

UPDATE etl_job_control SET last_run_date = '01/01/1999' WHERE job_name = 'DIM_EMP'
go
EOF

sqlcmd -S $DEVDB_IP -U $DBUSER -P $DBPSWD -d $DBNAME -i ../sql/init.m_dim_emp.sql -o /tmp/init.m_dim_emp.sql.$ctr

sqlcmd -S $DEVDB_IP -U $DBUSER -P $DBPSWD -d $DBNAME << EOF
-- USE poc
-- go

UPDATE etl_job_control SET last_run_date = GETDATE() WHERE job_name = 'DIM_EMP'
go
EOF

echo "Completed $0 at - " `date`

