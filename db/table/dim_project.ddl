USE poc
go

DROP TABLE dim_project
go

CREATE TABLE dim_project
(
     project_key INT IDENTITY(1,1) PRIMARY KEY
    ,id INT NOT NULL
    ,title NVARCHAR(250) NULL
    ,app_name VARCHAR(MAX) NULL
    ,conference_call_ind BIT NULL
    ,description NVARCHAR(MAX) NULL
    ,status_id INT NULL
    ,engagement_stage VARCHAR(30) NULL
    ,engagement_type VARCHAR(30) NULL
    ,glg_delegate_person_id INT NULL
    ,primary_rm_person_id INT NULL
    ,on_demand_ind BIT NULL
    ,skip_oq BIT NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_project 
    ON dim_project (id, eff_from_date, eff_to_date)
go

CREATE INDEX ix1_dim_project 
    ON dim_project (id)
go

CREATE INDEX ix2_dim_project 
    ON dim_project (title)
go

