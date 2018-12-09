USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS START_DATE_TIME
go

DECLARE @lvDATE AS DATETIME = GETDATE();

WITH CAL_GENERATOR(DD) AS
(
  SELECT CAST('20000101' AS DATE) AS [DATE]
  UNION ALL
  SELECT DATEADD(d, 1, DD)
    FROM CAL_GENERATOR
   WHERE DD < CAST('20251231' AS DATE)
)
,CALENDAR AS
(
  SELECT CAST(CAL_GENERATOR.DD AS DATE) AS [DATE]
    FROM CAL_GENERATOR
)

--Place holder to be FK value for NULL in date columns, represents 'unknown'
INSERT
  INTO dim_time
(
    [DATE_KEY]
   ,[DATE]
   ,[WEEK_DAY_NAME]
   ,[WEEK_DAY_NUMBER]
   ,[WEEK_DAY_NAME_SHORT]
   ,[IS_WORK_DAY]
   ,[WORK_DAYS_IN_MONTH]
   ,[REMAINING_WORK_DAYS_IN_MONTH]
   ,[DAY_NUMBER]
   ,[MONTH_NUMBER]
   ,[QUARTER_NUMBER]
   ,[YEAR_NUMBER]
   ,[MONTH_NAME]
   ,[FIRST_DAY_MONTH]
   ,[LAST_DAY_MONTH]
   ,[DAYS_IN_MONTH]
   ,[FIRST_DAY_QUARTER]
   ,[LAST_DAY_QUARTER]
   ,[DAYS_IN_QUARTER]
   ,[DATE_KEY_LY_OP]
   ,[DATE_KEY_LY_FIN]
   ,ACTIVE_IND
   ,EFF_FROM_DATE
   ,EFF_TO_DATE
)
SELECT
       -1             AS DATE_KEY
      ,CAST('1/1/2099' AS DATE) AS [DATE]
      ,'na'           AS WEEK_DAY_NAME
      ,-1             AS WEEK_DAY_NUMBER
      ,'na'           AS WEEK_DAY_NAME_SHORT
      ,CAST(0 AS bit) AS IS_WORK_DAY
      ,-1             AS WORK_DAYS_IN_MONTH
      ,-1             AS REMAINING_WORK_DAYS_IN_MONTH
      ,-1             AS DAY_NUMBER
      ,-1             AS MONTH_NUMBER
      ,-1             AS QUARTER_NUMBER
      ,-1             AS YEAR_NUMBER
      ,'na'           AS MONTH_NAME
      ,-1             AS FIRST_DAY_MONTH
      ,-1             AS LAST_DAY_MONTH
      ,-1             AS DAYS_IN_MONTH
      ,-1             AS FIRST_DAY_QUARTER
      ,-1             AS LAST_DAY_QUARTER
      ,-1             AS DAYS_IN_QUARTER
      ,-1             AS DATE_KEY_LY_OP
      ,-1             AS DATE_KEY_LY_FIN
      ,'Y'            AS ACTIVE_IND
      ,@lvDATE        AS EFF_FROM_DATE 
      ,'12/31/9999'   AS EFF_TO_DATE 
 UNION
   ALL
SELECT
       CONVERT(INT, CONVERT(VARCHAR(8), [DATE], 112)) AS DATE_KEY
      ,[DATE]
      ,DATENAME(dw, [Date]) AS WEEK_DAY_NAME
      ,DATEPART(dw, [Date]) AS WEEK_DAY_NUMBER
      ,LEFT(DATENAME(dw, [Date]), 3) AS WEEK_DAY_NAME_SHORT
      ,CASE WHEN DATEPART(dw, [Date]) BETWEEN 2 AND 6
              THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
       END AS IS_WORK_DAY

      ,  (DATEDIFF(dd, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), EOMONTH([DATE])) + 1)
       - (DATEDIFF(wk, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), EOMONTH([DATE])) * 2)
       - (
           CASE WHEN DATENAME(dw, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0)) = 'Sunday'
                  THEN 1
                ELSE 0
           END
         )
       - (
           CASE WHEN DATENAME(dw, EOMONTH([DATE])) = 'Saturday'
                  THEN 1
                ELSE 0
           END
         ) AS WORK_DAYS_IN_MONTH

      ,(
         (DATEDIFF(dd, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), EOMONTH([DATE])) + 1)
       - (DATEDIFF(wk, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), EOMONTH([DATE])) * 2)
       - (
           CASE WHEN DATENAME(dw, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0)) = 'Sunday'
                  THEN 1
                ELSE 0
           END
         )
       - (
           CASE WHEN DATENAME(dw, EOMONTH([DATE])) = 'Saturday'
                  THEN 1
                ELSE 0
           END
         )
       )
       -
       (
         (DATEDIFF(dd, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), [Date]) + 1)
       - (DATEDIFF(wk, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), [Date]) * 2)
       - (
           CASE WHEN DATENAME(dw, DATEADD(month, DATEDIFF(month, 0, [DATE]), 0)) = 'Sunday'
                  THEN 1
                ELSE 0
           END
         )
       - (
           CASE WHEN DATENAME(dw, [Date]) = 'Saturday'
                  THEN 1
                ELSE 0
           END
         )
       ) AS REMAINING_WORK_DAYS_IN_MONTH

      ,DATEPART(day, [DATE]) AS DAY_NUMBER
      ,DATEPART(month, [DATE]) AS MONTH_NUMBER
      ,DATEPART(QUARTER, [DATE]) AS QUARTER_NUMBER
      ,DATEPART(YEAR, [DATE]) AS YEAR_NUMBER
      ,DATENAME(mm, [Date]) AS MONTH_NAME
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), 112)
              ) AS FIRST_DAY_MONTH
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), EOMONTH([DATE]), 112)
              ) AS LAST_DAY_MONTH
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), EOMONTH([DATE]), 112)
              )
       -
       CONVERT(
                INT
               ,CONVERT(VARCHAR(8), DATEADD(month, DATEDIFF(month, 0, [DATE]), 0), 112)
              ) + 1 AS DAYS_IN_MONTH
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), DATEADD(quarter, DATEDIFF(quarter, 0, [DATE]), 0), 112)
              ) AS FIRST_DAY_QUARTER
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), DATEADD(dd, -1, DATEADD(qq, DATEDIFF(qq, 0, [DATE]) + 1, 0)), 112)
              ) AS LAST_DAY_QUARTER
      ,DATEDIFF(
                 dd
                ,DATEADD(quarter, DATEDIFF(quarter, 0, [DATE]), 0)
                ,DATEADD(dd, -1, DATEADD(qq, DATEDIFF(qq, 0, [DATE]) + 1, 0))
               ) AS DAYS_IN_QUARTER
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), dateadd(week, -52, [DATE]), 112)
              ) AS DATE_KEY_LY_OP
      ,CONVERT(
                INT
               ,CONVERT(VARCHAR(8), dateadd(year, -1, [DATE]), 112)
              ) AS DATE_KEY_LY_FIN
      ,'Y' AS ACTIVE_IND
      ,@lvDATE AS EFF_FROM_DATE
      ,'12/31/9999'AS EFF_TO_DATE
  FROM CALENDAR
OPTION (MAXRECURSION 0)

SELECT COUNT(1) AS ROWS_INSERTED
  FROM dim_time TGT
 WHERE TGT.eff_from_date = @lvDATE

SELECT COUNT(1) AS ROWS_UPDATED
  FROM dim_time TGT
 WHERE TGT.eff_to_date = @lvDATE
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

