USE poc
go

DROP TABLE dim_product_type
go

CREATE TABLE dim_product_type
(
     product_type_key INT IDENTITY(1,1) PRIMARY KEY
    ,product_type_id INT NOT NULL
    ,product_type_desc VARCHAR(256) NOT NULL
    ,category_name VARCHAR(256) NOT NULL
    ,product_type_category_id INT NOT NULL
    ,customizable_ind INT NULL
    ,pct_ind INT NULL
    ,transaction_ind INT NULL
    ,allows_multiple_payments_ind INT NULL
    ,duration_based_payments_ind INT NULL
    ,eligible_for_payments_ind INT NULL
    ,standard_markup INT NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

CREATE UNIQUE INDEX ux_dim_product 
    ON dim_product_type (product_type_id, product_type_category_id, eff_from_date)
go

CREATE INDEX ix1_dim_product 
    ON dim_product_type (product_type_id)
go

CREATE INDEX ix2_dim_product 
    ON dim_product_type (product_type_desc)
go

exit

