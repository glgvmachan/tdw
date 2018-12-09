USE poc
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS START_DATE_TIME
go

TRUNCATE TABLE dim_product_type
go

INSERT
  INTO dim_product_type
(
       PRODUCT_TYPE_ID
      ,PRODUCT_TYPE_DESC
      ,CATEGORY_NAME
      ,PRODUCT_TYPE_CATEGORY_ID
      ,CUSTOMIZABLE_IND
      ,PCT_IND
      ,TRANSACTION_IND
      ,ALLOWS_MULTIPLE_PAYMENTS_IND
      ,DURATION_BASED_PAYMENTS_IND
      ,ELIGIBLE_FOR_PAYMENTS_IND
      ,STANDARD_MARKUP
      ,ACTIVE_IND
      ,EFF_FROM_DATE
      ,EFF_TO_DATE
)
SELECT
       MERGEOUT.PRODUCT_TYPE_ID
      ,MERGEOUT.PRODUCT_TYPE_DESC
      ,MERGEOUT.CATEGORY_NAME
      ,MERGEOUT.PRODUCT_TYPE_CATEGORY_ID
      ,MERGEOUT.CUSTOMIZABLE_IND
      ,MERGEOUT.PCT_IND
      ,MERGEOUT.TRANSACTION_IND
      ,MERGEOUT.ALLOWS_MULTIPLE_PAYMENTS_IND
      ,MERGEOUT.DURATION_BASED_PAYMENTS_IND
      ,MERGEOUT.ELIGIBLE_FOR_PAYMENTS_IND
      ,MERGEOUT.STANDARD_MARKUP
      ,'Y'          /* ACTVE_IND */
      ,GETDATE()    /* EFF_FROM_DATE */
      ,'12/31/9999' /* EFF_TO_DATE   */
  FROM
      (
          MERGE dim_product_type TGT
          USING (
                  SELECT VPS.PRODUCT_TYPE_ID
	                ,VPS.PRODUCT_TYPE_DESC
                        ,VPS.CATEGORY_NAME
	                ,VPS.PRODUCT_TYPE_CATEGORY_ID
	                ,VPS.CUSTOMIZABLE_IND
	                ,VPS.PCT_IND
	                ,VPS.TRANSACTION_IND
	                ,VPS.STANDARD_MARKUP
	                ,VPS.ALLOWS_MULTIPLE_PAYMENTS_IND
	                ,VPS.DURATION_BASED_PAYMENTS_IND
	                ,VPS.ELIGIBLE_FOR_PAYMENTS_IND
                    FROM POC..vw_product_src VPS
                ) SRC
             ON SRC.PRODUCT_TYPE_ID = TGT.PRODUCT_TYPE_ID
            AND SRC.PRODUCT_TYPE_CATEGORY_ID = TGT.PRODUCT_TYPE_CATEGORY_ID
            AND TGT.EFF_TO_DATE = '12/31/9999'
           WHEN MATCHED
            AND (
                     TGT.PRODUCT_TYPE_DESC != SRC.PRODUCT_TYPE_DESC
                  OR TGT.CATEGORY_NAME != SRC.CATEGORY_NAME
                  OR TGT.PRODUCT_TYPE_CATEGORY_ID != SRC.PRODUCT_TYPE_CATEGORY_ID
                  OR TGT.CUSTOMIZABLE_IND != SRC.CUSTOMIZABLE_IND
                  OR TGT.PCT_IND != SRC.PCT_IND
                  OR TGT.TRANSACTION_IND != SRC.TRANSACTION_IND
                  OR TGT.STANDARD_MARKUP != SRC.STANDARD_MARKUP
                )
           THEN 
         UPDATE
            SET TGT.EFF_TO_DATE = GETDATE()
               ,TGT.ACTIVE_IND = 'N'
           WHEN NOT MATCHED
           THEN
         INSERT
                (
                  PRODUCT_TYPE_ID
                 ,PRODUCT_TYPE_DESC
                 ,CATEGORY_NAME
                 ,PRODUCT_TYPE_CATEGORY_ID
                 ,CUSTOMIZABLE_IND
                 ,PCT_IND
                 ,TRANSACTION_IND
                 ,ALLOWS_MULTIPLE_PAYMENTS_IND
                 ,DURATION_BASED_PAYMENTS_IND
                 ,ELIGIBLE_FOR_PAYMENTS_IND
                 ,STANDARD_MARKUP
                 ,ACTIVE_IND
                 ,EFF_FROM_DATE
                 ,EFF_TO_DATE
                )
         VALUES
                (
                  SRC.PRODUCT_TYPE_ID
                 ,SRC.PRODUCT_TYPE_DESC
                 ,SRC.CATEGORY_NAME
                 ,SRC.PRODUCT_TYPE_CATEGORY_ID
                 ,SRC.CUSTOMIZABLE_IND
                 ,SRC.PCT_IND
                 ,SRC.TRANSACTION_IND
                 ,SRC.ALLOWS_MULTIPLE_PAYMENTS_IND
                 ,SRC.DURATION_BASED_PAYMENTS_IND
                 ,SRC.ELIGIBLE_FOR_PAYMENTS_IND
                 ,SRC.STANDARD_MARKUP
                 ,'Y'            /* ACTIVE_IND    */
                 ,GETDATE()      /* EFF_FROM_DATE */
                 ,'12/31/9999'   /* EFF_TO_DATE   */
                )
         OUTPUT
                $action AS MERGEACTION
               ,SRC.PRODUCT_TYPE_ID
               ,SRC.PRODUCT_TYPE_DESC
               ,SRC.CATEGORY_NAME
               ,SRC.PRODUCT_TYPE_CATEGORY_ID
               ,SRC.CUSTOMIZABLE_IND
               ,SRC.PCT_IND
               ,SRC.TRANSACTION_IND
               ,SRC.ALLOWS_MULTIPLE_PAYMENTS_IND
               ,SRC.DURATION_BASED_PAYMENTS_IND
               ,SRC.ELIGIBLE_FOR_PAYMENTS_IND
               ,SRC.STANDARD_MARKUP
      ) AS MERGEOUT
 WHERE MERGEOUT.MERGEACTION = 'UPDATE'
go

SELECT CONVERT(VARCHAR(32), GETDATE(), 121) AS FINISH_DATE_TIME
go

