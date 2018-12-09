USE tdw
go

TRUNCATE TABLE etl_job_control
go

/* DIM_PRODUCT - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_PRODUCT'
    ,'Populates the products dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_PRODUCT - ABOVE */

/* DIM_PROJECT - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_PROJECT'
    ,'Populates the projects dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_PROJECT - ABOVE */

/* DIM_USER - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_USER'
    ,'Populates the user dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_USER - ABOVE */

/* DIM_EMP - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_EMP'
    ,'Populates the employee dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_EMP - ABOVE */

/* DIM_COUNCIL_MEMBER - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_COUNCIL_MEMBER'
    ,'Populates the council member dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_COUNCIL_MEMBER - ABOVE */

/* DIM_ACTIVITY_STATUS - BELOW */
INSERT 
  INTO etl_job_control 
(
     job_name
    ,job_description
    ,depends_on
    ,runnable_ind
    ,active_ind
    ,last_run_status
    ,last_run_date
    ,created_date
    ,last_updated_date
)
VALUES
(
     'DIM_ACTIVITY_STATUS'
    ,'Populates the activity status dimension'
    ,NULL
    ,1
    ,1
    ,'SUCCESS'
    ,'12/31/1900'
    ,GETDATE()
    ,GETDATE()
)
go
/* DIM_COUNCIL_MEMBER - ABOVE */

