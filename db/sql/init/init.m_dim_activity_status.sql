USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

TRUNCATE TABLE dim_activity_status
go

DECLARE @lvDATE AS DATETIME = GETDATE();

INSERT
  INTO dim_activity_status
(
       ACTIVITY_STATUS
      ,ACTIVE_IND
      ,EFF_FROM_DATE
      ,EFF_TO_DATE
)
SELECT
       MERGEOUT.ACTIVITY_STATUS
      ,'Y'          /* ACTIVE_IND */
      ,@lvDATE      /* EFF_FROM_DATE */
      ,'12/31/9999' /* EFF_TO_DATE   */
  FROM
(
 MERGE dim_activity_status TGT
 USING (
         SELECT MEETING_PARTICIPANT_STATUS AS ACTIVITY_STATUS
           FROM GLGLIVE.DBO.MEETING_PARTICIPANT_STATUS
          WHERE ACTIVE_IND = 1
          UNION
         SELECT Name AS ACTIVITY_STATUS
           FROM GLGLIVE.qualtrics.SurveyStatus
          UNION
         SELECT Name AS ACTIVITY_STATUS
           FROM GLGLIVE.Survey.Survey_Status
       ) SRC
    ON SRC.ACTIVITY_STATUS = TGT.ACTIVITY_STATUS
   AND TGT.EFF_TO_DATE = '12/31/9999'
  WHEN NOT MATCHED
  THEN
INSERT
       (
         ACTIVITY_STATUS
        ,ACTIVE_IND
        ,EFF_FROM_DATE
        ,EFF_TO_DATE
       )
VALUES
       (
         SRC.ACTIVITY_STATUS
        ,'Y'
        ,@lvDATE  
        ,'12/31/9999'
       )
/*
  -- DO NOTHING WHEN MATCHED, SINCE THERE ARE NO OTHER ATTRIBUTES TO UPDATE FOR A STATUS
  -- WE EITHER ADD NEW ONES OR DON'T
  WHEN MATCHED
  THEN 
*/
OUTPUT
       $action AS MERGEACTION
      ,SRC.ACTIVITY_STATUS
) AS MERGEOUT
 WHERE MERGEOUT.MERGEACTION = 'UPDATE'

SELECT COUNT(1) AS ROWS_INSERTED
  FROM dim_activity_status TGT
 WHERE TGT.eff_from_date = @lvDATE

SELECT COUNT(1) AS ROWS_UPDATED
  FROM dim_activity_status TGT
 WHERE TGT.eff_to_date = @lvDATE
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

