USE poc
go

DROP TABLE dim_time
go

CREATE TABLE dim_time
(
    /*
        Central TIME Dimension for use in all reporting and analytics
    */
    date_key int NOT NULL 
   ,[date] DATE NOT NULL
   ,week_day_name NVARCHAR(30) NOT NULL
   ,week_day_number INT NOT NULL
   ,week_day_name_short NVARCHAR(3) NOT NULL
   ,is_work_day BIT NOT NULL
   ,work_days_in_month INT NOT NULL
   ,remaining_work_days_in_month INT NOT NULL
   ,day_number INT NOT NULL
   ,month_number INT NOT NULL
   ,quarter_number INT NOT NULL
   ,year_number INT NOT NULL
   ,month_name NVARCHAR(30) NOT NULL
   ,first_day_month INT NOT NULL
   ,last_day_month INT NOT NULL
   ,days_in_month INT NOT NULL
   ,first_day_quarter INT NOT NULL
   ,last_day_quarter INT NOT NULL
   ,days_in_quarter INT NOT NULL
   ,date_key_ly_op INT NOT NULL
   ,date_key_ly_fin INT NOT NULL
   ,active_ind CHAR(1) NOT NULL
   ,eff_from_date DATETIME NOT NULL
   ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_time 
    ON dim_time (date_key)
go

CREATE INDEX ix1_dim_time 
    ON dim_time (date)
go
