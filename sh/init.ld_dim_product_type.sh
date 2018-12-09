#!/bin/bash

echo "Starting $0 at - " `date`

. ./.pocdb.cfg

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

TRUNCATE TABLE dim_product_type
go

UPDATE jobcontrol SET last_run_date = '01/01/1999' WHERE [name] = 'DIM_PRODUCT_TYPE'
go
EOF

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD < ../sql/init.m_dim_product_type.sql > /tmp/init.m_dim_product_type.sql.$ctr

tsql -S $DEVDB_IP -U $DBUSER -P $DBPSWD << EOF
USE poc
go

UPDATE jobcontrol SET last_run_date = GETDATE() WHERE [name] = 'DIM_PRODUCT_TYPE'
go
EOF

echo "Completed $0 at - " `date`

