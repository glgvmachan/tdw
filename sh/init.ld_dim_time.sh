#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

TRUNCATE TABLE dim_time
go

UPDATE jobcontrol SET last_run_date = '01/01/1999' WHERE [name] = 'DIM_TIME'
go
EOF

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD < ../sql/init.i_dim_time.sql > /tmp/init.i_dim_time.sql.$ctr

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

UPDATE jobcontrol SET last_run_date = GETDATE() WHERE [name] = 'DIM_TIME'
go
EOF

echo "Completed $0 at - " `date`

