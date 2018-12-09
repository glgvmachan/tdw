USE poc
go

CREATE OR ALTER VIEW vw_user_src
AS
SELECT SCT.Id AS ID
      ,SCT.FirstName AS FIRST_NAME
      ,SCT.LastName AS LAST_NAME
      ,SCT.Name AS NAME
      ,SCT.Title AS TITLE
      ,SCT.Description AS DESCRIPTION
      ,SCT.MailingStreet AS ADDRESS_LINE_1
      ,SCT.MailingCity AS CITY
      ,SCT.MailingState AS STATE
      ,SCT.MailingPostalCode AS POSTALCODE
      ,SCT.MailingCountry AS COUNTRY
      ,SCT.country_regions__c AS REGION
      ,SCT.Email AS EMAIL
      ,SCT.Phone AS PHONE
      ,SCT.AccountId AS ACCOUNTID
      ,SCT.DoNotCall AS DONOTCALL
      ,SCT.HasOptedOutOfEmail AS HASOPTEDOUTOFEMAIL
      ,SCT.HasOptedOutOfFax AS HASOPTEDOUTOFFAX
      ,ISNULL(SUR.Vega_Person_Id__c, GRM.USER_ID) AS USER_SALES_OWNER_PERSON_ID
      ,ISNULL(SUO.Vega_Person_Id__c, CSA.GLG_ID) AS USER_RESEARCH_OWNER_PERSON_ID
      ,COALESCE(SCT.currently_at_firm__c, 0) AS AT_FIRM
      ,CAST(
             (CASE WHEN SCT.CreatedDate > COALESCE(SCT.LastModifiedDate, '01/01/1900')
                  THEN SCT.CreatedDate
                  ELSE SCT.LastModifiedDate
             END)
           AS DATETIME2
           ) AS START_DATE
      ,CAST(GETDATE() AS DATETIME2) AS END_DATE
  FROM SFDC..Contact SCT
  LEFT
  JOIN SFDC..[User] SUR
    ON SCT.Rm_Coverage_Primary__c = SUR.Id
  LEFT
  JOIN GLGLIVE..CONTACT_RELATIONSHIP_MANAGER GRM
    ON GRM.CONTACT_ID = SCT.VegaID__C 
   AND GRM.ACTIVE_IND = 1
  LEFT
  JOIN SFDC..[User] SUO
    ON SCT.OwnerId = SUO.Id
  LEFT
  JOIN GLGLIVE..CONTACT_SALES_ASSIGNMENT CSA
    ON CSA.CONTACT_ID = SCT.VegaID__C 
   AND CSA.ACTIVE_IND = 1
   AND CSA.PRIMARY_IND = 1
 WHERE 1 = 1
   AND SCT.IsDeleted = 0
   AND CAST(SCT.CreatedDate as date) >=     (
                                              SELECT last_run_date
                                                FROM jobcontrol
                                               WHERE name = 'DIM_USER'
                                                 AND active_ind = 1
                                                 AND runnable_ind = 1
                                            )
   OR CAST(SCT.LastModifiedDate as date) >= (
                                              SELECT last_run_date
                                                FROM jobcontrol
                                               WHERE name = 'DIM_USER'
                                                 AND active_ind = 1
                                                 AND runnable_ind = 1
                                            )
go

