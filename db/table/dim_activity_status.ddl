USE poc
go

DROP TABLE dim_activity_status
go

CREATE TABLE dim_activity_status
(
     activity_status_key INT IDENTITY(1,1) PRIMARY KEY
    ,activity_status VARCHAR(64) NOT NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_user 
    ON dim_activity_status (activity_status_key)
go

CREATE INDEX ix1_dim_user 
    ON dim_activity_status (activity_status)
go


