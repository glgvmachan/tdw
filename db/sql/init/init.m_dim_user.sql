USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS START_DATE_TIME
go

-- THIS STEP ONLY DONE WHEN THE INITIAL LOAD SCRIPT
TRUNCATE TABLE dim_user
go

CREATE TABLE #tmp_dim_user
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
    ,at_firm INT NULL
    ,active_ind CHAR(1) NOT NULL
    ,eff_from_date DATETIME NOT NULL
    ,eff_to_date DATETIME NOT NULL
)
go

SELECT *
  INTO #tmp_vw_data
  FROM POC..vw_user_src
go


DECLARE @vCOUNTER SMALLINT
SET @vCOUNTER = 1

DECLARE @vMAXRANKNO SMALLINT
SET @vMAXRANKNO =
         (
         SELECT MAX(RANKNO) FROM
         (
         SELECT TVD.ID

               ,ROW_NUMBER() OVER (PARTITION BY TVD.ID ORDER BY TVD.START_DATE ASC) AS RANKNO
               ,TVD.START_DATE AS START_DATE
               ,TVD.END_DATE AS END_DATE
           FROM #tmp_vw_data TVD
          WHERE 1 = 1
         ) A
         )

/* LOOP - BEGIN */

WHILE (@vCOUNTER <= @vMAXRANKNO)
BEGIN

    INSERT
      INTO #tmp_dim_user
    (
           id
          ,name
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
          ,accountid
          ,donotcall
          ,hasoptedoutofemail
          ,hasoptedoutoffax
          ,user_sales_owner_person_id
          ,user_research_owner_person_id
          ,at_firm
          ,active_ind
          ,eff_from_date
          ,eff_to_date
    )
    SELECT
           MERGEOUT.id
          ,MERGEOUT.name
          ,MERGEOUT.first_name
          ,MERGEOUT.last_name
          ,MERGEOUT.title
          ,MERGEOUT.description
          ,MERGEOUT.address_line_1
          ,MERGEOUT.city
          ,MERGEOUT.state
          ,MERGEOUT.postalcode
          ,MERGEOUT.country
          ,MERGEOUT.region
          ,MERGEOUT.email
          ,MERGEOUT.phone
          ,MERGEOUT.accountid
          ,MERGEOUT.donotcall
          ,MERGEOUT.hasoptedoutofemail
          ,MERGEOUT.hasoptedoutoffax
          ,MERGEOUT.user_sales_owner_person_id
          ,MERGEOUT.user_research_owner_person_id
          ,MERGEOUT.at_firm
          ,'Y'                  /* ACTIVE_IND    */
          ,MERGEOUT.START_DATE  /* EFF_FROM_DATE */
          ,'12/31/9999'         /* EFF_TO_DATE   */
      FROM 
    (
     MERGE dim_user TGT
     USING (
         SELECT *
           FROM
           (
         SELECT TVD.ID
               ,TVD.FIRST_NAME
               ,TVD.LAST_NAME
               ,TVD.NAME
               ,TVD.TITLE
               ,TVD.DESCRIPTION
               ,TVD.ADDRESS_LINE_1
               ,TVD.CITY
               ,TVD.STATE
               ,TVD.POSTALCODE
               ,TVD.COUNTRY
               ,TVD.REGION
               ,TVD.EMAIL
               ,TVD.PHONE
               ,TVD.ACCOUNTID
               ,TVD.DONOTCALL
               ,TVD.HASOPTEDOUTOFEMAIL
               ,TVD.HASOPTEDOUTOFFAX
               ,TVD.USER_SALES_OWNER_PERSON_ID
               ,TVD.USER_RESEARCH_OWNER_PERSON_ID
               ,TVD.AT_FIRM
               ,ROW_NUMBER() OVER (PARTITION BY TVD.ID ORDER BY TVD.START_DATE ASC) AS RANKNO
               ,TVD.START_DATE AS START_DATE
               ,TVD.END_DATE AS END_DATE
           FROM #tmp_vw_data TVD
          WHERE 1 = 1
           ) A
          WHERE RANKNO = @vCOUNTER
           ) SRC
        ON SRC.ID = TGT.ID
       AND TGT.EFF_TO_DATE = '12/31/9999'
      WHEN MATCHED
       AND (
                COALESCE(TGT.USER_SALES_OWNER_PERSON_ID, 9999) <> COALESCE(SRC.USER_SALES_OWNER_PERSON_ID, 9999)
             OR COALESCE(TGT.USER_RESEARCH_OWNER_PERSON_ID, 9999) <> COALESCE(SRC.USER_RESEARCH_OWNER_PERSON_ID, 9999)
             OR COALESCE(TGT.AT_FIRM, 9999) <> COALESCE(SRC.AT_FIRM, 9999)
             OR COALESCE(TGT.FIRST_NAME, 'NONE') <> COALESCE(SRC.FIRST_NAME, 'NONE')
             OR COALESCE(TGT.LAST_NAME, 'NONE') <> COALESCE(SRC.LAST_NAME, 'NONE')
             OR COALESCE(TGT.NAME, 'NONE') <> COALESCE(SRC.NAME, 'NONE')
             OR COALESCE(TGT.TITLE, 'NONE') <> COALESCE(SRC.TITLE, 'NONE')
             OR COALESCE(TGT.DESCRIPTION, 'NONE') <> COALESCE(SRC.DESCRIPTION, 'NONE')
             OR COALESCE(TGT.ADDRESS_LINE_1, 'NONE') <> COALESCE(SRC.ADDRESS_LINE_1, 'NONE')
             OR COALESCE(TGT.CITY, 'NONE') <> COALESCE(SRC.CITY, 'NONE')
             OR COALESCE(TGT.STATE, 'NONE') <> COALESCE(SRC.STATE, 'NONE')
             OR COALESCE(TGT.POSTALCODE, 'NONE') <> COALESCE(SRC.POSTALCODE, 'NONE')
             OR COALESCE(TGT.COUNTRY, 'NONE') <> COALESCE(SRC.COUNTRY, 'NONE')
             OR COALESCE(TGT.REGION, 'NONE') <> COALESCE(SRC.REGION, 'NONE')
             OR COALESCE(TGT.EMAIL, 'NONE') <> COALESCE(SRC.EMAIL, 'NONE')
             OR COALESCE(TGT.PHONE, 'NONE') <> COALESCE(SRC.PHONE, 'NONE')
             OR COALESCE(TGT.DONOTCALL, 'NONE') <> COALESCE(SRC.DONOTCALL, 'NONE')
             OR COALESCE(TGT.HASOPTEDOUTOFEMAIL, 'NONE') <> COALESCE(SRC.HASOPTEDOUTOFEMAIL, 'NONE')
             OR COALESCE(TGT.HASOPTEDOUTOFFAX, 'NONE') <> COALESCE(SRC.HASOPTEDOUTOFFAX, 'NONE')
           )
      THEN 
    UPDATE
       SET TGT.EFF_TO_DATE = GETDATE()
          ,TGT.ACTIVE_IND = 'N'
      WHEN NOT MATCHED
      THEN
    INSERT
           (
             ID
            ,NAME
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
            ,ACCOUNTID
            ,DONOTCALL
            ,HASOPTEDOUTOFEMAIL
            ,HASOPTEDOUTOFFAX
            ,USER_SALES_OWNER_PERSON_ID
            ,USER_RESEARCH_OWNER_PERSON_ID
            ,AT_FIRM
            ,ACTIVE_IND
            ,EFF_FROM_DATE
            ,EFF_TO_DATE
           )
    VALUES
           (
             SRC.ID
            ,SRC.NAME
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
            ,SRC.ACCOUNTID
            ,SRC.DONOTCALL
            ,SRC.HASOPTEDOUTOFEMAIL
            ,SRC.HASOPTEDOUTOFFAX
            ,SRC.USER_SALES_OWNER_PERSON_ID
            ,SRC.USER_RESEARCH_OWNER_PERSON_ID
            ,SRC.AT_FIRM
            ,'Y'
            ,SRC.START_DATE
            ,'12/31/9999'
           )
    OUTPUT
           $action AS MERGEACTION
          ,SRC.ID
          ,SRC.NAME
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
          ,SRC.ACCOUNTID
          ,SRC.DONOTCALL
          ,SRC.HASOPTEDOUTOFEMAIL
          ,SRC.HASOPTEDOUTOFFAX
          ,SRC.USER_SALES_OWNER_PERSON_ID
          ,SRC.USER_RESEARCH_OWNER_PERSON_ID
          ,SRC.AT_FIRM
          ,SRC.START_DATE
          ,SRC.END_DATE
    ) AS MERGEOUT
     WHERE MERGEOUT.MERGEACTION = 'UPDATE'

    INSERT
      INTO dim_user
    (
           id
          ,name
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
          ,accountid
          ,donotcall
          ,hasoptedoutofemail
          ,hasoptedoutoffax
          ,user_sales_owner_person_id
          ,user_research_owner_person_id
          ,at_firm
          ,active_ind
          ,eff_from_date
          ,eff_to_date
    )
    SELECT
           ID
          ,NAME
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
          ,ACCOUNTID
          ,DONOTCALL
          ,HASOPTEDOUTOFEMAIL
          ,HASOPTEDOUTOFFAX
          ,USER_SALES_OWNER_PERSON_ID
          ,USER_RESEARCH_OWNER_PERSON_ID
          ,AT_FIRM
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
      FROM #tmp_dim_user

    TRUNCATE TABLE #tmp_dim_user

    SET @vCOUNTER = @vCOUNTER + 1
END

/* LOOP - END */
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

