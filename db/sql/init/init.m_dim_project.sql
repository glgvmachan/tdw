USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS START_DATE_TIME
go

-- THIS STEP ONLY DONE WHEN THE INITIAL LOAD SCRIPT
TRUNCATE TABLE dim_project
go

CREATE TABLE #tmp_dim_project
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

SELECT *
  INTO #tmp_vw_data
  FROM POC..vw_project_src
go

DECLARE @vCOUNTER SMALLINT
SET @vCOUNTER = 1

DECLARE @lvDATE DATETIME
SET @lvDATE = GETDATE()

DECLARE @vMAXRANKNO SMALLINT
SET @vMAXRANKNO = 
         (
         SELECT MAX(RANKNO) FROM
         (
         SELECT TVD.ID
               ,ROW_NUMBER() OVER (PARTITION BY TVD.ID ORDER BY TVD.START_DATE ASC) AS RANKNO
               ,TVD.START_DATE
               ,TVD.END_DATE
           FROM #tmp_vw_data TVD
          WHERE 1 = 1
         ) A
         )

WHILE (@vCOUNTER <= @vMAXRANKNO)
BEGIN

    INSERT
      INTO #tmp_dim_project
    (
           ID
          ,TITLE
          ,APP_NAME
          ,CONFERENCE_CALL_IND
          ,DESCRIPTION
          ,STATUS_ID
          ,ENGAGEMENT_STAGE
          ,ENGAGEMENT_TYPE
          ,GLG_DELEGATE_PERSON_ID
          ,PRIMARY_RM_PERSON_ID
          ,ON_DEMAND_IND
          ,SKIP_OQ
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
    )
    SELECT
           MERGEOUT.ID
          ,MERGEOUT.TITLE
          ,MERGEOUT.APP_NAME
          ,MERGEOUT.CONFERENCE_CALL_IND
          ,MERGEOUT.DESCRIPTION
          ,MERGEOUT.STATUS_ID
          ,MERGEOUT.ENGAGEMENT_STAGE
          ,MERGEOUT.ENGAGEMENT_TYPE
          ,MERGEOUT.GLG_DELEGATE_PERSON_ID
          ,MERGEOUT.PRIMARY_RM_PERSON_ID
          ,MERGEOUT.ON_DEMAND_IND
          ,MERGEOUT.SKIP_OQ
          ,'Y'            /* ACTIVE_IND */
          ,@lvDATE        /* EFF_FROM_DATE */
          ,'12/31/9999'   /* EFF_TO_DATE   */
      FROM
    (
     MERGE dim_project TGT
     USING (
             SELECT *
               FROM 
             (
             SELECT TVD.ID
                   ,TVD.TITLE
                   ,TVD.APP_NAME
                   ,TVD.CONFERENCE_CALL_IND
                   ,TVD.DESCRIPTION
                   ,TVD.STATUS_ID
                   ,TVD.ENGAGEMENT_STAGE
                   ,TVD.ENGAGEMENT_TYPE
                   ,TVD.GLG_DELEGATE_PERSON_ID
                   ,TVD.PRIMARY_RM_PERSON_ID
                   ,TVD.ON_DEMAND_IND
                   ,TVD.SKIP_OQ

                   ,ROW_NUMBER() OVER (PARTITION BY TVD.ID ORDER BY TVD.START_DATE ASC) AS RANKNO
                   ,TVD.START_DATE
                   ,TVD.END_DATE
               FROM #tmp_vw_data TVD
              WHERE 1 = 1
             ) A
             WHERE RANKNO = @vCOUNTER
           ) SRC
        ON SRC.ID = TGT.ID
       AND COALESCE(SRC.TITLE, 'NONE') = COALESCE(TGT.TITLE, 'NONE')
       AND COALESCE(SRC.DESCRIPTION, 'NONE') = COALESCE(TGT.DESCRIPTION, 'NONE')
       AND TGT.EFF_TO_DATE = '12/31/9999'
      WHEN MATCHED
       AND (
                TGT.PRIMARY_RM_PERSON_ID <> SRC.PRIMARY_RM_PERSON_ID
             OR COALESCE(TGT.GLG_DELEGATE_PERSON_ID, 9999) <> COALESCE(SRC.GLG_DELEGATE_PERSON_ID, 9999)
             OR COALESCE(TGT.STATUS_ID, 9999) <> COALESCE(SRC.STATUS_ID, 9999)
             OR COALESCE(TGT.APP_NAME, 'NONE') <> COALESCE(SRC.APP_NAME, 'NONE')
             OR COALESCE(TGT.TITLE, 'NONE') <> COALESCE(SRC.TITLE, 'NONE')
             OR COALESCE(TGT.DESCRIPTION, 'NONE') <> COALESCE(SRC.DESCRIPTION, 'NONE')
             OR COALESCE(TGT.CONFERENCE_CALL_IND, 'NONE') <> COALESCE(SRC.CONFERENCE_CALL_IND, 'NONE')
             OR COALESCE(TGT.ENGAGEMENT_STAGE, 'NONE') <> COALESCE(SRC.ENGAGEMENT_STAGE, 'NONE')
             OR COALESCE(TGT.ENGAGEMENT_TYPE, 'NONE') <> COALESCE(SRC.ENGAGEMENT_TYPE, 'NONE')
             OR COALESCE(TGT.GLG_DELEGATE_PERSON_ID, 'NONE') <> COALESCE(SRC.GLG_DELEGATE_PERSON_ID, 'NONE')
             OR COALESCE(TGT.PRIMARY_RM_PERSON_ID, 'NONE') <> COALESCE(SRC.PRIMARY_RM_PERSON_ID, 'NONE')
             OR COALESCE(TGT.SKIP_OQ, 'NONE') <> COALESCE(SRC.SKIP_OQ, 'NONE')
           )
      THEN 
    UPDATE
       SET TGT.EFF_TO_DATE = CASE WHEN DATEADD(dd, -1, SRC.START_DATE) < TGT.EFF_FROM_DATE THEN TGT.EFF_FROM_DATE ELSE DATEADD(dd, -1, SRC.START_DATE) END
          ,TGT.ACTIVE_IND = 'N'
      WHEN NOT MATCHED
      THEN
    INSERT
           (
             ID
            ,TITLE
            ,APP_NAME
            ,CONFERENCE_CALL_IND
            ,DESCRIPTION
            ,STATUS_ID
            ,ENGAGEMENT_STAGE
            ,ENGAGEMENT_TYPE
            ,GLG_DELEGATE_PERSON_ID
            ,PRIMARY_RM_PERSON_ID
            ,ON_DEMAND_IND
            ,SKIP_OQ
            ,ACTIVE_IND
            ,EFF_FROM_DATE
            ,EFF_TO_DATE
           )
    VALUES
           (
             SRC.ID
            ,SRC.TITLE
            ,SRC.APP_NAME
            ,SRC.CONFERENCE_CALL_IND
            ,SRC.DESCRIPTION
            ,SRC.STATUS_ID
            ,SRC.ENGAGEMENT_STAGE
            ,SRC.ENGAGEMENT_TYPE
            ,SRC.GLG_DELEGATE_PERSON_ID
            ,SRC.PRIMARY_RM_PERSON_ID
            ,SRC.ON_DEMAND_IND
            ,SRC.SKIP_OQ
            ,'Y'              /* ACTIVE_IND    */
            ,SRC.START_DATE   /* EFF_FROM_DATE */
            ,'12/31/9999'     /* EFF_TO_DATE   */
           )
    OUTPUT
           $action AS MERGEACTION
          ,SRC.ID
          ,SRC.TITLE
          ,SRC.APP_NAME
          ,SRC.CONFERENCE_CALL_IND
          ,SRC.DESCRIPTION
          ,SRC.STATUS_ID
          ,SRC.ENGAGEMENT_STAGE
          ,SRC.ENGAGEMENT_TYPE
          ,SRC.GLG_DELEGATE_PERSON_ID
          ,SRC.PRIMARY_RM_PERSON_ID
          ,SRC.ON_DEMAND_IND
          ,SRC.SKIP_OQ
          ,SRC.START_DATE
          ,SRC.END_DATE
    ) AS MERGEOUT
     WHERE MERGEOUT.MERGEACTION = 'UPDATE'
    
    INSERT
      INTO dim_project
    (
           ID
          ,TITLE
          ,APP_NAME
          ,CONFERENCE_CALL_IND
          ,DESCRIPTION
          ,STATUS_ID
          ,ENGAGEMENT_STAGE
          ,ENGAGEMENT_TYPE
          ,GLG_DELEGATE_PERSON_ID
          ,PRIMARY_RM_PERSON_ID
          ,ON_DEMAND_IND
          ,SKIP_OQ
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
    )
    SELECT 
           ID
          ,TITLE
          ,APP_NAME
          ,CONFERENCE_CALL_IND
          ,DESCRIPTION
          ,STATUS_ID
          ,ENGAGEMENT_STAGE
          ,ENGAGEMENT_TYPE
          ,GLG_DELEGATE_PERSON_ID
          ,PRIMARY_RM_PERSON_ID
          ,ON_DEMAND_IND
          ,SKIP_OQ
          ,ACTIVE_IND
          ,EFF_FROM_DATE
          ,EFF_TO_DATE
      FROM #tmp_dim_project

    TRUNCATE TABLE #tmp_dim_project

    SET @vCOUNTER = @vCOUNTER + 1
END

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

