USE poc
go

CREATE OR ALTER VIEW vw_council_member_src
AS
WITH COUNCIL_MEMBER_BASE AS
(
    -- this holds all of the council member IDs and creates a starting point for all records
    -- (will always be the original START_DATE).
    -- This also holds a few attributes that are not currently tracked over time (practive area, retired, etc.)
    SELECT cm.COUNCIL_MEMBER_ID
          ,cm.RETIRED_IND AS RETIRED
          ,pa.PRACTICE_AREA
          ,c.COUNCIL_NAME
          ,cm.RECRUITED_BY
          ,p.IS_DNC AS DNC
          ,CASE --INFLOW_METHOD: all 4 options mentioned to be MECE
                WHEN     cm.referred_by_person_id IS NOT NULL
                     AND cm.recruited_by IS NOT NULL
                     THEN 'Referred & Recruited'
                WHEN cm.recruited_by IS NOT NULL
                     THEN 'Recruited'
                WHEN cm.referred_by_person_id IS NOT NULL
                     THEN 'Referred'
                ELSE
                     'Not Referred or Recruited'
           END AS INFLOW_METHOD
          ,CAST(cm.CREATE_DATE AS DATETIME2) AS STARTDATE
          ,CAST(GETDATE() AS DATETIME2) AS ENDDATE
      FROM GLGLIVE..COUNCIL_MEMBER cm
      LEFT
      JOIN GLGLIVE..PRACTICE_AREA pa
        ON pa.PRACTICE_AREA_ID = cm.PRACTICE_AREA_ID
      LEFT
      JOIN GLGLIVE..COUNCIL c
        ON c.COUNCIL_ID = cm.COUNCIL_ID
     INNER
      JOIN GLGLIVE..PERSON p
        ON p.PERSON_ID = cm.PERSON_ID
     WHERE (
                CONVERT(DATE, cm.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
             OR CONVERT(DATE, cm.LAST_UPDATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
           )
)

, TERMS_CONDITIONS_RAW AS
(
    -- take the terms and conditions history and create a "end date hierarchy" so that we can
    -- take most conservative expiration date in TERMS_CONDITIONS
    SELECT tcs.COUNCIL_MEMBER_ID
          ,CAST(tcs.CREATE_DATE AS DATETIME2) AS STARTDATE
          ,CAST(tcs.EXPIRATION_DATE AS DATETIME2) AS NOTED_EXPIRATION_DATE
          ,CAST(DATEADD(yy, 1, tcs.CREATE_DATE) AS DATETIME2) AS CALCULATED_EXPIRATION_DATE -- assume "standard" 1 yr TC period
          ,CAST(LEAD(tcs.CREATE_DATE) OVER(PARTITION BY tcs.COUNCIL_MEMBER_ID ORDER BY tcs.CREATE_DATE) AS DATETIME2) AS ROLLING_EXPIRATION_DATE -- since people can resign before the're TC's are up
      FROM GLGLIVE..TERMS_CONDITIONS_SIGNED tcs
     WHERE (
                CONVERT(DATE, tcs.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
          )
)

, TERMS_CONDITIONS_ACTIVE AS
(
    -- resolve any overlaps (since people can resign before the're TC's are up) that exist
    -- in TERMS_CONDITIONS_RAW and move to the most "conservative" version of when T&Cs expired
    SELECT DISTINCT
           COUNCIL_MEMBER_ID
          ,STARTDATE AS TERMS_CONDITIONS_SIGNED_DATE
          ,STARTDATE
          ,DATEADD(
                     ns
                   ,-100
                   ,CASE
                         WHEN ROLLING_EXPIRATION_DATE IS NULL
                              THEN GETDATE()
                         WHEN ROLLING_EXPIRATION_DATE <
                              COALESCE(NOTED_EXPIRATION_DATE, CALCULATED_EXPIRATION_DATE)
                              THEN ROLLING_EXPIRATION_DATE
                         ELSE
                              COALESCE(NOTED_EXPIRATION_DATE, CALCULATED_EXPIRATION_DATE)
                    END
                  ) AS ENDDATE
      FROM TERMS_CONDITIONS_RAW
)

, TERMS_CONDITIONS_GAPS AS
(
    -- because "gaps" don't exist we will caculate them frmo the lack of an active record
    SELECT COUNCIL_MEMBER_ID
          ,NULL AS TERMS_CONDITIONS_SIGNED_DATE
          ,STARTDATE AS ORIGINAL_START_DATE
          ,CAST(DATEADD(ns, 100, ENDDATE) AS DATETIME2) AS STARTDATE
          ,CAST(DATEADD(ns, -100, ISNULL(LEAD(STARTDATE) OVER (PARTITION BY COUNCIL_MEMBER_ID ORDER BY STARTDATE), GETDATE())) AS DATETIME2) AS ENDDATE
      FROM TERMS_CONDITIONS_ACTIVE
)

, TERMS_CONDITIONS AS
(
    -- put it together to make a MECE timeline of T&C's
    SELECT COUNCIL_MEMBER_ID
          ,TERMS_CONDITIONS_SIGNED_DATE
          ,STARTDATE
          ,ENDDATE
      FROM TERMS_CONDITIONS_ACTIVE
     UNION
       ALL
    SELECT tcg.COUNCIL_MEMBER_ID
          ,tcg.TERMS_CONDITIONS_SIGNED_DATE
          ,tcg.STARTDATE
          ,tcg.ENDDATE
      FROM TERMS_CONDITIONS_GAPS tcg
     WHERE tcg.STARTDATE <  tcg.ENDDATE
)

, BIO_RAW AS
(
    -- Grab & make unique when Bios are updated for CMs (need to figure out a way to actually get
    -- the BIO in without blowing up the query plan **possibly flaking**)
    SELECT DISTINCT
           cmura.COUNCIL_MEMBER_ID
          ,CAST(cmura.CREATE_DATE AS DATETIME2) AS LAST_BIO_UPDATE
          ,CAST(cmura.CREATE_DATE AS DATETIME2) AS STARTDATE
      FROM GLGLIVE..COUNCIL_MEMBER_UPDATE_REQUEST_ARCHIVE cmura
     WHERE cmura.REQUESTED_ACTION = 'EB'
       AND cmura.ACTION_TAKEN = 'A' -- actions represent succesfully completed BIO
       AND (
               CONVERT(DATE, cmura.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
           )
)

, BIO AS
(
    -- figure out end date for bio
    SELECT COUNCIL_MEMBER_ID
          ,LAST_BIO_UPDATE
          ,STARTDATE
          ,ISNULL(DATEADD(ns, -100, CAST(LEAD(STARTDATE) OVER(PARTITION BY COUNCIL_MEMBER_ID ORDER BY STARTDATE) AS DATETIME2)), GETDATE()) AS ENDDATE
      FROM BIO_RAW
)

, CM_RATE_HISTORY_RAW AS
(
    -- Create the TSP for the CMs rate history & remove dupes
    SELECT DISTINCT
           cmr.COUNCIL_MEMBER_ID
          ,CAST(cmr.CREATE_DATE AS DATETIME2) AS STARTDATE
          ,cmr.RATE_AMOUNT AS CONSULTATION_RATE
      FROM GLGLIVE..COUNCIL_MEMBER_RATE cmr
     WHERE cmr.Product_Type_ID = 3  -- Consultation rates as this is the base rate used
       AND cmr.Rate_Amount > 0  -- 0 and NULL rates are some outcome just written by different apps
       AND (
                CONVERT(DATE, cmr.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
             OR CONVERT(DATE, cmr.LAST_UPDATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
           )
)

, CM_RATE_HISTORY AS
(
    -- figure out end date for rate history
    SELECT COUNCIL_MEMBER_ID
          ,STARTDATE
          ,ISNULL(DATEADD(ns, -100, CAST(LEAD(STARTDATE) OVER(PARTITION BY COUNCIL_MEMBER_ID ORDER BY STARTDATE) AS DATETIME2)), GETDATE()) AS ENDDATE
          ,CONSULTATION_RATE
      FROM CM_RATE_HISTORY_RAW
)

, CM_JOB_AND_TITLE_HISTORY_RAW AS
(
    -- TSP for Job & Title histories (these two attributes are always update symultaniously)
    SELECT DISTINCT
           cmjfrh.COUNCIL_MEMBER_ID
          ,CAST(cmjfrh.CREATE_DATE AS DATETIME2) AS STARTDATE
          ,cmjfrh.COMPANY
          ,cmjfrh.TITLE
      FROM GLGLIVE..COUNCIL_MEMBER_JOB_FUNCTION_RELATION_HISTORY cmjfrh
     WHERE (
               CONVERT(DATE, cmjfrh.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
            OR CONVERT(DATE, cmjfrh.LAST_UPDATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
           )
)

, CM_JOB_AND_TITLE_HISTORY AS
(
    -- get job history & title associated with the work
    SELECT COUNCIL_MEMBER_ID
          ,STARTDATE
          ,ISNULL(DATEADD(ns, -100, CAST(LEAD(STARTDATE) OVER(PARTITION BY COUNCIL_MEMBER_ID ORDER BY STARTDATE) AS DATETIME2)), GETDATE()) AS ENDDATE
          ,COMPANY
          ,TITLE
      FROM CM_JOB_AND_TITLE_HISTORY_RAW
)

, CM_FLAGS_RAW AS
(
    -- get CM flags this will be split out into multiple joins later (kept together for performance
    -- against window agg in CM_FLAGS CTE)
    SELECT cmfh.COUNCIL_MEMBER_ID
          ,cmfh.CREATE_DATE AS STARTDATE
          ,cmfh.CREATE_DATE
          ,CASE
                WHEN [ACTION] = 'DELETE' THEN 0
                ELSE 1
           END AS ACTION_OUTCOME
          ,CASE
                WHEN cmf.COUNCIL_MEMBER_FLAG_SUBTYPE_ID = 1
                     THEN 'IDNC_FLAG'
                WHEN cmf.COUNCIL_MEMBER_FLAG_SUBTYPE_ID = 4
                     THEN 'CAUTION'
                WHEN cmf.COUNCIL_MEMBER_FLAG_SUBTYPE_ID = 5
                     THEN 'ACTION_REQUIRED_FLAG'
                WHEN cmf.COUNCIL_MEMBER_FLAG_SUBTYPE_ID = 8
                     THEN 'MEMBER_PROGRAM'
                WHEN cmfh.COUNCIL_MEMBER_FLAG_ID = 43
                     THEN 'PREMIUM_CM'
           END AS CM_FLAG_GROUP
          ,cmf.DESCRIPTION
          ,CASE
                WHEN [ACTION] = 'DELETE'
                     THEN NULL
                ELSE
                     COMMENTS
           END AS COMMENTS -- from a business experience when a flag is deleted there is no longer a comment
      FROM GLGLIVE..COUNCIL_MEMBER_FLAG_HISTORY cmfh
     INNER
      JOIN GLGLIVE..COUNCIL_MEMBER_FLAG cmf
        ON cmfh.COUNCIL_MEMBER_FLAG_ID = cmf.COUNCIL_MEMBER_FLAG_ID
     WHERE (
                CONVERT(DATE, cmfh.CREATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
             OR CONVERT(DATE, cmfh.FLAG_RELATION_LAST_UPDATE_DATE, 108) = (
                                     SELECT last_run_date
                                       FROM jobcontrol 
                                      WHERE name = 'DIM_COUNCIL_MEMBER'
                                        AND active_ind = 1
                                        AND runnable_ind = 1
                                   )
           )
)

, CM_FLAGS AS
(
    -- add end dates, note that since this is a combined set its also split by group for
    -- larger timeframes if tags overlap (split in later joins)
    SELECT COUNCIL_MEMBER_ID
          ,CM_FLAG_GROUP
          ,[DESCRIPTION]
          ,ACTION_OUTCOME
          ,COMMENTS
          ,STARTDATE
          ,ISNULL(DATEADD(ns, -100, CAST(LEAD(STARTDATE) OVER(PARTITION BY COUNCIL_MEMBER_ID, CM_FLAG_GROUP ORDER BY STARTDATE) AS DATETIME2)), GETDATE()) AS ENDDATE
      FROM CM_FLAGS_RAW
)

, LANGUAGES AS
(
    -- get languages and use RN for denormed columns later when combining back
    SELECT DISTINCT
           pl.COUNCIL_MEMBER_ID
          ,l.[LANGUAGE]
          ,pl.language_id
          ,ROW_NUMBER() OVER ( PARTITION BY pl.COUNCIL_MEMBER_ID ORDER BY pl.proficiency, pl.LANGUAGE_ID) AS RN
      FROM GLGLIVE..person_language pl
     INNER
      JOIN GLGLIVE..[LANGUAGE] l ON l.LANGUAGE_ID = pl.LANGUAGE_ID
    WHERE pl.COUNCIL_MEMBER_ID IS NOT NULL
      AND pl.proficiency > 5
      AND pl.language_id IS NOT NULL
)

, D_DEMO AS
(
    -- generates D_DEMO key & associated grain changes from that (TSP)
    SELECT NULL AS HOLDER_UNTIL_D_DEMO_IS_DONE
)

, COMBINED_RAW AS
(
    -- combine all of the attributes
    SELECT 'COUNCIL_MEMBER_BASE' AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM COUNCIL_MEMBER_BASE
     UNION
       ALL
    SELECT 'TERMS_CONDITIONS' AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM TERMS_CONDITIONS
     UNION
       ALL
    SELECT 'BIO' AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM BIO
     UNION
       ALL
    SELECT 'CM_RATE_HISTORY' AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM CM_RATE_HISTORY
     UNION
       ALL
    SELECT 'CM_JOB_AND_TITLE_HISTORY' AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM CM_JOB_AND_TITLE_HISTORY
     UNION
       ALL
    SELECT [DESCRIPTION] AS ATTR
          ,COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM CM_FLAGS
)

, UNIQUE_COMBINED AS
(
    -- Create the grain on the end table by removing the attribute type & end dates
    -- (this can lead to duplicate rows)
    SELECT DISTINCT
           COUNCIL_MEMBER_ID
          ,STARTDATE
      FROM COMBINED_RAW
)

, COMBINED_TSP AS
(
    -- add in the END_DATE fine grain time frames for join back
    SELECT COUNCIL_MEMBER_ID
          ,STARTDATE AS [START_DATE]
          ,DATEADD(ns, -100, CAST(LEAD(STARTDATE) OVER(PARTITION BY COUNCIL_MEMBER_ID ORDER BY STARTDATE) AS DATETIME2)) AS END_DATE
      FROM UNIQUE_COMBINED
)

, COMBINED_OUTPUT AS
(
    -- join back indivudal overlaps against finer combined grain to create TSP
    SELECT HASHBYTES
           (
               'SHA2_256'
              ,CAST(ISNULL(tsp.COUNCIL_MEMBER_ID, '') AS VARCHAR(250)) +
               CAST(ISNULL('D_DEMO_KEY', '') AS VARCHAR(250)) +
               CAST(ISNULL(t_c.TERMS_CONDITIONS_SIGNED_DATE, '') AS VARCHAR(250)) +
               CAST(ISNULL(bio.LAST_BIO_UPDATE, '')  AS VARCHAR(250)) +
               CAST(ISNULL(rates.CONSULTATION_RATE, '') AS VARCHAR(250)) +
               CAST(ISNULL(jobs.COMPANY, '') AS VARCHAR(250)) +
               CAST(ISNULL(jobs.TITLE, '') AS VARCHAR(250)) +
               CAST(ISNULL(FLAG_CAUTION.COMMENTS, '') AS VARCHAR(250)) +
               CAST(ISNULL(FLAG_ACTION_REQUIRED.COMMENTS, '') AS VARCHAR(250)) +
               CAST(ISNULL(FLAG_MEMBER_PROGRAM.COMMENTS, '') AS VARCHAR(250)) +
               CAST(ISNULL(FLAG_PREMIUM.COMMENTS, '') AS VARCHAR(250)) +
               CAST(ISNULL([START_DATE] , '') AS  VARCHAR(250))
           ) AS D_KEY
          ,tsp.COUNCIL_MEMBER_ID
          ,CASE
                WHEN NOT EXISTS (
                                  SELECT 1
                                    FROM GLGLIVE..TERMS_CONDITIONS_SIGNED
                                   WHERE COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
                                )
                     THEN 'Lead' -- need to check if they ever signed
                WHEN     rates.CONSULTATION_RATE IS NOT NULL
                     AND bio.LAST_BIO_UPDATE IS NOT NULL
                     AND (jobs.TITLE IS NOT NULL OR jobs.COMPANY IS NOT NULL)
                     THEN 'CM 4'
                ELSE
                     'Council Member'
           END AS [STATUS]
          ,cm_b.RECRUITED_BY
          ,cm_b.INFLOW_METHOD
          ,t_c.TERMS_CONDITIONS_SIGNED_DATE
          ,LAST_BIO_UPDATE
          ,rates.CONSULTATION_RATE
          ,CASE
                WHEN cm_b.DNC = 0
                     THEN NULL -- person table DNC should drive if someone is actually DNC'd
                WHEN FLAG_IDNC.COMMENTS IS NOT NULL
                     THEN FLAG_IDNC.COMMENTS -- grab the message from flags if we can
                ELSE
                     'Company DNC' -- assume company DNC (could be improved) if no flag
           END AS DNC
          ,jobs.COMPANY
          ,jobs.TITLE
          ,cm_b. RETIRED
          ,cm_b.PRACTICE_AREA
          ,cm_b.COUNCIL_NAME
          ,LANGUAGE_1.[LANGUAGE] AS LANGUAGE_1
          ,LANGUAGE_2.[LANGUAGE] AS LANGUAGE_2
          ,LANGUAGE_3.[LANGUAGE] AS LANGUAGE_3
          ,LANGUAGE_4.[LANGUAGE] AS LANGUAGE_4
          ,'[' + FLAG_CAUTION.[DESCRIPTION] + ']:  ' +  FLAG_CAUTION.COMMENTS AS CAUTION_FLAG
          ,'[' + FLAG_ACTION_REQUIRED.[DESCRIPTION] + ']:  ' + FLAG_ACTION_REQUIRED.COMMENTS AS ACTION_REQUIRED_FLAG
          ,'[' + FLAG_MEMBER_PROGRAM.[DESCRIPTION] + ']:  ' + FLAG_MEMBER_PROGRAM.COMMENTS  AS MEMBER_PROGRAM_FLAG
          ,'[' + FLAG_PREMIUM.[DESCRIPTION] + ']:  ' + FLAG_PREMIUM.COMMENTS AS PREMIUM_FLAG
          ,tsp.[START_DATE]
          ,tsp.END_DATE
          ,  CAST(YEAR(tsp.[START_DATE]) AS NVARCHAR)
           + RIGHT('00' + CAST(MONTH(tsp.[START_DATE]) AS NVARCHAR),2)
           + RIGHT('00' + CAST(DAY(tsp.[START_DATE]) AS NVARCHAR),2) AS START_DATE_DATE_KEY
          ,  CAST(YEAR(tsp.[END_DATE]) AS NVARCHAR)
           + RIGHT('00' + CAST(MONTH(tsp.[END_DATE]) AS NVARCHAR),2)
           + RIGHT('00' + CAST(DAY(tsp.[END_DATE]) AS NVARCHAR),2) AS END_DATE_DATE_KEY
      FROM COMBINED_TSP tsp
      LEFT
      JOIN COUNCIL_MEMBER_BASE cm_b
        ON cm_b.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND cm_b.ENDDATE >= tsp.START_DATE
       AND cm_b.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN TERMS_CONDITIONS t_c
        ON t_c.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND t_c.ENDDATE >= tsp.START_DATE
       AND t_c.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN BIO bio
        ON bio.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND bio.ENDDATE >= tsp.START_DATE
       AND bio.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_RATE_HISTORY rates
        ON rates.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND rates.ENDDATE >= tsp.START_DATE
       AND rates.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_JOB_AND_TITLE_HISTORY jobs
        ON jobs.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND jobs.ENDDATE >= tsp.START_DATE
       AND jobs.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_FLAGS FLAG_IDNC
        ON FLAG_IDNC.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND FLAG_IDNC.[DESCRIPTION] = 'IDNC_FLAG'
       AND FLAG_IDNC.ENDDATE >= tsp.START_DATE
       AND FLAG_IDNC.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_FLAGS FLAG_CAUTION
        ON FLAG_CAUTION.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND FLAG_CAUTION.[DESCRIPTION] = 'CAUTION'
       AND FLAG_CAUTION.ENDDATE >= tsp.START_DATE
       AND FLAG_CAUTION.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_FLAGS FLAG_ACTION_REQUIRED
        ON FLAG_ACTION_REQUIRED.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND FLAG_ACTION_REQUIRED.[DESCRIPTION] = 'ACTION_REQUIRED_FLAG'
       AND FLAG_ACTION_REQUIRED.ENDDATE >= tsp.START_DATE
       AND FLAG_ACTION_REQUIRED.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_FLAGS FLAG_MEMBER_PROGRAM
        ON FLAG_MEMBER_PROGRAM.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND FLAG_MEMBER_PROGRAM.[DESCRIPTION] = 'MEMBER_PROGRAM'
       AND FLAG_MEMBER_PROGRAM.ENDDATE >= tsp.START_DATE
       AND FLAG_MEMBER_PROGRAM.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN CM_FLAGS FLAG_PREMIUM
        ON FLAG_PREMIUM.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND FLAG_PREMIUM.[DESCRIPTION] = 'PREMIUM_CM'
       AND FLAG_PREMIUM.ENDDATE >= tsp.START_DATE
       AND FLAG_PREMIUM.STARTDATE < ISNULL(tsp.END_DATE, GETDATE())
      LEFT
      JOIN LANGUAGES AS LANGUAGE_1
        ON LANGUAGE_1.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND LANGUAGE_1.RN = 1
      LEFT
      JOIN LANGUAGES AS LANGUAGE_2
        ON LANGUAGE_1.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND LANGUAGE_1.RN = 2
      LEFT
      JOIN LANGUAGES AS LANGUAGE_3
        ON LANGUAGE_1.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND LANGUAGE_1.RN = 3
      LEFT
      JOIN LANGUAGES AS LANGUAGE_4
        ON LANGUAGE_1.COUNCIL_MEMBER_ID = tsp.COUNCIL_MEMBER_ID
       AND LANGUAGE_1.RN = 4
     WHERE tsp.[START_DATE] < ISNULL(tsp.END_DATE, GETDATE())
)


SELECT -- post TSP work
       CAST(D_KEY AS BINARY(32)) AS D_KEY
      ,CAST(COUNCIL_MEMBER_ID AS INT) AS COUNCIL_MEMBER_ID

      /* Adding below instead of link to D_DEMO */
      ,NULL AS FIRST_NAME
      ,NULL AS LAST_NAME
      ,NULL AS DESCRIPTION
      ,NULL AS ADDRESS_LINE_1
      ,NULL AS CITY
      ,NULL AS STATE
      ,NULL AS POSTALCODE
      ,NULL AS COUNTRY
      ,NULL AS REGION
      ,NULL AS EMAIL
      ,NULL AS PHONE
      /* Adding above instead of link to D_DEMO */

      ,CAST([STATUS] AS NVARCHAR(42)) AS [STATUS]
      ,CAST(INFLOW_METHOD AS NVARCHAR(42)) AS INFLOW_METHOD
      ,CAST(TITLE AS NVARCHAR(MAX)) AS TITLE
      ,CAST(COMPANY AS NVARCHAR(MAX)) AS COMPANY
      ,CAST(LAST_BIO_UPDATE AS DATETIME2) AS LAST_BIO_UPDATE
      ,CAST(TERMS_CONDITIONS_SIGNED_DATE AS DATETIME2) AS TC_SIGNED_DATE
      ,CAST(CONSULTATION_RATE AS DECIMAL(16,4)) AS CONSULTATION_RATE
      ,CAST(RECRUITED_BY AS BINARY(32)) AS RECRUITED_BY_D_EMP_KEY -- need to be moved to D_EMP key
      ,CAST(COUNCIL_NAME AS NVARCHAR(32)) AS COUNCIL_NAME
      ,CAST(PRACTICE_AREA AS NVARCHAR(32)) AS PRACTICE_AREA
      ,CAST(DNC AS NVARCHAR(42)) AS DNC
      ,CAST(CAUTION_FLAG AS NVARCHAR(46)) AS CAUTION_FLAG
      ,CAST(ACTION_REQUIRED_FLAG AS NVARCHAR(50)) AS ACTION_REQUIRED_FLAG
      ,CAST(MEMBER_PROGRAM_FLAG AS NVARCHAR(61)) AS MEMBER_PROGRAM_FLAG
      ,CAST(PREMIUM_FLAG AS NVARCHAR(42)) AS PREMIUM_FLAG
      ,CAST(RETIRED AS BIT) AS RETIRED
      ,CAST(LANGUAGE_1 AS NVARCHAR(32)) AS LANGUAGE_PREFERRED
      ,CAST(LANGUAGE_2 AS NVARCHAR(32)) AS LANGUAGE_2
      ,CAST(LANGUAGE_3 AS NVARCHAR(32)) AS LANGUAGE_3
      ,CAST(LANGUAGE_4 AS NVARCHAR(32)) AS LANGUAGE_4
      ,CAST(NULL AS BINARY(32)) AS D_DEMO_KEY
      ,CAST([START_DATE] AS DATETIME2) AS [START_DATE]
      ,CAST(END_DATE AS DATETIME2) AS END_DATE
      ,CAST(START_DATE_DATE_KEY AS INT) AS START_DATE_DATE_KEY
      ,CAST(END_DATE_DATE_KEY AS INT) AS END_DATE_DATE_KEY
  FROM COMBINED_OUTPUT
go



