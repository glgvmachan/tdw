#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

sqlcmd -S $DEVDB_IP -U $DBUSER -P $DBPSWD -i ../sql/m_dim_emp.sql -o /tmp/m_dim_emp.sql.log

sqlcmd -S $DEVDB_IP -U $DBUSER -P $DBPSWD -d $DBNAME -Q " UPDATE jobcontrol SET last_run_date = GETDATE() WHERE [name] = 'DIM_EMP'"

echo "Completed $0 at - " `date`

