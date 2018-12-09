USE poc
go

DROP TABLE dim_user
go

CREATE TABLE dim_user
(
     user_key INT IDENTITY(1,1) PRIMARY KEY
    ,id NVARCHAR(18) NOT NULL
    ,name NVARCHAR(121) NULL
    ,first_name NVARCHAR(40) NULL
    ,last_name NVARCHAR(80) NULL
    ,title NVARCHAR(128) NULL
    ,description NVARCHAR(MAX) NULL
    ,address_line_1 NVARCHAR(MAX) NULL
    ,city VARCHAR(40) NULL
    ,state VARCHAR(80) NULL
    ,postalcode VARCHAR(20) NULL
    ,country VARCHAR(80) NULL
    ,region VARCHAR(256) NULL
    ,email NVARCHAR(255) NULL
    ,phone NVARCHAR(255) NULL
    ,accountid NVARCHAR(18) NULL
    ,donotcall BIT NULL
    ,hasoptedoutofemail BIT NULL
    ,hasoptedoutoffax BIT NULL
    ,user_sales_owner_person_id INT NULL
    ,user_research_owner_person_id INT NULL
    ,at_firm INT NOT NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_user 
    ON dim_user (user_key)
go

CREATE INDEX ix1_dim_user 
    ON dim_user (id)
go


