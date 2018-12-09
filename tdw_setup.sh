#!/bin/bash

# Setup the TDW database from scratch
# The TDW database needs to be present and needs full DBO permissions for this setup to succeed.

# Check Microsoft SQL Server tool availability
export SQL_CMD=`which sqlcmd`
if [ $? -eq 1 ]
then
  echo "Microsoft SQL Server command-line tool 'sqlcmd' not found'!!"
  echo "PLEASE INSTALL mssql_tools!!"
  echo 
  exit 1
fi

# Set TDW settings
export TDW_SERVER=172.27.6.75
export TDW_DB=tdw
export TDW_DB_OWNER=sa
export TDW_DB_PASSWORD=GLG1234!

# Set TDW_HOME
export TDW_HOME=/home/vmachan/glg/wars2.0

# CREATE ETL job control table
$SQL_CMD -S $TDW_SERVER -U $TDW_DB_OWNER -P $TDW_DB_PASSWORD -d $TDW_DB -i $TDW_HOME/jobcontrol/ddl/etl_job_control.ddl
# POPULATE ETL job control table
$SQL_CMD -S $TDW_SERVER -U $TDW_DB_OWNER -P $TDW_DB_PASSWORD -d $TDW_DB -i $TDW_HOME/jobcontrol/sql/etl_job_control.sql

# Setup ALL dimension objects
$TDW_HOME/tdw_dim_setup.sh

# Setup ALL fact objects

# Any other cleanup.. 

