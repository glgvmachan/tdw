USE tdw
go

DROP TABLE etl_job_control
go

CREATE TABLE etl_job_control
(
     job_id INT IDENTITY(1,1) PRIMARY KEY
    ,job_name VARCHAR(256) NOT NULL
    ,job_description VARCHAR(1024) NOT NULL
    ,depends_on INT NULL
    ,runnable_ind INT NOT NULL
    ,active_ind INT NOT NULL
    ,last_run_status VARCHAR(32) NOT NULL
    ,last_run_date DATETIME NOT NULL
    ,created_date DATETIME NOT NULL
    ,last_updated_date DATETIME NOT NULL
)
go

