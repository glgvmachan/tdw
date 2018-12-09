#!/bin/bash

logdate=`date +%Y-%m-%d:%H.%M.%S`
mainexec=`basename $0`
logfile=/tmp/$mainexec.log.$logdate

echo "Starting $0 at - " `date` > $logfile

./init.ld_dim_time.sh >> $logfile
./init.ld_dim_activity_status.sh >> $logfile
./init.ld_dim_product_type.sh >> $logfile
./init.ld_dim_meeting.sh >> $logfile
./init.ld_dim_emp.sh >> $logfile
./init.ld_dim_project.sh >> $logfile
./init.ld_dim_user.sh >> $logfile
./init.ld_dim_council_member.sh >> $logfile

echo "Completed $0 at - " `date` >> $logfile

