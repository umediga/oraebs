DROP PACKAGE BODY APPS.XX_QP_GEN_INS_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_GEN_INS_CNV_PKG" AS
/*
 Created By     : Debjani Roy
 Creation Date  : 30-MAY-2013
 File Name      : XXQPINSERT.pkb
 Description    : This script creates the body of the package xx_qp_gen_ins_cnv_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     30-MAY-2013 Debjani Roy  Initial development.
-------------------------------------------------------------------------
*/
    PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_pricelist     IN VARCHAR2,
            p_modifier      IN VARCHAR2,
            p_qualgroups    IN VARCHAR2
              ) IS

         -- CURSOR FOR VARIOUS STAGES

    x_yes_no_yes VARCHAR2(1) := 'Y';

    BEGIN

       retcode := xx_emf_cn_pkg.CN_SUCCESS;

       IF p_pricelist = x_yes_no_yes THEN
          DELETE FROM XX_QP_PR_LIST_HDR_STG WHERE batch_id = p_batch_id;
          DELETE FROM XX_QP_PR_LIST_LINES_STG WHERE batch_id = p_batch_id;
          DELETE FROM XX_QP_PR_LIST_QLF_STG WHERE batch_id = p_batch_id;
       END IF;

       IF p_modifier = x_yes_no_yes THEN
          DELETE FROM XX_QP_MDPR_LIST_HDR_STG WHERE batch_id = p_batch_id;
          DELETE FROM XX_QP_MDPR_LIST_LINES_STG WHERE batch_id = p_batch_id;
          DELETE FROM XX_QP_MDPR_LIST_QLF_STG WHERE batch_id = p_batch_id;
       END IF;


       IF p_qualgroups = x_yes_no_yes THEN
          DELETE FROM XX_QP_RULES_QLF_STG WHERE batch_id = p_batch_id;
       END IF;


       COMMIT;

       IF p_modifier = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_MDPR_LIST_HDR_STG
                      ( BATCH_ID
                       ,RECORD_NUMBER
                       ,SOURCE_SYSTEM_NAME
                       ,LIST_TYPE_CODE
                       ,START_DATE_ACTIVE
                       ,END_DATE_ACTIVE
                       ,SOURCE_LANG
                       ,AUTOMATIC_FLAG
                       ,NAME
                       ,DESCRIPTION
                       ,CURRENCY_CODE
                       ,VERSION_NO
                       ,ROUNDING_FACTOR
                       ,SHIP_METHOD_CODE
                       ,FREIGHT_TERMS_CODE
                       ,COMMENTS
                       ,DISCOUNT_LINES_FLAG
                       ,GSA_INDICATOR
                       ,ASK_FOR_FLAG
                       ,ACTIVE_FLAG
                       ,PARENT_LIST_HEADER_ID
                       ,ACTIVE_DATE_FIRST_TYPE
                       ,START_DATE_ACTIVE_FIRST
                       ,END_DATE_ACTIVE_FIRST
                       ,ACTIVE_DATE_SECOND_TYPE
                       ,START_DATE_ACTIVE_SECOND
                       ,END_DATE_ACTIVE_SECOND
                       ,CONTEXT
                       ,ATTRIBUTE1
                       ,ATTRIBUTE2
                       ,ATTRIBUTE3
                       ,ATTRIBUTE4
                       ,ATTRIBUTE5
                       ,ATTRIBUTE6
                       ,ATTRIBUTE7
                       ,ATTRIBUTE8
                       ,ATTRIBUTE9
                       ,ATTRIBUTE10
                       ,ATTRIBUTE11
                       ,ATTRIBUTE12
                       ,ATTRIBUTE13
                       ,ATTRIBUTE14
                       ,ATTRIBUTE15
                       ,LANGUAGE
                       ,MOBILE_DOWNLOAD
                       ,CURRENCY_HEADER
                       ,PTE_CODE
                       ,LIST_SOURCE_CODE
                       ,ORIG_SYS_HEADER_REF
                       ,ORIG_ORG_NAME
                       ,GLOBAL_FLAG
                       ,ATTRIBUTE_STATUS
                       ,SHIP_METHOD
                       ,FREIGHT_TERMS
                       ,TERMS
                       ,PROCESS_CODE
                       )
                   (
                SELECT
                        BATCH_ID
                       ,RECORD_NUMBER
                       ,SOURCE_SYSTEM_NAME
                       ,LIST_TYPE_CODE
                       ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                       ,SOURCE_LANG
                       ,AUTOMATIC_FLAG
                       ,NAME
                       ,DESCRIPTION
                       ,CURRENCY_CODE
                       ,VERSION_NO
                       ,ROUNDING_FACTOR
                       ,SHIP_METHOD_CODE
                       ,FREIGHT_TERMS_CODE
                       ,COMMENTS
                       ,DISCOUNT_LINES_FLAG
                       ,GSA_INDICATOR
                       ,ASK_FOR_FLAG
                       ,ACTIVE_FLAG
                       ,PARENT_LIST_HEADER_ID
                       ,ACTIVE_DATE_FIRST_TYPE
                       ,TO_DATE(START_DATE_ACTIVE_FIRST,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE_FIRST,'MM/DD/YYYY')
                       ,ACTIVE_DATE_SECOND_TYPE
                       ,TO_DATE(START_DATE_ACTIVE_SECOND,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE_SECOND,'MM/DD/YYYY')
                       ,CONTEXT
                       ,ATTRIBUTE1
                       ,ATTRIBUTE2
                       ,ATTRIBUTE3
                       ,ATTRIBUTE4
                       ,ATTRIBUTE5
                       ,ATTRIBUTE6
                       ,ATTRIBUTE7
                       ,ATTRIBUTE8
                       ,ATTRIBUTE9
                       ,ATTRIBUTE10
                       ,ATTRIBUTE11
                       ,ATTRIBUTE12
                       ,ATTRIBUTE13
                       ,ATTRIBUTE14
                       ,ATTRIBUTE15
                       ,LANGUAGE
                       ,MOBILE_DOWNLOAD
                       ,CURRENCY_HEADER
                       ,PTE_CODE
                       ,LIST_SOURCE_CODE
                       ,ORIG_SYS_HEADER_REF
                       ,ORIG_ORG_NAME
                       ,GLOBAL_FLAG
                       ,ATTRIBUTE_STATUS
                       ,SHIP_METHOD
                       ,FREIGHT_TERMS
                       ,TERMS
                       ,'New'
                 FROM XX_QP_LOAD_HEADERS
                 WHERE LIST_TYPE_CODE <> 'PRL'
                  AND  batch_id =   p_batch_id
                       )   ;
           fnd_file.put_line(fnd_file.log,'~No of Records inserted in Modifier Hdr Staging Table =>'||SQL%ROWCOUNT);
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line(fnd_file.log,'Exception while inserting in Modifier Hdr Staging Table =>'||SQLERRM);
          ROLLBACK;
          retcode := 2;
       END;
       END IF;
       ---Insert into Pricelist header staging

       IF p_pricelist = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_PR_LIST_HDR_STG
                      ( BATCH_ID
                       ,RECORD_NUMBER
                       ,SOURCE_SYSTEM_NAME
                       ,LIST_TYPE_CODE
                       ,START_DATE_ACTIVE
                       ,END_DATE_ACTIVE
                       ,SOURCE_LANG
                       ,AUTOMATIC_FLAG
                       ,NAME
                       ,DESCRIPTION
                       ,CURRENCY_CODE
                       ,VERSION_NO
                       ,ROUNDING_FACTOR
                       ,SHIP_METHOD_CODE
                       ,FREIGHT_TERMS_CODE
                       ,COMMENTS
                       ,DISCOUNT_LINES_FLAG
                       ,GSA_INDICATOR
                       ,ASK_FOR_FLAG
                       ,ACTIVE_FLAG
                       ,PARENT_LIST_HEADER_ID
                       ,ACTIVE_DATE_FIRST_TYPE
                       ,START_DATE_ACTIVE_FIRST
                       ,END_DATE_ACTIVE_FIRST
                       ,ACTIVE_DATE_SECOND_TYPE
                       ,START_DATE_ACTIVE_SECOND
                       ,END_DATE_ACTIVE_SECOND
                       ,CONTEXT
                       ,ATTRIBUTE1
                       ,ATTRIBUTE2
                       ,ATTRIBUTE3
                       ,ATTRIBUTE4
                       ,ATTRIBUTE5
                       ,ATTRIBUTE6
                       ,ATTRIBUTE7
                       ,ATTRIBUTE8
                       ,ATTRIBUTE9
                       ,ATTRIBUTE10
                       ,ATTRIBUTE11
                       ,ATTRIBUTE12
                       ,ATTRIBUTE13
                       ,ATTRIBUTE14
                       ,ATTRIBUTE15
                       ,LANGUAGE
                       ,MOBILE_DOWNLOAD
                       ,CURRENCY_HEADER
                       ,PTE_CODE
                       ,LIST_SOURCE_CODE
                       ,ORIG_SYS_HEADER_REF
                       ,ORIG_ORG_NAME
                       ,GLOBAL_FLAG
                       ,ATTRIBUTE_STATUS
                       ,SHIP_METHOD
                       ,FREIGHT_TERMS
                       ,TERMS
                       ,PROCESS_CODE
                       )
                    (
                SELECT
                        BATCH_ID
                       ,RECORD_NUMBER
                       ,SOURCE_SYSTEM_NAME
                       ,LIST_TYPE_CODE
                       ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                       ,SOURCE_LANG
                       ,AUTOMATIC_FLAG
                       ,NAME
                       ,DESCRIPTION
                       ,CURRENCY_CODE
                       ,VERSION_NO
                       ,ROUNDING_FACTOR
                       ,SHIP_METHOD_CODE
                       ,FREIGHT_TERMS_CODE
                       ,COMMENTS
                       ,DISCOUNT_LINES_FLAG
                       ,GSA_INDICATOR
                       ,ASK_FOR_FLAG
                       ,ACTIVE_FLAG
                       ,PARENT_LIST_HEADER_ID
                       ,ACTIVE_DATE_FIRST_TYPE
                       ,TO_DATE(START_DATE_ACTIVE_FIRST,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE_FIRST,'MM/DD/YYYY')
                       ,ACTIVE_DATE_SECOND_TYPE
                       ,TO_DATE(START_DATE_ACTIVE_SECOND,'MM/DD/YYYY')
                       ,TO_DATE(END_DATE_ACTIVE_SECOND,'MM/DD/YYYY')
                       ,CONTEXT
                       ,ATTRIBUTE1
                       ,ATTRIBUTE2
                       ,ATTRIBUTE3
                       ,ATTRIBUTE4
                       ,ATTRIBUTE5
                       ,ATTRIBUTE6
                       ,ATTRIBUTE7
                       ,ATTRIBUTE8
                       ,ATTRIBUTE9
                       ,ATTRIBUTE10
                       ,ATTRIBUTE11
                       ,ATTRIBUTE12
                       ,ATTRIBUTE13
                       ,ATTRIBUTE14
                       ,ATTRIBUTE15
                       ,LANGUAGE
                       ,MOBILE_DOWNLOAD
                       ,CURRENCY_HEADER
                       ,PTE_CODE
                       ,LIST_SOURCE_CODE
                       ,ORIG_SYS_HEADER_REF
                       ,ORIG_ORG_NAME
                       ,GLOBAL_FLAG
                       ,ATTRIBUTE_STATUS
                       ,SHIP_METHOD
                       ,FREIGHT_TERMS
                       ,TERMS
                       ,'New'
                 FROM XX_QP_LOAD_HEADERS
                 WHERE LIST_TYPE_CODE = 'PRL'
                   AND  batch_id =   p_batch_id
                       )   ;
                 fnd_file.put_line(fnd_file.log,'~No of Records inserted in Pricelist Hdr Staging Table =>'||SQL%ROWCOUNT);
                 COMMIT;
          EXCEPTION
                WHEN OTHERS THEN
                   fnd_file.put_line(fnd_file.log,'Exception while inserting in Pricelist Hdr Staging Table =>'||SQLERRM);
                   ROLLBACK;
                   retcode := 2;
          END;
          END IF;

       ---Insert into Modlist line staging
       IF p_modifier = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_MDPR_LIST_LINES_STG
                (  BATCH_ID
                 ,RECORD_NUMBER
                 ,SOURCE_SYSTEM_NAME
                 ,LIST_LINE_TYPE_CODE
                 ,START_DATE_ACTIVE
                 ,END_DATE_ACTIVE
                 ,AUTOMATIC_FLAG
                 ,MODIFIER_LEVEL_CODE
                 ,LIST_PRICE
                 ,PRIMARY_UOM_FLAG
                 ,SUBSTITUTION_CONTEXT
                 ,SUBSTITUTION_ATTRIBUTE
                 ,SUBSTITUTION_VALUE
                 ,ORGANIZATION_NAME
                 ,REVISION
                 ,REVISION_DATE
                 ,REVISION_REASON_CODE
                 ,PRICE_BREAK_TYPE_CODE
                 ,PERCENT_PRICE
                 ,NUMBER_EFFECTIVE_PERIODS
                 ,EFFECTIVE_PERIOD_UOM
                 ,ARITHMETIC_OPERATOR
                 ,OPERAND
                 ,OVERRIDE_FLAG
                 ,PRINT_ON_INVOICE_FLAG
                 ,REBATE_TRXN_TYPE_CODE
                 ,ESTIM_ACCRUAL_RATE
                 ,LOCK_FLAG
                 ,COMMENTS
                 ,REPRICE_FLAG
                 ,LIST_LINE_NO
                 ,ESTIM_GL_VALUE
                 ,EXPIRATION_PERIOD_START_DATE
                 ,NUMBER_EXPIRATION_PERIODS
                 ,EXPIRATION_PERIOD_UOM
                 ,EXPIRATION_DATE
                 ,ACCRUAL_FLAG
                 ,PRICING_GROUP_SEQUENCE
                 ,INCOMPATIBILITY_GRP_CODE
                 ,PRODUCT_PRECEDENCE
                 ,ACCRUAL_CONVERSION_RATE
                 ,BENEFIT_QTY
                 ,BENEFIT_UOM_CODE
                 ,BENEFIT_LIMIT
                 ,BENFT_PLL_ORIG_SYS_LINE_REF
                 ,CHARGE_TYPE_CODE
                 ,CHARGE_SUBTYPE_CODE
                 ,INCLUDE_ON_RETURNS_FLAG
                 ,QUALIFICATION_IND
                 ,CONTEXT
                 ,ATTRIBUTE1
                 ,ATTRIBUTE2
                 ,ATTRIBUTE3
                 ,ATTRIBUTE4
                 ,ATTRIBUTE5
                 ,ATTRIBUTE6
                 ,ATTRIBUTE7
                 ,ATTRIBUTE8
                 ,ATTRIBUTE9
                 ,ATTRIBUTE10
                 ,ATTRIBUTE11
                 ,ATTRIBUTE12
                 ,ATTRIBUTE13
                 ,ATTRIBUTE14
                 ,ATTRIBUTE15
                 ,RLTD_MODIFIER_GRP_NO
                 ,RLTD_MODIFIER_GRP_TYPE
                 ,PRICE_BREAK_HEADER_INDEX
                 ,PRICE_LIST_LINE_INDEX
                 ,PRICING_PHASE_NAME
                 ,RECURRING_VALUE
                 ,NET_AMOUNT_FLAG
                 ,ORIG_SYS_LINE_REF
                 ,ORIG_SYS_HEADER_REF
                 ,PRICE_BREAK_HEADER_REF
                 ,GENERATE_USING_FORMULA
                 ,PRICE_BY_FORMULA
                 ,CONTINUOUS_PRICE_BREAK_FLAG
                 ,RLTD_ORIG_SYS_HDR_REF
                 ,FROM_ORIG_SYS_HDR_REF
                 ,TO_ORIG_SYS_HDR_REF
                 ,INVENTORY_ITEM
                 ,RELATED_ITEM
                 ,RELATIONSHIP_TYPE
                 ,PRORATION_TYPE_CODE
                 ,ACCUM_ATTRIBUTE
                 ,GL_CLASS
                 ,LIST_PRICE_UOM
                 ,REBATE_SUBTYPE
                 ,ACCRUAL_QTY
                 ,ACCRUAL_UOM_CODE
                 ,BASE_QTY
                 ,BASE_UOM_CODE
                 ,CUSTOMER_ITEM_NUMBER
                 ,BREAK_UOM_CODE
                 ,BREAK_UOM_CONTEXT
                 ,BREAK_UOM_ATTRIBUTE
                 ,PRICING_ATTRIBUTE_CONTEXT
                 ,PRODUCT_ATTRIBUTE_CONTEXT
                 ,PRODUCT_ATTRIBUTE
                 ,PRODUCT_ATTRIBUTE_CODE
                 ,PRICING_ATTRIBUTE
                 ,PRICING_ATTRIBUTE_NAME
                 ,PRODUCT_UOM_CODE
                 ,PRODUCT_UOM_DESC
                 ,PRODUCT_ATTR_VALUE
                 ,PRODUCT_ATTR_VALUE_CODE
                 ,PRICING_ATTR_VALUE_FROM
                 ,PRICING_ATTR_VALUE_TO
                 ,COMPARISON_OPERATOR_CODE
                 ,EXCLUDER_FLAG
                 ,MODIFIERS_INDEX
                 ,VOLUME_TYPE
                 ,ACTIVE_FLAG
                 ,ACCUMULATE_FLAG
                 ,ORIG_SYS_PRICING_ATTR_REF
                 ,PROCESS_CODE
                 )
                 (
                 SELECT
                      BATCH_ID
                    ,RECORD_NUMBER
                    ,SOURCE_SYSTEM_NAME
                    ,LIST_LINE_TYPE_CODE
                    ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                    ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                    ,AUTOMATIC_FLAG
                    ,MODIFIER_LEVEL_CODE
                    ,LIST_PRICE
                    ,PRIMARY_UOM_FLAG
                    ,SUBSTITUTION_CONTEXT
                    ,SUBSTITUTION_ATTRIBUTE
                    ,SUBSTITUTION_VALUE
                    ,ORGANIZATION_NAME
                    ,REVISION
                    ,TO_DATE(REVISION_DATE,'MM/DD/YYYY')
                    ,REVISION_REASON_CODE
                    ,PRICE_BREAK_TYPE_CODE
                    ,PERCENT_PRICE
                    ,NUMBER_EFFECTIVE_PERIODS
                    ,EFFECTIVE_PERIOD_UOM
                    ,ARITHMETIC_OPERATOR
                    ,OPERAND
                    ,OVERRIDE_FLAG
                    ,PRINT_ON_INVOICE_FLAG
                    ,REBATE_TRXN_TYPE_CODE
                    ,ESTIM_ACCRUAL_RATE
                    ,LOCK_FLAG
                    ,COMMENTS
                    ,REPRICE_FLAG
                    ,LIST_LINE_NO
                    ,ESTIM_GL_VALUE
                    ,TO_DATE(EXPIRATION_PERIOD_START_DATE,'MM/DD/YYYY')
                    ,NUMBER_EXPIRATION_PERIODS
                    ,EXPIRATION_PERIOD_UOM
                    ,TO_DATE(EXPIRATION_DATE,'MM/DD/YYYY')
                    ,ACCRUAL_FLAG
                    ,PRICING_GROUP_SEQUENCE
                    ,INCOMPATIBILITY_GRP_CODE
                    ,PRODUCT_PRECEDENCE
                    ,ACCRUAL_CONVERSION_RATE
                    ,BENEFIT_QTY
                    ,BENEFIT_UOM_CODE
                    ,BENEFIT_LIMIT
                    ,BENFT_PLL_ORIG_SYS_LINE_REF
                    ,CHARGE_TYPE_CODE
                    ,CHARGE_SUBTYPE_CODE
                    ,INCLUDE_ON_RETURNS_FLAG
                    ,QUALIFICATION_IND
                    ,CONTEXT
                    ,ATTRIBUTE1
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,RLTD_MODIFIER_GRP_NO
                    ,RLTD_MODIFIER_GRP_TYPE
                    ,PRICE_BREAK_HEADER_INDEX
                    ,PRICE_LIST_LINE_INDEX
                    ,PRICING_PHASE_NAME
                    ,RECURRING_VALUE
                    ,NET_AMOUNT_FLAG
                    ,ORIG_SYS_LINE_REF
                    ,ORIG_SYS_HEADER_REF
                    ,PRICE_BREAK_HEADER_REF
                    ,GENERATE_USING_FORMULA
                    ,PRICE_BY_FORMULA
                    ,CONTINUOUS_PRICE_BREAK_FLAG
                    ,RLTD_ORIG_SYS_HDR_REF
                    ,FROM_ORIG_SYS_HDR_REF
                    ,TO_ORIG_SYS_HDR_REF
                    ,INVENTORY_ITEM
                    ,RELATED_ITEM
                    ,RELATIONSHIP_TYPE
                    ,PRORATION_TYPE_CODE
                    ,ACCUM_ATTRIBUTE
                    ,GL_CLASS
                    ,LIST_PRICE_UOM
                    ,REBATE_SUBTYPE
                    ,ACCRUAL_QTY
                    ,ACCRUAL_UOM_CODE
                    ,BASE_QTY
                    ,BASE_UOM_CODE
                    ,CUSTOMER_ITEM_NUMBER
                    ,BREAK_UOM_CODE
                    ,BREAK_UOM_CONTEXT
                    ,BREAK_UOM_ATTRIBUTE
                    ,PRICING_ATTRIBUTE_CONTEXT
                    ,PRODUCT_ATTRIBUTE_CONTEXT
                    ,PRODUCT_ATTRIBUTE
                    ,PRODUCT_ATTRIBUTE_CODE
                    ,PRICING_ATTRIBUTE
                    ,PRICING_ATTRIBUTE_NAME
                    ,PRODUCT_UOM_CODE
                    ,PRODUCT_UOM_DESC
                    ,PRODUCT_ATTR_VALUE
                    ,PRODUCT_ATTR_VALUE_CODE
                    ,PRICING_ATTR_VALUE_FROM
                    ,PRICING_ATTR_VALUE_TO
                    ,COMPARISON_OPERATOR_CODE
                    ,EXCLUDER_FLAG
                    ,MODIFIERS_INDEX
                    ,VOLUME_TYPE
                    ,ACTIVE_FLAG
                    ,ACCUMULATE_FLAG
                    ,ORIG_SYS_PRICING_ATTR_REF
                    ,'New'
                 FROM XX_QP_LOAD_LINES xql
                 WHERE EXISTS (SELECT 1
                               FROM XX_QP_LOAD_HEADERS xqh
                               WHERE xqh.orig_sys_header_ref = xql.orig_sys_header_ref
                               AND   xqh.list_type_code <> 'PRL'
                               AND   xqh.batch_id = xql.batch_id
                               )
                   AND  batch_id =   p_batch_id
                  );


            fnd_file.put_line(fnd_file.log,'~No of Records inserted in Modlist Line Staging Table =>'||SQL%ROWCOUNT);
            COMMIT;
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Modlist Line Staging Table =>'||SQLERRM);
              ROLLBACK;
              retcode := 2;
       END;
       END IF;

       ---Insert into Pricelistlist line staging
       IF p_pricelist = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_PR_LIST_LINES_STG
                (  BATCH_ID
                 ,RECORD_NUMBER
                 ,SOURCE_SYSTEM_NAME
                 ,LIST_LINE_TYPE_CODE
                 ,START_DATE_ACTIVE
                 ,END_DATE_ACTIVE
                 ,AUTOMATIC_FLAG
                 ,MODIFIER_LEVEL_CODE
                 ,LIST_PRICE
                 ,PRIMARY_UOM_FLAG
                 ,SUBSTITUTION_CONTEXT
                 ,SUBSTITUTION_ATTRIBUTE
                 ,SUBSTITUTION_VALUE
                 ,ORGANIZATION_NAME
                 ,REVISION
                 ,REVISION_DATE
                 ,REVISION_REASON_CODE
                 ,PRICE_BREAK_TYPE_CODE
                 ,PERCENT_PRICE
                 ,NUMBER_EFFECTIVE_PERIODS
                 ,EFFECTIVE_PERIOD_UOM
                 ,ARITHMETIC_OPERATOR
                 ,OPERAND
                 ,OVERRIDE_FLAG
                 ,PRINT_ON_INVOICE_FLAG
                 ,REBATE_TRXN_TYPE_CODE
                 ,ESTIM_ACCRUAL_RATE
                 ,LOCK_FLAG
                 ,COMMENTS
                 ,REPRICE_FLAG
                 ,LIST_LINE_NO
                 ,ESTIM_GL_VALUE
                 ,EXPIRATION_PERIOD_START_DATE
                 ,NUMBER_EXPIRATION_PERIODS
                 ,EXPIRATION_PERIOD_UOM
                 ,EXPIRATION_DATE
                 ,ACCRUAL_FLAG
                 ,PRICING_GROUP_SEQUENCE
                 ,INCOMPATIBILITY_GRP_CODE
                 ,PRODUCT_PRECEDENCE
                 ,ACCRUAL_CONVERSION_RATE
                 ,BENEFIT_QTY
                 ,BENEFIT_UOM_CODE
                 ,BENEFIT_LIMIT
                 ,BENFT_PLL_ORIG_SYS_LINE_REF
                 ,CHARGE_TYPE_CODE
                 ,CHARGE_SUBTYPE_CODE
                 ,INCLUDE_ON_RETURNS_FLAG
                 ,QUALIFICATION_IND
                 ,CONTEXT
                 ,ATTRIBUTE1
                 ,ATTRIBUTE2
                 ,ATTRIBUTE3
                 ,ATTRIBUTE4
                 ,ATTRIBUTE5
                 ,ATTRIBUTE6
                 ,ATTRIBUTE7
                 ,ATTRIBUTE8
                 ,ATTRIBUTE9
                 ,ATTRIBUTE10
                 ,ATTRIBUTE11
                 ,ATTRIBUTE12
                 ,ATTRIBUTE13
                 ,ATTRIBUTE14
                 ,ATTRIBUTE15
                 ,RLTD_MODIFIER_GRP_NO
                 ,RLTD_MODIFIER_GRP_TYPE
                 ,PRICE_BREAK_HEADER_INDEX
                 ,PRICE_LIST_LINE_INDEX
                 ,PRICING_PHASE_NAME
                 ,RECURRING_VALUE
                 ,NET_AMOUNT_FLAG
                 ,ORIG_SYS_LINE_REF
                 ,ORIG_SYS_HEADER_REF
                 ,PRICE_BREAK_HEADER_REF
                 ,GENERATE_USING_FORMULA
                 ,PRICE_BY_FORMULA
                 ,CONTINUOUS_PRICE_BREAK_FLAG
                 ,RLTD_ORIG_SYS_HDR_REF
                 ,FROM_ORIG_SYS_HDR_REF
                 ,TO_ORIG_SYS_HDR_REF
                 ,INVENTORY_ITEM
                 ,RELATED_ITEM
                 ,RELATIONSHIP_TYPE
                 ,PRORATION_TYPE_CODE
                 ,ACCUM_ATTRIBUTE
                 ,GL_CLASS
                 ,LIST_PRICE_UOM
                 ,REBATE_SUBTYPE
                 ,ACCRUAL_QTY
                 ,ACCRUAL_UOM_CODE
                 ,BASE_QTY
                 ,BASE_UOM_CODE
                 ,CUSTOMER_ITEM_NUMBER
                 ,BREAK_UOM_CODE
                 ,BREAK_UOM_CONTEXT
                 ,BREAK_UOM_ATTRIBUTE
                 ,PRICING_ATTRIBUTE_CONTEXT
                 ,PRODUCT_ATTRIBUTE_CONTEXT
                 ,PRODUCT_ATTRIBUTE
                 ,PRODUCT_ATTRIBUTE_CODE
                 ,PRICING_ATTRIBUTE
                 ,PRICING_ATTRIBUTE_NAME
                 ,PRODUCT_UOM_CODE
                 ,PRODUCT_UOM_DESC
                 ,PRODUCT_ATTR_VALUE
                 ,PRODUCT_ATTR_VALUE_CODE
                 ,PRICING_ATTR_VALUE_FROM
                 ,PRICING_ATTR_VALUE_TO
                 ,COMPARISON_OPERATOR_CODE
                 ,EXCLUDER_FLAG
                 ,MODIFIERS_INDEX
                 ,VOLUME_TYPE
                 ,ACTIVE_FLAG
                 ,ACCUMULATE_FLAG
                 ,ORIG_SYS_PRICING_ATTR_REF
                 ,PROCESS_CODE
                 )
                 (
                 SELECT
                      BATCH_ID
                    ,RECORD_NUMBER
                    ,SOURCE_SYSTEM_NAME
                    ,LIST_LINE_TYPE_CODE
                    ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                    ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                    ,AUTOMATIC_FLAG
                    ,MODIFIER_LEVEL_CODE
                    ,LIST_PRICE
                    ,PRIMARY_UOM_FLAG
                    ,SUBSTITUTION_CONTEXT
                    ,SUBSTITUTION_ATTRIBUTE
                    ,SUBSTITUTION_VALUE
                    ,ORGANIZATION_NAME
                    ,REVISION
                    ,TO_DATE(REVISION_DATE,'MM/DD/YYYY')
                    ,REVISION_REASON_CODE
                    ,PRICE_BREAK_TYPE_CODE
                    ,PERCENT_PRICE
                    ,NUMBER_EFFECTIVE_PERIODS
                    ,EFFECTIVE_PERIOD_UOM
                    ,ARITHMETIC_OPERATOR
                    ,OPERAND
                    ,OVERRIDE_FLAG
                    ,PRINT_ON_INVOICE_FLAG
                    ,REBATE_TRXN_TYPE_CODE
                    ,ESTIM_ACCRUAL_RATE
                    ,LOCK_FLAG
                    ,COMMENTS
                    ,REPRICE_FLAG
                    ,LIST_LINE_NO
                    ,ESTIM_GL_VALUE
                    ,TO_DATE(EXPIRATION_PERIOD_START_DATE,'MM/DD/YYYY')
                    ,NUMBER_EXPIRATION_PERIODS
                    ,EXPIRATION_PERIOD_UOM
                    ,TO_DATE(EXPIRATION_DATE,'MM/DD/YYYY')
                    ,ACCRUAL_FLAG
                    ,PRICING_GROUP_SEQUENCE
                    ,INCOMPATIBILITY_GRP_CODE
                    ,PRODUCT_PRECEDENCE
                    ,ACCRUAL_CONVERSION_RATE
                    ,BENEFIT_QTY
                    ,BENEFIT_UOM_CODE
                    ,BENEFIT_LIMIT
                    ,BENFT_PLL_ORIG_SYS_LINE_REF
                    ,CHARGE_TYPE_CODE
                    ,CHARGE_SUBTYPE_CODE
                    ,INCLUDE_ON_RETURNS_FLAG
                    ,QUALIFICATION_IND
                    ,CONTEXT
                    ,ATTRIBUTE1
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,RLTD_MODIFIER_GRP_NO
                    ,RLTD_MODIFIER_GRP_TYPE
                    ,PRICE_BREAK_HEADER_INDEX
                    ,PRICE_LIST_LINE_INDEX
                    ,PRICING_PHASE_NAME
                    ,RECURRING_VALUE
                    ,NET_AMOUNT_FLAG
                    ,ORIG_SYS_LINE_REF
                    ,ORIG_SYS_HEADER_REF
                    ,PRICE_BREAK_HEADER_REF
                    ,GENERATE_USING_FORMULA
                    ,PRICE_BY_FORMULA
                    ,CONTINUOUS_PRICE_BREAK_FLAG
                    ,RLTD_ORIG_SYS_HDR_REF
                    ,FROM_ORIG_SYS_HDR_REF
                    ,TO_ORIG_SYS_HDR_REF
                    ,INVENTORY_ITEM
                    ,RELATED_ITEM
                    ,RELATIONSHIP_TYPE
                    ,PRORATION_TYPE_CODE
                    ,ACCUM_ATTRIBUTE
                    ,GL_CLASS
                    ,LIST_PRICE_UOM
                    ,REBATE_SUBTYPE
                    ,ACCRUAL_QTY
                    ,ACCRUAL_UOM_CODE
                    ,BASE_QTY
                    ,BASE_UOM_CODE
                    ,CUSTOMER_ITEM_NUMBER
                    ,BREAK_UOM_CODE
                    ,BREAK_UOM_CONTEXT
                    ,BREAK_UOM_ATTRIBUTE
                    ,PRICING_ATTRIBUTE_CONTEXT
                    ,PRODUCT_ATTRIBUTE_CONTEXT
                    ,PRODUCT_ATTRIBUTE
                    ,PRODUCT_ATTRIBUTE_CODE
                    ,PRICING_ATTRIBUTE
                    ,PRICING_ATTRIBUTE_NAME
                    ,PRODUCT_UOM_CODE
                    ,PRODUCT_UOM_DESC
                    ,PRODUCT_ATTR_VALUE
                    ,PRODUCT_ATTR_VALUE_CODE
                    ,PRICING_ATTR_VALUE_FROM
                    ,PRICING_ATTR_VALUE_TO
                    ,COMPARISON_OPERATOR_CODE
                    ,EXCLUDER_FLAG
                    ,MODIFIERS_INDEX
                    ,VOLUME_TYPE
                    ,ACTIVE_FLAG
                    ,ACCUMULATE_FLAG
                    ,ORIG_SYS_PRICING_ATTR_REF
                    ,'New'
                 FROM XX_QP_LOAD_LINES xql
                 WHERE EXISTS (SELECT 1
                               FROM XX_QP_LOAD_HEADERS xqh
                               WHERE xqh.orig_sys_header_ref = xql.orig_sys_header_ref
                               AND   xqh.list_type_code = 'PRL'
                               AND   xqh.batch_id = xql.batch_id
                               )
                  AND  batch_id =   p_batch_id
                 );

              fnd_file.put_line(fnd_file.log,'~No of Records inserted in Pricelist Line Staging Table =>'||SQL%ROWCOUNT);
              COMMIT;
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Pricelist Line Staging Table =>'||SQLERRM);
              ROLLBACK;
              retcode := 2;
       END;
       END IF;
       ---Insert into Modifierlist Qualifier staging
       IF p_modifier = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_MDPR_LIST_QLF_STG
                      ( BATCH_ID
                      ,RECORD_NUMBER
                      ,SOURCE_SYSTEM_NAME
                      ,ORIG_SYS_HEADER_REF
                      ,ORIG_SYS_LINE_REF
                      ,COMPARISON_OPERATOR_CODE
                      ,QUALIFIER_CONTEXT
                      ,QUALIFIER_ATTRIBUTE
                      ,QUALIFIER_GROUPING_NO
                      ,QUALIFIER_ATTR_VALUE
                      ,QUALIFIER_PRECEDENCE
                      ,QUALIFIER_ATTR_VALUE_TO
                      ,START_DATE_ACTIVE
                      ,END_DATE_ACTIVE
                      ,CONTEXT
                      ,PRICE_LIST_LINE_INDEX
                     -- ,PRODUCT_ATTR_VAL_DISP
                      ,ATTRIBUTE1
                      ,ATTRIBUTE10
                      ,ATTRIBUTE11
                      ,ATTRIBUTE12
                      ,ATTRIBUTE13
                      ,ATTRIBUTE14
                      ,ATTRIBUTE15
                      ,ATTRIBUTE2
                      ,ATTRIBUTE3
                      ,ATTRIBUTE4
                      ,ATTRIBUTE5
                      ,ATTRIBUTE6
                      ,ATTRIBUTE7
                      ,ATTRIBUTE8
                      ,ATTRIBUTE9
                      ,QUALIFIER_DATATYPE
                      ,LIST_TYPE_CODE
                      ,QUAL_ATTR_VALUE_FROM_NUMBER
                      ,QUAL_ATTR_VALUE_TO_NUMBER
                      ,CREATED_FROM_RULE
                    --  ,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                      ,EXCLUDER_FLAG
                      ,ORIG_SYS_QUALIFIER_REF
                      ,PROCESS_CODE
                      ,QUALIFIER_ATTR_VALUE_DISP
                   )
                (SELECT
                       BATCH_ID
                    ,RECORD_NUMBER
                    ,SOURCE_SYSTEM_NAME
                    ,ORIG_SYS_HEADER_REF
                    ,ORIG_SYS_LINE_REF
                    ,COMPARISON_OPERATOR_CODE
                    ,QUALIFIER_CONTEXT
                    ,QUALIFIER_ATTRIBUTE
                    ,QUALIFIER_GROUPING_NO
                    ,QUALIFIER_ATTR_VALUE
                    ,QUALIFIER_PRECEDENCE
                    ,QUALIFIER_ATTR_VALUE_TO
                    ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                    ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                    ,CONTEXT
                    ,PRICE_LIST_LINE_INDEX
                    --,PRODUCT_ATTR_VAL_DISP
                    ,ATTRIBUTE1
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,QUALIFIER_DATATYPE
                    ,LIST_TYPE_CODE
                    ,QUAL_ATTR_VALUE_FROM_NUMBER
                    ,QUAL_ATTR_VALUE_TO_NUMBER
                    ,CREATED_FROM_RULE
                    --,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                    ,EXCLUDER_FLAG
                    ,ORIG_SYS_QUALIFIER_REF
                    ,'New'
                    ,QUALIFIER_ATTR_VALUE_DISP
              FROM XX_QP_LOAD_QUALIFIERS xql
              WHERE EXISTS (SELECT 1
                            FROM XX_QP_LOAD_HEADERS xqh
                            WHERE xqh.orig_sys_header_ref = xql.orig_sys_header_ref
                            AND   xqh.list_type_code <> 'PRL'
                            AND   xqh.batch_id = xql.batch_id)
               AND  batch_id =   p_batch_id
                 );

              fnd_file.put_line(fnd_file.log,'~No of Records inserted in Modlist Qualifier Staging Table =>'||SQL%ROWCOUNT);
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Modlist Qualifier Staging Table =>'||SQLERRM);
              retcode := 2;
              ROLLBACK;
       END;
       END IF;
       ---Insert into Pricelist Qualifier staging
       IF p_pricelist = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_PR_LIST_QLF_STG
                      ( BATCH_ID
                      ,RECORD_NUMBER
                      ,SOURCE_SYSTEM_NAME
                      ,ORIG_SYS_HEADER_REF
                      ,ORIG_SYS_LINE_REF
                      ,COMPARISON_OPERATOR_CODE
                      ,QUALIFIER_CONTEXT
                      ,QUALIFIER_ATTRIBUTE
                      ,QUALIFIER_GROUPING_NO
                      ,QUALIFIER_ATTR_VALUE
                      ,QUALIFIER_PRECEDENCE
                      ,QUALIFIER_ATTR_VALUE_TO
                      ,START_DATE_ACTIVE
                      ,END_DATE_ACTIVE
                      ,CONTEXT
                      ,PRICE_LIST_LINE_INDEX
                      --,PRODUCT_ATTR_VAL_DISP
                      ,ATTRIBUTE1
                      ,ATTRIBUTE10
                      ,ATTRIBUTE11
                      ,ATTRIBUTE12
                      ,ATTRIBUTE13
                      ,ATTRIBUTE14
                      ,ATTRIBUTE15
                      ,ATTRIBUTE2
                      ,ATTRIBUTE3
                      ,ATTRIBUTE4
                      ,ATTRIBUTE5
                      ,ATTRIBUTE6
                      ,ATTRIBUTE7
                      ,ATTRIBUTE8
                      ,ATTRIBUTE9
                      ,QUALIFIER_DATATYPE
                      ,LIST_TYPE_CODE
                      ,QUAL_ATTR_VALUE_FROM_NUMBER
                      ,QUAL_ATTR_VALUE_TO_NUMBER
                      ,CREATED_FROM_RULE
                      ,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                      ,EXCLUDER_FLAG
                      ,ORIG_SYS_QUALIFIER_REF
                      ,PROCESS_CODE
                      ,QUALIFIER_ATTR_VALUE_DISP
                   )
                (SELECT
                       BATCH_ID
                    ,RECORD_NUMBER
                    ,SOURCE_SYSTEM_NAME
                    ,ORIG_SYS_HEADER_REF
                    ,ORIG_SYS_LINE_REF
                    ,COMPARISON_OPERATOR_CODE
                    ,QUALIFIER_CONTEXT
                    ,QUALIFIER_ATTRIBUTE
                    ,QUALIFIER_GROUPING_NO
                    ,QUALIFIER_ATTR_VALUE
                    ,QUALIFIER_PRECEDENCE
                    ,QUALIFIER_ATTR_VALUE_TO
                    ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                    ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                    ,CONTEXT
                    ,PRICE_LIST_LINE_INDEX
                   -- ,PRODUCT_ATTR_VAL_DISP
                    ,ATTRIBUTE1
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,QUALIFIER_DATATYPE
                    ,LIST_TYPE_CODE
                    ,QUAL_ATTR_VALUE_FROM_NUMBER
                    ,QUAL_ATTR_VALUE_TO_NUMBER
                    ,CREATED_FROM_RULE
                    ,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                    ,EXCLUDER_FLAG
                    ,ORIG_SYS_QUALIFIER_REF
                    ,'New'
                    ,QUALIFIER_ATTR_VALUE_DISP
              FROM XX_QP_LOAD_QUALIFIERS xql
              WHERE EXISTS (SELECT 1
                            FROM XX_QP_LOAD_HEADERS xqh
                            WHERE xqh.orig_sys_header_ref = xql.orig_sys_header_ref
                            AND   xqh.list_type_code = 'PRL'
                            AND   xqh.batch_id = xql.batch_id)
               AND  batch_id =   p_batch_id
               AND QUALIFIER_CONTEXT <> 'MODLIST'
               ) ;

              fnd_file.put_line(fnd_file.log,'~No of Records inserted in Pricelist Qualifier Staging Table =>'||SQL%ROWCOUNT);
            COMMIT;
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Pricelist Qualifier Staging Table =>'||SQLERRM);
           ROLLBACK;
          retcode := 2;
       END;
       END IF;
      ---Insert into Pricelist Qualifier staging
       IF p_pricelist = x_yes_no_yes THEN
       BEGIN
          INSERT INTO XX_QP_PR_LIST_QLF_STG
                      ( BATCH_ID
                      ,RECORD_NUMBER
                      ,SOURCE_SYSTEM_NAME
                      ,ORIG_SYS_HEADER_REF
                      ,ORIG_SYS_LINE_REF
                      ,COMPARISON_OPERATOR_CODE
                      ,QUALIFIER_CONTEXT
                      ,QUALIFIER_ATTRIBUTE
                      ,QUALIFIER_GROUPING_NO
                      ,QUALIFIER_ATTR_VALUE
                      ,QUALIFIER_PRECEDENCE
                      ,QUALIFIER_ATTR_VALUE_TO
                      ,START_DATE_ACTIVE
                      ,END_DATE_ACTIVE
                      ,CONTEXT
                      ,PRICE_LIST_LINE_INDEX
                      --,PRODUCT_ATTR_VAL_DISP
                      ,ATTRIBUTE1
                      ,ATTRIBUTE10
                      ,ATTRIBUTE11
                      ,ATTRIBUTE12
                      ,ATTRIBUTE13
                      ,ATTRIBUTE14
                      ,ATTRIBUTE15
                      ,ATTRIBUTE2
                      ,ATTRIBUTE3
                      ,ATTRIBUTE4
                      ,ATTRIBUTE5
                      ,ATTRIBUTE6
                      ,ATTRIBUTE7
                      ,ATTRIBUTE8
                      ,ATTRIBUTE9
                      ,QUALIFIER_DATATYPE
                      ,LIST_TYPE_CODE
                      ,QUAL_ATTR_VALUE_FROM_NUMBER
                      ,QUAL_ATTR_VALUE_TO_NUMBER
                      ,CREATED_FROM_RULE
                      ,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                      ,EXCLUDER_FLAG
                      ,ORIG_SYS_QUALIFIER_REF
                      ,PROCESS_CODE
                      ,QUALIFIER_ATTR_VALUE_DISP
                   )
                (SELECT
                       BATCH_ID
                    ,RECORD_NUMBER
                    ,SOURCE_SYSTEM_NAME
                    ,QUALIFIER_ATTR_VALUE_DISP--ORIG_SYS_HEADER_REF
                    ,ORIG_SYS_LINE_REF
                    ,COMPARISON_OPERATOR_CODE
                    ,QUALIFIER_CONTEXT
                    ,QUALIFIER_ATTRIBUTE
                    ,QUALIFIER_GROUPING_NO
                    ,QUALIFIER_ATTR_VALUE
                    ,QUALIFIER_PRECEDENCE
                    ,QUALIFIER_ATTR_VALUE_TO
                    ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                    ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                    ,CONTEXT
                    ,PRICE_LIST_LINE_INDEX
                   -- ,PRODUCT_ATTR_VAL_DISP
                    ,ATTRIBUTE1
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,QUALIFIER_DATATYPE
                    ,LIST_TYPE_CODE
                    ,QUAL_ATTR_VALUE_FROM_NUMBER
                    ,QUAL_ATTR_VALUE_TO_NUMBER
                    ,CREATED_FROM_RULE
                    ,SEC_PRC_LIST_ORIG_SYS_HDR_REF
                    ,EXCLUDER_FLAG
                    ,ORIG_SYS_QUALIFIER_REF
                    ,'New'
                    ,ORIG_SYS_HEADER_REF --QUALIFIER_ATTR_VALUE_DISP
              FROM XX_QP_LOAD_QUALIFIERS xql
              WHERE EXISTS (SELECT 1
                            FROM XX_QP_LOAD_HEADERS xqh
                            WHERE xqh.orig_sys_header_ref = xql.QUALIFIER_ATTR_VALUE_DISP
                            AND   xqh.list_type_code = 'PRL'
                            AND   xqh.batch_id = xql.batch_id)
               AND  EXISTS (SELECT 1
                            FROM XX_QP_LOAD_HEADERS xqh
                            WHERE xqh.orig_sys_header_ref = xql.orig_sys_header_ref
                            AND   xqh.list_type_code = 'PRL'
                            AND   xqh.batch_id = xql.batch_id)
               AND  batch_id =   p_batch_id
               AND QUALIFIER_CONTEXT = 'MODLIST'
               AND QUALIFIER_ATTRIBUTE ='QUALIFIER_ATTRIBUTE4'
               ) ;

              fnd_file.put_line(fnd_file.log,'~No of Records inserted in Pricelist Qualifier Staging Table for Sec Prc List=>'||SQL%ROWCOUNT);
            COMMIT;
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Pricelist Qualifier Staging Table for Sec Prc List=>'||SQLERRM);
           ROLLBACK;
          retcode := 2;
       END;
       END IF;
       ---Insert into Qualifier Rule staging
       IF p_qualgroups = x_yes_no_yes THEN
       BEGIN
       INSERT INTO XX_QP_RULES_QLF_STG
             (BATCH_ID
             ,RECORD_NUMBER
             ,SOURCE_SYSTEM_NAME
             ,QUALIFIER_NAME
             ,DESCRIPTION
             ,QUALIFY_HIER_DESCENDENTS_FLAG
             ,QUALIFIER_GROUPING_NO
             ,QUALIFIER_CONTEXT
             ,QUALIFIER_ATTRIBUTE
             ,QUALIFIER_ATTR_VALUE
             ,COMPARISON_OPERATOR_CODE
             ,EXCLUDER_FLAG
             ,QUALIFIER_RULE_ID
             ,START_DATE_ACTIVE
             ,END_DATE_ACTIVE
             ,CREATED_FROM_RULE_ID
             ,QUALIFIER_PRECEDENCE
             ,LIST_HEADER_ID
             ,LIST_LINE_ID
             ,QUALIFIER_DATATYPE
             ,QUALIFIER_ATTR_VALUE_TO
             ,CONTEXT
             ,ATTRIBUTE1
             ,ATTRIBUTE2
             ,ATTRIBUTE3
             ,ATTRIBUTE4
             ,ATTRIBUTE5
             ,ATTRIBUTE6
             ,ATTRIBUTE7
             ,ATTRIBUTE8
             ,ATTRIBUTE9
             ,ATTRIBUTE10
             ,ATTRIBUTE11
             ,ATTRIBUTE12
             ,ATTRIBUTE13
             ,ATTRIBUTE14
             ,ATTRIBUTE15
             ,ORIG_SYS_QUALIFIER_REF
             ,ORIG_SYS_HEADER_REF
             ,ORIG_SYS_LINE_REF
             ,OTHERS_GROUP_CNT
             ,QUALIFIER_ID
             ,SEARCH_IND
             ,QUALIFIER_GROUP_CNT
             ,HEADER_QUALS_EXIST_FLAG
             ,DISTINCT_ROW_COUNT
             ,SEGMENT_ID
             ,ACTIVE_FLAG
             ,LIST_TYPE_CODE
             ,QUAL_ATTR_VALUE_FROM_NUMBER
             ,QUAL_ATTR_VALUE_TO_NUMBER
             ,ORIG_SYS_QUALIFIER_RULE_REF
             ,PROCESS_CODE
             ,QUALIFIER_ATTR_VALUE_DISP
             )
        (SELECT
                 BATCH_ID
                ,RECORD_NUMBER
                ,SOURCE_SYSTEM_NAME
                ,QUALIFIER_NAME
                ,DESCRIPTION
                ,QUALIFY_HIER_DESCENDENTS_FLAG
                ,QUALIFIER_GROUPING_NO
                ,QUALIFIER_CONTEXT
                ,QUALIFIER_ATTRIBUTE
                ,QUALIFIER_ATTR_VALUE
                ,COMPARISON_OPERATOR_CODE
                ,EXCLUDER_FLAG
                ,QUALIFIER_RULE_ID
                ,TO_DATE(START_DATE_ACTIVE,'MM/DD/YYYY')
                ,TO_DATE(END_DATE_ACTIVE,'MM/DD/YYYY')
                ,CREATED_FROM_RULE_ID
                ,QUALIFIER_PRECEDENCE
                ,LIST_HEADER_ID
                ,LIST_LINE_ID
                ,QUALIFIER_DATATYPE
                ,QUALIFIER_ATTR_VALUE_TO
                ,CONTEXT
                ,ATTRIBUTE1
                ,ATTRIBUTE2
                ,ATTRIBUTE3
                ,ATTRIBUTE4
                ,ATTRIBUTE5
                ,ATTRIBUTE6
                ,ATTRIBUTE7
                ,ATTRIBUTE8
                ,ATTRIBUTE9
                ,ATTRIBUTE10
                ,ATTRIBUTE11
                ,ATTRIBUTE12
                ,ATTRIBUTE13
                ,ATTRIBUTE14
                ,ATTRIBUTE15
                ,ORIG_SYS_QUALIFIER_REF
                ,ORIG_SYS_HEADER_REF
                ,ORIG_SYS_LINE_REF
                ,OTHERS_GROUP_CNT
                ,QUALIFIER_ID
                ,SEARCH_IND
                ,QUALIFIER_GROUP_CNT
                ,HEADER_QUALS_EXIST_FLAG
                ,DISTINCT_ROW_COUNT
                ,SEGMENT_ID
                ,ACTIVE_FLAG
                ,LIST_TYPE_CODE
                ,QUAL_ATTR_VALUE_FROM_NUMBER
                ,QUAL_ATTR_VALUE_TO_NUMBER
                ,QUALIFIER_RULE_ID --ORIG_SYS_QUALIFIER_RULE_REF
                ,'New'
                ,QUALIFIER_ATTR_VALUE_DISP
           FROM XX_QP_LOAD_QLF_RULES
          WHERE batch_id =   p_batch_id

                )  ;

              fnd_file.put_line(fnd_file.log,'~No of Records inserted in Qualifier Rules Staging Table =>'||SQL%ROWCOUNT);
              COMMIT;
       EXCEPTION
           WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Exception while inserting in Qualifier Rules Staging Table =>'||SQLERRM);
           ROLLBACK;
          retcode := 2;
       END;
       END IF;





    EXCEPTION
       WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Exception while executing xx_qp_gen_ins_cnv_pkg.main' );
          ROLLBACK;
          retcode := 2;
    END main;

END xx_qp_gen_ins_cnv_pkg;
/
