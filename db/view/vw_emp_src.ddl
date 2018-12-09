USE tdw
go

CREATE OR ALTER VIEW vw_emp_src
AS
WITH BASE_DATA AS (
         SELECT 
                UT.USER_ID AS ID
               ,FEA.ActionTypeCode 
               ,FEA.AssignmentStartDate AS FEA_STARTDATE 
               ,FEA.AssignmentEndDate AS FEA_ENDDATE 
               ,FEA.FirstName AS FIRST_NAME -- P.FIRST_NAME
               ,FEA.LastName AS LAST_NAME -- P.LAST_NAME
               ,FEA.JobTitle AS TITLE -- P.TITLE
               ,P.EMAIL
               ,UT.PHONE
               ,UT.FAX
               ,UT.MOBILE
               ,UT.NOTIFY_RESEARCH
               ,UT.COUNCIL_ID
               ,UT.DEPARTMENT
               ,UT.EMPLOYEE_TYPE_ID
               ,FEA.Location AS LOCATION
               ,FEA.ROLE AS FUSION_ROLE
               ,FEA.ManagerId
               ,FEA.ManagerName
               ,FEA.ManagerFirstName
               ,FEA.ManagerLastName
           FROM FUSION..employeeAssignmentHistory FEA
           LEFT
           JOIN GLGLIVE..USER_TABLE UT
             ON FEA.ID = UT.FUSION_ID
          INNER
           JOIN GLGLIVE..PERSON P
             ON UT.PERSON_ID = P.PERSON_ID
            AND UT.ACTIVE_IND = 1
            AND P.ACTIVE_IND = 1
            /* AND UT.USER_ID = 1122 TESTING */
          WHERE 1 = 1
            AND UT.ACTIVE_IND = 1
       )
    ,
UBU_DATES AS (
         SELECT UBU.[USER_ID]
               ,UBU.START_DATE AS UBU_STARTDATE
               ,LEAD(DATEADD(dd, -1, UBU.START_DATE), 1, GETDATE()) OVER ( PARTITION BY UBU.[USER_ID] ORDER BY UBU.START_DATE) AS UBU_ENDDATE 
               ,UBUT.BUSINESS_UNIT
               ,UBUT.SEGMENT
               ,UBUT.POD
               ,UBUT.TEAM
               ,UBUT.MANAGER_USER_ID
           FROM GLGLIVE.employee.USER_BUSINESS_UNIT UBU
          INNER
           JOIN GLGLIVE.employee.USER_BUSINESS_UNIT_TAXONOMY UBUT
             ON UBU.TAXONOMY_ID = UBUT.TAXONOMY_ID
          INNER
           JOIN GLGLIVE..USER_TABLE UT
             ON UBU.USER_ID = UT.USER_ID
              ) 
SELECT BASE_DATA.ID
      ,BASE_DATA.ActionTypeCode 
      ,BASE_DATA.FEA_STARTDATE 
      ,BASE_DATA.FEA_ENDDATE 
      ,BASE_DATA.FIRST_NAME
      ,BASE_DATA.LAST_NAME
      ,BASE_DATA.TITLE
      ,BASE_DATA.EMAIL
      ,BASE_DATA.PHONE
      ,BASE_DATA.FAX
      ,BASE_DATA.MOBILE
      ,BASE_DATA.NOTIFY_RESEARCH
      ,BASE_DATA.COUNCIL_ID
      ,BASE_DATA.DEPARTMENT
      ,BASE_DATA.EMPLOYEE_TYPE_ID
      ,BASE_DATA.LOCATION
      ,BASE_DATA.FUSION_ROLE
      ,BASE_DATA.ManagerId
      ,BASE_DATA.ManagerName
      ,BASE_DATA.ManagerFirstName
      ,BASE_DATA.ManagerLastName

      ,UBU_DATES.UBU_STARTDATE
      ,UBU_DATES.UBU_ENDDATE 
      ,UBU_DATES.BUSINESS_UNIT AS BU
      ,UBU_DATES.SEGMENT
      ,UBU_DATES.POD
      ,UBU_DATES.TEAM
      ,UBU_DATES.MANAGER_USER_ID
  FROM BASE_DATA 
  LEFT
  JOIN UBU_DATES 
    ON BASE_DATA.[ID] = UBU_DATES.[USER_ID]
   AND BASE_DATA.FEA_ENDDATE >= UBU_DATES.UBU_STARTDATE
   AND BASE_DATA.FEA_STARTDATE <= UBU_DATES.UBU_ENDDATE
 WHERE 1 = 1
--  AND BASE_DATA.FEA_ENDDATE <> '4712-12-31'
   AND BASE_DATA.FEA_STARTDATE >= (
                                     SELECT last_run_date
                                       FROM tdw..etl_job_control 
                                      WHERE job_name = 'DIM_EMP'
                                       AND active_ind = 1
                                       AND runnable_ind = 1
                                  )
go

