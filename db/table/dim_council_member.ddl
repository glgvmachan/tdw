USE poc
go

DROP TABLE dim_council_member
go

CREATE TABLE dim_council_member
(
     council_member_key INT IDENTITY(1,1) PRIMARY KEY
    ,id INT NOT NULL

     /* ------- DEMOGRAPHIC attributes - START ------- */
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
     /* ------- DEMOGRAPHIC attributes - END ------- */

    ,[status] NVARCHAR(121) NULL
    ,inflow_method NVARCHAR(42) NULL
    ,company NVARCHAR(255) NULL
    ,last_bio_update DATETIME NULL
    ,tc_signed_date DATETIME NULL
    ,consultation_rate DECIMAL(16, 4) NULL
    ,recruited_by_d_emp_key INT NULL
    ,council_name NVARCHAR(255) NULL
    ,practice_area NVARCHAR(255) NULL
    ,dnc NVARCHAR(42) NULL
    ,caution_flag NVARCHAR(46) NULL
    ,action_required_flag NVARCHAR(50) NULL
    ,member_program_flag NVARCHAR(61) NULL
    ,premium_flag NVARCHAR(42) NULL
    ,retired BIT NULL
    ,language_preferred NVARCHAR(32) NULL
    ,language_2 NVARCHAR(32) NULL
    ,language_3 NVARCHAR(32) NULL
    ,language_4 NVARCHAR(32) NULL

    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_council_member 
    ON dim_council_member (council_member_key)
go

CREATE INDEX ix1_dim_council_member 
    ON dim_council_member (id)
go


