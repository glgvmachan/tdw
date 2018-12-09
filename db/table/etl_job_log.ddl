USE poc
go

DROP TABLE etl_job_log
go

CREATE TABLE etl_job_log
(
     job_id INT INT NOT NULL
    ,run_start_datetime DATETIME NOT NULL
    ,run_end_datetime DATETIME NOT NULL
    ,success_ind INT NOT NULL
    ,tuples_added INT NOT NULL
    ,tuples_updated INT NOT NULL
    ,tuples_deleted INT NOT NULL
    ,tuples_exceptions INT NOT NULL
    ,created_date DATETIME NOT NULL
    ,last_updated_date DATETIME NOT NULL
)
go

