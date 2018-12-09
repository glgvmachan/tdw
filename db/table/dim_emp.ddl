-- USE poc
USE tdw
go

DROP TABLE dim_emp
go

CREATE TABLE dim_emp
(
     emp_key INT IDENTITY(1,1) PRIMARY KEY
    ,id NVARCHAR(18) NOT NULL
    ,first_name NVARCHAR(40) NULL
    ,last_name NVARCHAR(80) NULL
    ,title NVARCHAR(128) NULL
    ,location NVARCHAR(255) NULL
    ,email NVARCHAR(255) NULL
    ,phone NVARCHAR(255) NULL
    ,mobile NVARCHAR(255) NULL
    ,notify_research BIT NULL
    ,department NVARCHAR(255) NULL
    ,bu NVARCHAR(255) NULL
    ,segment NVARCHAR(255) NULL
    ,pod NVARCHAR(255) NULL
    ,team NVARCHAR(255) NULL
    ,manager_id INT NULL
    ,fusion_role NVARCHAR(255) NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_emp 
    ON dim_emp (emp_key)
go

CREATE INDEX ix1_dim_emp 
    ON dim_emp (id)
go


