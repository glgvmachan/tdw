#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

TRUNCATE TABLE dim_user
go

UPDATE jobcontrol SET last_run_date = '01/01/1999' WHERE [name] = 'DIM_USER'
go
EOF

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD < ../sql/init.m_dim_user.sql > /tmp/init.m_dim_user.sql.$ctr

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

UPDATE jobcontrol SET last_run_date = GETDATE() WHERE [name] = 'DIM_USER'
go
EOF

echo "Completed $0 at - " `date`

