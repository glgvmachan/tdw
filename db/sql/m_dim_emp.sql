USE tdw
go

SELECT GETDATE() AS START_DATE_TIME
go

CREATE TABLE #tmp_dim_emp
(
     EMP_KEY INT IDENTITY(1,1) PRIMARY KEY
    ,ID NVARCHAR(18) NOT NULL
    ,FIRST_NAME NVARCHAR(40) NULL
    ,LAST_NAME NVARCHAR(80) NULL
    ,TITLE NVARCHAR(128) NULL
    ,LOCATION NVARCHAR(255) NULL
    ,EMAIL NVARCHAR(255) NULL
    ,PHONE NVARCHAR(255) NULL
    ,MOBILE NVARCHAR(255) NULL
    ,NOTIFY_RESEARCH BIT NULL
    ,DEPARTMENT NVARCHAR(255) NULL
    ,BU NVARCHAR(255) NULL
    ,SEGMENT NVARCHAR(255) NULL
    ,POD NVARCHAR(255) NULL
    ,TEAM NVARCHAR(255) NULL
    ,MANAGER_ID INT NULL
    ,FUSION_ROLE NVARCHAR(255) NULL
    ,ACTIVE_IND CHAR(1) NOT NULL
    ,EFF_FROM_DATE DATETIME NOT NULL
    ,EFF_TO_DATE DATETIME NOT NULL
)
go

SELECT *
  INTO #tmp_vw_data
  FROM POC..vw_emp_src
go

DECLARE @vCOUNTER SMALLINT
SET @vCOUNTER = 1

DECLARE @vMAXRANKNO SMALLINT
SET @vMAXRANKNO = 
    (
         SELECT MAX(RANKNO)
           FROM 
                (
                SELECT VES.ID
                      ,ROW_NUMBER() OVER (PARTITION BY VES.ID ORDER BY VES.FEA_STARTDATE ASC) AS RANKNO
                      ,VES.FEA_STARTDATE AS START_DATE
                      ,VES.FEA_ENDDATE AS END_DATE
                  FROM #tmp_vw_data VES
                 WHERE 1 = 1
                ) A
    )

/* LOOP - BEGIN */

