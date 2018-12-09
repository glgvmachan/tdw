USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS START_DATE_TIME
go

CREATE TABLE #tmp_dim_council_member
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

SELECT *
  INTO #tmp_vw_data
  FROM POC..vw_council_member_src 
go


DECLARE @vCOUNTER SMALLINT
SET @vCOUNTER = 1

DECLARE @vMAXRANKNO SMALLINT
SET @vMAXRANKNO = 
         (
         SELECT MAX(RANKNO) FROM 
         (
         SELECT VCMS.COUNCIL_MEMBER_ID

               ,ROW_NUMBER() OVER (PARTITION BY VCMS.COUNCIL_MEMBER_ID ORDER BY VCMS.START_DATE ASC) AS RANKNO
               ,VCMS.START_DATE AS START_DATE
               ,VCMS.END_DATE AS END_DATE
           FROM #tmp_vw_data VCMS
          WHERE 1 = 1
         ) A
         )

-- SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS BEFORE_LOOP_START_DATE_TIME
/* LOOP - BEGIN */

WHILE (@vCOUNTER <= @vMAXRANKNO)
BEGIN

    INSERT
      INTO #tmp_dim_council_member
    (
           id

           /* ------- DEMOGRAPHIC attributes - START ------- */
          ,first_name
          ,last_name
          ,title
          ,description
          ,address_line_1
          ,city
          ,state
          ,postalcode
          ,country
          ,region
          ,email
          ,phone
           /* ------- DEMOGRAPHIC attributes - END ------- */

          ,[status]
          ,inflow_method
          ,company
          ,last_bio_update
          ,tc_signed_date
          ,consultation_rate
          ,recruited_by_d_emp_key
          ,council_name
          ,practice_area
          ,dnc
          ,caution_flag
          ,action_required_flag
          ,member_program_flag
          ,premium_flag
          ,retired
          ,language_preferred
          ,language_2
          ,language_3
          ,language_4

          ,active_ind
          ,eff_from_date
          ,eff_to_date
    )
    SELECT
           MERGEOUT.ID

          ,MERGEOUT.first_name
          ,MERGEOUT.last_name
          ,MERGEOUT.TITLE
          ,MERGEOUT.description
          ,MERGEOUT.address_line_1
          ,MERGEOUT.city
          ,MERGEOUT.state
          ,MERGEOUT.postalcode
          ,MERGEOUT.country
          ,MERGEOUT.region
          ,MERGEOUT.email
          ,MERGEOUT.phone

          ,MERGEOUT.[STATUS]
          ,MERGEOUT.INFLOW_METHOD
          ,MERGEOUT.COMPANY
          ,MERGEOUT.LAST_BIO_UPDATE
          ,MERGEOUT.TC_SIGNED_DATE
          ,MERGEOUT.CONSULTATION_RATE
          ,MERGEOUT.RECRUITED_BY_D_EMP_KEY 
          ,MERGEOUT.COUNCIL_NAME
          ,MERGEOUT.PRACTICE_AREA
          ,MERGEOUT.DNC
          ,MERGEOUT.CAUTION_FLAG
          ,MERGEOUT.ACTION_REQUIRED_FLAG
          ,MERGEOUT.MEMBER_PROGRAM_FLAG
          ,MERGEOUT.PREMIUM_FLAG
          ,MERGEOUT.RETIRED
          ,MERGEOUT.LANGUAGE_PREFERRED
          ,MERGEOUT.LANGUAGE_2
          ,MERGEOUT.LANGUAGE_3
          ,MERGEOUT.LANGUAGE_4
          /* ,MERGEOUT.D_DEMO_KEY */
          /* ,MERGEOUT.END_DATE */

          ,'Y'                 /* ACTIVE_IND */
          ,MERGEOUT.START_DATE /* GETDATE()    EFF_FROM_DATE */
          ,'12/31/9999'        /* EFF_TO_DATE   */
      FROM
    (
     MERGE dim_council_member TGT
     USING (
         SELECT *
           FROM
           (
         SELECT VCMS.COUNCIL_MEMBER_ID AS ID

               ,VCMS.FIRST_NAME
               ,VCMS.LAST_NAME
               ,VCMS.TITLE
               ,VCMS.DESCRIPTION
               ,VCMS.ADDRESS_LINE_1
               ,VCMS.CITY
               ,VCMS.STATE
               ,VCMS.POSTALCODE
               ,VCMS.COUNTRY
               ,VCMS.REGION
               ,VCMS.EMAIL
               ,VCMS.PHONE

               ,VCMS.[STATUS]
               ,VCMS.INFLOW_METHOD
               ,VCMS.COMPANY
               ,VCMS.LAST_BIO_UPDATE
               ,VCMS.TC_SIGNED_DATE
               ,VCMS.CONSULTATION_RATE
               ,VCMS.RECRUITED_BY_D_EMP_KEY 
               ,VCMS.COUNCIL_NAME
               ,VCMS.PRACTICE_AREA
               ,VCMS.DNC
               ,VCMS.CAUTION_FLAG
               ,VCMS.ACTION_REQUIRED_FLAG
               ,VCMS.MEMBER_PROGRAM_FLAG
               ,VCMS.PREMIUM_FLAG
               ,VCMS.RETIRED
               ,VCMS.LANGUAGE_PREFERRED
               ,VCMS.LANGUAGE_2
               ,VCMS.LANGUAGE_3
               ,VCMS.LANGUAGE_4

               ,ROW_NUMBER() OVER (PARTITION BY VCMS.COUNCIL_MEMBER_ID ORDER BY VCMS.START_DATE ASC) AS RANKNO
               ,VCMS.START_DATE
               ,VCMS.END_DATE
           FROM #tmp_vw_data VCMS
          WHERE 1 = 1
           ) A
          WHERE RANKNO = @vCOUNTER
           ) SRC
        ON SRC.ID = TGT.ID
       AND TGT.EFF_TO_DATE = '12/31/9999'
      WHEN MATCHED
       AND (
/*
            COALESCE(TGT.FIRST_NAME, 'NONE') <> COALESCE(SRC.FIRST_NAME, 'NONE')
         OR COALESCE(TGT.LAST_NAME, 'NONE') <> COALESCE(SRC.LAST_NAME, 'NONE')
         OR COALESCE(TGT.TITLE, 'NONE') <> COALESCE(SRC.TITLE, 'NONE')
         OR COALESCE(TGT.DESCRIPTION, 'NONE') <> COALESCE(SRC.DESCRIPTION, 'NONE')
         OR COALESCE(TGT.ADDRESS_LINE_1, 'NONE') <> COALESCE(SRC.ADDRESS_LINE_1, 'NONE')
         OR COALESCE(TGT.CITY, 'NONE') <> COALESCE(SRC.CITY, 'NONE')
         OR COALESCE(TGT.STATE, 'NONE') <> COALESCE(SRC.STATE, 'NONE')
         OR COALESCE(TGT.POSTALCODE, 'NONE') <> COALESCE(SRC.POSTALCODE, 'NONE')
         OR COALESCE(TGT.COUNTRY, 'NONE') <> COALESCE(SRC.COUNTRY, 'NONE')
         OR COALESCE(TGT.REGION, 'NONE') <> COALESCE(SRC.REGION, 'NONE')
         OR COALESCE(TGT.EMAIL, 'NONE') <> COALESCE(SRC.EMAIL, 'NONE')
         OR  COALESCE(TGT.PHONE, 'NONE') <> COALESCE(SRC.PHONE, 'NONE')
*/
            COALESCE(TGT.[STATUS], 'NONE') <> COALESCE(SRC.[STATUS], 'NONE')
         OR COALESCE(TGT.INFLOW_METHOD, 'NONE') <> COALESCE(SRC.INFLOW_METHOD, 'NONE')
         OR COALESCE(TGT.COMPANY, 'NONE') <> COALESCE(SRC.COMPANY, 'NONE')
         OR ( 
                  COALESCE(TGT.LAST_BIO_UPDATE, '12-31-9999') <> COALESCE(SRC.LAST_BIO_UPDATE, '12-31-9999')
              AND CONVERT(DATE, TGT.LAST_BIO_UPDATE, 108) <> CONVERT(DATE, SRC.LAST_BIO_UPDATE, 108)
            )
         OR ( 
                  COALESCE(TGT.TC_SIGNED_DATE, '12-31-9999') <> COALESCE(SRC.TC_SIGNED_DATE, '12-31-9999')
              AND CONVERT(DATE, TGT.TC_SIGNED_DATE, 108) <> CONVERT(DATE, SRC.TC_SIGNED_DATE, 108)
            )
         OR COALESCE(TGT.CONSULTATION_RATE, 0.00) <> COALESCE(SRC.CONSULTATION_RATE, 0.00)
         OR COALESCE(TGT.RECRUITED_BY_D_EMP_KEY , -1) <> COALESCE(SRC.RECRUITED_BY_D_EMP_KEY , -1)
         OR COALESCE(TGT.COUNCIL_NAME, 'NONE') <> COALESCE(SRC.COUNCIL_NAME, 'NONE')
         OR COALESCE(TGT.PRACTICE_AREA, 'NONE') <> COALESCE(SRC.PRACTICE_AREA, 'NONE')
         OR COALESCE(TGT.DNC, 'NONE') <> COALESCE(SRC.DNC, 'NONE')
         OR COALESCE(TGT.CAUTION_FLAG, 'NONE') <> COALESCE(SRC.CAUTION_FLAG, 'NONE')
         OR COALESCE(TGT.ACTION_REQUIRED_FLAG, 'NONE') <> COALESCE(SRC.ACTION_REQUIRED_FLAG, 'NONE')
         OR COALESCE(TGT.MEMBER_PROGRAM_FLAG, 'NONE') <> COALESCE(SRC.MEMBER_PROGRAM_FLAG, 'NONE')
         OR COALESCE(TGT.PREMIUM_FLAG, 'NONE') <> COALESCE(SRC.PREMIUM_FLAG, 'NONE')
         -- OR COALESCE(TGT.RETIRED, 0) <> COALESCE(SRC.RETIRED, 0)
         OR COALESCE(TGT.LANGUAGE_PREFERRED, 'NONE') <> COALESCE(SRC.LANGUAGE_PREFERRED, 'NONE')
         OR COALESCE(TGT.LANGUAGE_2, 'NONE') <> COALESCE(SRC.LANGUAGE_2, 'NONE')
         OR COALESCE(TGT.LANGUAGE_3, 'NONE') <> COALESCE(SRC.LANGUAGE_3, 'NONE')
         OR COALESCE(TGT.LANGUAGE_4, 'NONE') <> COALESCE(SRC.LANGUAGE_4, 'NONE')
           )
       AND TGT.ACTIVE_IND = 'Y'
       AND TGT.EFF_TO_DATE = '12/31/9999'
      THEN 
    UPDATE
       SET TGT.EFF_TO_DATE = CASE WHEN DATEADD(dd, -1, SRC.START_DATE) < TGT.EFF_FROM_DATE THEN TGT.EFF_FROM_DATE ELSE DATEADD(dd, -1, SRC.START_DATE) END
          ,TGT.ACTIVE_IND = 'N'
      WHEN NOT MATCHED BY TARGET
      THEN
    INSERT
           (
         ID

        ,FIRST_NAME
        ,LAST_NAME
        ,TITLE
        ,DESCRIPTION
        ,ADDRESS_LINE_1
        ,CITY
        ,STATE
        ,POSTALCODE
        ,COUNTRY
        ,REGION
        ,EMAIL
        ,PHONE

        ,[STATUS]
        ,INFLOW_METHOD
        ,COMPANY
        ,LAST_BIO_UPDATE
        ,TC_SIGNED_DATE
        ,CONSULTATION_RATE
        ,RECRUITED_BY_D_EMP_KEY 
        ,COUNCIL_NAME
        ,PRACTICE_AREA
        ,DNC
        ,CAUTION_FLAG
        ,ACTION_REQUIRED_FLAG
        ,MEMBER_PROGRAM_FLAG
        ,PREMIUM_FLAG
        ,RETIRED
        ,LANGUAGE_PREFERRED
        ,LANGUAGE_2
        ,LANGUAGE_3
        ,LANGUAGE_4

        ,ACTIVE_IND
        ,EFF_FROM_DATE
        ,EFF_TO_DATE
           )
    VALUES
           (
         SRC.ID

        ,SRC.FIRST_NAME
        ,SRC.LAST_NAME
        ,SRC.TITLE
        ,SRC.DESCRIPTION
        ,SRC.ADDRESS_LINE_1
        ,SRC.CITY
        ,SRC.STATE
        ,SRC.POSTALCODE
        ,SRC.COUNTRY
        ,SRC.REGION
        ,SRC.EMAIL
        ,SRC.PHONE

        ,SRC.[STATUS]
        ,SRC.INFLOW_METHOD
        ,SRC.COMPANY
        ,SRC.LAST_BIO_UPDATE
        ,SRC.TC_SIGNED_DATE
        ,SRC.CONSULTATION_RATE
        ,SRC.RECRUITED_BY_D_EMP_KEY 
        ,SRC.COUNCIL_NAME
        ,SRC.PRACTICE_AREA
        ,SRC.DNC
        ,SRC.CAUTION_FLAG
        ,SRC.ACTION_REQUIRED_FLAG
        ,SRC.MEMBER_PROGRAM_FLAG
        ,SRC.PREMIUM_FLAG
        ,SRC.RETIRED
        ,SRC.LANGUAGE_PREFERRED
        ,SRC.LANGUAGE_2
        ,SRC.LANGUAGE_3
        ,SRC.LANGUAGE_4
        ,'Y'                 /* ACTIVE_IND */
        ,SRC.START_DATE      /* EFF_FROM_DATE */
        ,'12/31/9999'        /* EFF_TO_DATE   */
           )
    OUTPUT
           $action AS MERGEACTION
          ,SRC.ID

          ,SRC.FIRST_NAME
          ,SRC.LAST_NAME
          ,SRC.TITLE
          ,SRC.DESCRIPTION
          ,SRC.ADDRESS_LINE_1
          ,SRC.CITY
          ,SRC.STATE
          ,SRC.POSTALCODE
          ,SRC.COUNTRY
          ,SRC.REGION
          ,SRC.EMAIL
          ,SRC.PHONE

          ,SRC.[STATUS]
          ,SRC.INFLOW_METHOD
          ,SRC.COMPANY
          ,SRC.LAST_BIO_UPDATE
          ,SRC.TC_SIGNED_DATE
          ,SRC.CONSULTATION_RATE
          ,SRC.RECRUITED_BY_D_EMP_KEY 
          ,SRC.COUNCIL_NAME
          ,SRC.PRACTICE_AREA
          ,SRC.DNC
          ,SRC.CAUTION_FLAG
          ,SRC.ACTION_REQUIRED_FLAG
          ,SRC.MEMBER_PROGRAM_FLAG
          ,SRC.PREMIUM_FLAG
          ,SRC.RETIRED
          ,SRC.LANGUAGE_PREFERRED
          ,SRC.LANGUAGE_2
          ,SRC.LANGUAGE_3
          ,SRC.LANGUAGE_4
          ,SRC.START_DATE 
          ,SRC.END_DATE
    ) AS MERGEOUT
     WHERE MERGEOUT.MERGEACTION = 'UPDATE'

    INSERT
      INTO dim_council_member
    (
           id

           /* ------- DEMOGRAPHIC attributes - START ------- */
          ,first_name
          ,last_name
          ,title
          ,description
          ,address_line_1
          ,city
          ,state
          ,postalcode
          ,country
          ,region
          ,email
          ,phone
           /* ------- DEMOGRAPHIC attributes - END ------- */

          ,[status]
          ,inflow_method
          ,company
          ,last_bio_update
          ,tc_signed_date
          ,consultation_rate
          ,recruited_by_d_emp_key
          ,council_name
          ,practice_area
          ,dnc
          ,caution_flag
          ,action_required_flag
          ,member_program_flag
          ,premium_flag
          ,retired
          ,language_preferred
          ,language_2
          ,language_3
          ,language_4

          ,active_ind
          ,eff_from_date
          ,eff_to_date
    )
    SELECT
           ID

          ,FIRST_NAME
          ,LAST_NAME
          ,TITLE
          ,DESCRIPTION
          ,ADDRESS_LINE_1
          ,CITY
          ,STATE
          ,POSTALCODE
          ,COUNTRY
          ,REGION
          ,EMAIL
          ,PHONE

          ,[STATUS]
          ,INFLOW_METHOD
          ,COMPANY
          ,LAST_BIO_UPDATE
          ,TC_SIGNED_DATE
          ,CONSULTATION_RATE
          ,RECRUITED_BY_D_EMP_KEY 
          ,COUNCIL_NAME
          ,PRACTICE_AREA
          ,DNC
          ,CAUTION_FLAG
          ,ACTION_REQUIRED_FLAG
          ,MEMBER_PROGRAM_FLAG
          ,PREMIUM_FLAG
          ,RETIRED
          ,LANGUAGE_PREFERRED
          ,LANGUAGE_2
          ,LANGUAGE_3
          ,LANGUAGE_4
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
      FROM #tmp_dim_council_member

    TRUNCATE TABLE #tmp_dim_council_member
    
    -- SELECT 'Processed RANK - ' + CAST(@vCOUNTER AS VARCHAR(8))
    -- SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS STEP_FINISH_DATE_TIME
    SET @vCOUNTER = @vCOUNTER + 1
END

/* LOOP - END */

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

