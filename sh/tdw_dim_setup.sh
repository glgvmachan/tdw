#!/bin/bash

# Start message
echo "This script will setup dimensions for TDW using the following settings"

# Setup ALL dimension objects
echo
echo "Setting TDW dimensions in "
echo "    TDW_SERVER=" $TDW_SERVER
echo "    TDW_DB=" $TDW_DB
echo "    TDW_DB_OWNER=" $TDW_DB_OWNER
echo "    TDW_DB_PASSWORD=" $TDW_DB_PASSWORD
echo "    TDW_HOME=" $TDW_HOME
echo
echo
echo "Press <ENTER> to continue OR <CTRL-C> to abort"
read

# CREATE dimension tables

for DIM_FILE in `ls -1 $TDW_HOME/dim/ddl/table`
do
    # Create the dimension table
    DIM_ETL_TABLE=`basename $DIM_FILE .ddl`
    echo "Using $DIM_ETL_FILE'.ddl' to create $DIM_ETL_FILE table.."
    read
    $SQL_CMD -S $TDW_SERVER -U $TDW_DB_OWNER -P $TDW_DB_PASSWORD -d $TDW_DB \
             -i $DIM_FILE
    # Get corresponding etl load script
    echo "Using $DIM_ETL_TABLE'.sql' to load $DIM_ETL_TABLE table.."
    read
    $SQL_CMD -S $TDW_SERVER -U $TDW_DB_OWNER -P $TDW_DB_PASSWORD -d $TDW_DB \
             -i $TDW_HOME/dim/sql/$DIM_ETL_TABLE.sql
done