WHILE (@vCOUNTER <= @vMAXRANKNO)
BEGIN

    INSERT
      INTO #tmp_dim_emp
    (
           ID
          ,FIRST_NAME
          ,LAST_NAME
          ,TITLE
          ,LOCATION
          ,EMAIL
          ,PHONE
          ,MOBILE
          ,NOTIFY_RESEARCH
          ,DEPARTMENT
          ,BU
          ,SEGMENT
          ,POD
          ,TEAM
          ,MANAGER_ID
          ,FUSION_ROLE
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
    )
    SELECT
           MERGEOUT.ID
          ,MERGEOUT.FIRST_NAME
          ,MERGEOUT.LAST_NAME
          ,MERGEOUT.TITLE
          ,MERGEOUT.LOCATION
          ,MERGEOUT.EMAIL
          ,MERGEOUT.PHONE
          ,MERGEOUT.MOBILE
          ,MERGEOUT.NOTIFY_RESEARCH
          ,MERGEOUT.DEPARTMENT
          ,MERGEOUT.BU
          ,MERGEOUT.SEGMENT
          ,MERGEOUT.POD
          ,MERGEOUT.TEAM
          ,MERGEOUT.MANAGER_ID
          ,MERGEOUT.FUSION_ROLE
          ,'Y'                 /* ACTIVE_IND */
          ,MERGEOUT.START_DATE /* GETDATE()    EFF_FROM_DATE */
          ,'12/31/9999'        /* EFF_TO_DATE   */
      FROM
    (
     MERGE dim_emp TGT
     USING (
         SELECT *
           FROM
           (
         SELECT VES.ID
               ,VES.FIRST_NAME
               ,VES.LAST_NAME
               ,VES.TITLE
               ,VES.LOCATION
               ,VES.EMAIL
               ,VES.PHONE
               ,VES.MOBILE
               ,VES.NOTIFY_RESEARCH
               ,VES.DEPARTMENT
               ,VES.BU
               ,VES.SEGMENT
               ,VES.POD
               ,VES.TEAM
               ,VES.ManagerId AS MANAGER_ID
               ,VES.FUSION_ROLE
               ,ROW_NUMBER() OVER (PARTITION BY VES.ID ORDER BY VES.FEA_STARTDATE ASC) AS RANKNO
               ,VES.FEA_STARTDATE AS START_DATE
               ,VES.FEA_ENDDATE AS END_DATE
           FROM #tmp_vw_data VES
          WHERE 1 = 1
           ) A
          WHERE RANKNO = @vCOUNTER
           ) SRC
        ON SRC.ID = TGT.ID
       AND TGT.EFF_TO_DATE = '12/31/9999'
      WHEN MATCHED
       AND (
            COALESCE(TGT.FIRST_NAME, 'NONE') <> COALESCE(SRC.FIRST_NAME, 'NONE')
         OR COALESCE(TGT.LAST_NAME, 'NONE') <> COALESCE(SRC.LAST_NAME, 'NONE')
         OR COALESCE(TGT.TITLE, 'NONE') <> COALESCE(SRC.TITLE, 'NONE')
         OR COALESCE(TGT.LOCATION, 'NONE') <> COALESCE(SRC.LOCATION, 'NONE')
         OR COALESCE(TGT.EMAIL, 'NONE') <> COALESCE(SRC.EMAIL, 'NONE')
         OR COALESCE(TGT.PHONE, 'NONE') <> COALESCE(SRC.PHONE, 'NONE')
         OR COALESCE(TGT.MOBILE, 'NONE') <> COALESCE(SRC.MOBILE, 'NONE')
         OR COALESCE(TGT.NOTIFY_RESEARCH, 'NONE') <> COALESCE(SRC.NOTIFY_RESEARCH, 'NONE')
         OR COALESCE(TGT.DEPARTMENT, 'NONE') <> COALESCE(SRC.DEPARTMENT, 'NONE')
         OR COALESCE(TGT.BU, 'NONE') <> COALESCE(SRC.BU, 'NONE')
         OR COALESCE(TGT.SEGMENT, 'NONE') <> COALESCE(SRC.SEGMENT, 'NONE')
         OR COALESCE(TGT.POD, 'NONE') <> COALESCE(SRC.POD, 'NONE')
         OR COALESCE(TGT.TEAM, 'NONE') <> COALESCE(SRC.TEAM, 'NONE')
         OR COALESCE(TGT.MANAGER_ID, 0) <> COALESCE(SRC.MANAGER_ID, 0)
         OR COALESCE(TGT.FUSION_ROLE, 'NONE') <> COALESCE(SRC.FUSION_ROLE, 'NONE')
           )
       AND TGT.ACTIVE_IND = 'Y'
       AND TGT.EFF_TO_DATE = '12/31/9999'
      THEN 
    UPDATE
       SET TGT.EFF_TO_DATE = CASE WHEN DATEADD(dd, -1, SRC.START_DATE) < TGT.EFF_FROM_DATE
                                       THEN TGT.EFF_FROM_DATE
                                  ELSE
                                       DATEADD(dd, -1, SRC.START_DATE)
                             END
          ,TGT.ACTIVE_IND = 'N'
      WHEN NOT MATCHED BY TARGET
      THEN
    INSERT
           (
         ID
        ,FIRST_NAME
        ,LAST_NAME
        ,TITLE
        ,LOCATION
        ,EMAIL
        ,PHONE
        ,MOBILE
        ,NOTIFY_RESEARCH
        ,DEPARTMENT
        ,BU
        ,SEGMENT
        ,POD
        ,TEAM
        ,MANAGER_ID
        ,FUSION_ROLE
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
        ,SRC.LOCATION
        ,SRC.EMAIL
        ,SRC.PHONE
        ,SRC.MOBILE
        ,SRC.NOTIFY_RESEARCH
        ,SRC.DEPARTMENT
        ,SRC.BU
        ,SRC.SEGMENT
        ,SRC.POD
        ,SRC.TEAM
        ,SRC.MANAGER_ID
        ,SRC.FUSION_ROLE
        ,'Y'
        ,SRC.START_DATE /* GETDATE() */
        ,'12/31/9999'
           )
    OUTPUT
           $action AS MERGEACTION
          ,SRC.ID
          ,SRC.FIRST_NAME
          ,SRC.LAST_NAME
          ,SRC.TITLE
          ,SRC.LOCATION
          ,SRC.EMAIL
          ,SRC.PHONE
          ,SRC.MOBILE
          ,SRC.NOTIFY_RESEARCH
          ,SRC.DEPARTMENT
          ,SRC.BU
          ,SRC.SEGMENT
          ,SRC.POD
          ,SRC.TEAM
          ,SRC.MANAGER_ID
          ,SRC.FUSION_ROLE
          ,SRC.START_DATE
          ,SRC.END_DATE
    ) AS MERGEOUT
     WHERE MERGEOUT.MERGEACTION = 'UPDATE'

    INSERT
      INTO dim_emp
    (
           ID
          ,FIRST_NAME
          ,LAST_NAME
          ,TITLE
          ,LOCATION
          ,EMAIL
          ,PHONE
          ,MOBILE
          ,NOTIFY_RESEARCH
          ,DEPARTMENT
          ,BU
          ,SEGMENT
          ,POD
          ,TEAM
          ,MANAGER_ID
          ,FUSION_ROLE
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
    )
    SELECT
           ID
          ,FIRST_NAME
          ,LAST_NAME
          ,TITLE
          ,LOCATION
          ,EMAIL
          ,PHONE
          ,MOBILE
          ,NOTIFY_RESEARCH
          ,DEPARTMENT
          ,BU
          ,SEGMENT
          ,POD
          ,TEAM
          ,MANAGER_ID
          ,FUSION_ROLE
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
      FROM #tmp_dim_emp

    TRUNCATE TABLE #tmp_dim_emp

    SELECT 'Processed RANK - ' + CAST(@vCOUNTER AS VARCHAR(8))
    SET @vCOUNTER = @vCOUNTER + 1
END

/* LOOP - END */

SELECT GETDATE() AS FINISH_DATE_TIME
go

