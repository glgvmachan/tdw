USE poc
go

CREATE OR ALTER VIEW vw_project_src
AS
SELECT
       CNSLT.CONSULTATION_ID AS ID
      ,CNSLT.TITLE AS TITLE
      ,CNSLT.APP_NAME AS APP_NAME
      ,CNSLT.CONFERENCE_CALL_IND AS CONFERENCE_CALL_IND
      ,CNSLT.CONSULTATION_DESCRIPTION_TEXT AS DESCRIPTION
      ,CNSLT.CONSULTATION_OVERALL_STATUS_ID AS STATUS_ID
      ,CNSLT.ENGAGEMENT_STAGE AS ENGAGEMENT_STAGE
      ,CNSLT.ENGAGEMENT_TYPE AS ENGAGEMENT_TYPE
      ,CNSLT.GLG_DELEGATE_PERSON_ID AS GLG_DELEGATE_PERSON_ID
      ,CNSLT.PRIMARY_RM_PERSON_ID AS PRIMARY_RM_PERSON_ID
      ,CNSLT.ON_DEMAND_IND AS ON_DEMAND_IND
      ,CNSLT.SKIP_OQ AS SKIP_OQ
      ,CAST(
             (CASE WHEN CNSLT.CREATED_DATE > COALESCE(CNSLT.LAST_UPDATED_DATE, '01/01/1900')
                  THEN CNSLT.CREATED_DATE
                  ELSE CNSLT.LAST_UPDATED_DATE
             END)
           AS DATETIME2
           ) AS START_DATE
      ,CAST(GETDATE() AS DATETIME2) AS END_DATE
  FROM GLGLIVE.consult.CONSULTATION CNSLT
 WHERE 1 = 1
   -- AND CAST(CNSLT.CREATED_DATE as date) >= '2013-01-01'
   AND CAST(CNSLT.CREATED_DATE as date)      >= (
                                                      SELECT last_run_date
                                                        FROM jobcontrol
                                                       WHERE name = 'DIM_PROJECT'
                                                         AND active_ind = 1
                                                         AND runnable_ind = 1
                                                )
    OR CAST(CNSLT.LAST_UPDATED_DATE as date) >= (
                                                      SELECT last_run_date
                                                        FROM jobcontrol
                                                       WHERE name = 'DIM_PROJECT'
                                                         AND active_ind = 1
                                                         AND runnable_ind = 1
                                                )
go

