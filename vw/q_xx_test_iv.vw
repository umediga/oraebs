DROP VIEW APPS.Q_XX_TEST_IV;

/* Formatted on 6/6/2016 5:00:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.Q_XX_TEST_IV
(
   TRANSACTION_INTERFACE_ID,
   QA_LAST_UPDATED_BY_NAME,
   QA_CREATED_BY_NAME,
   COLLECTION_ID,
   SOURCE_CODE,
   SOURCE_LINE_ID,
   PROCESS_STATUS,
   ORGANIZATION_CODE,
   OPERATING_UNIT_ID,
   OPERATING_UNIT,
   PLAN_NAME,
   INSERT_TYPE,
   MATCHING_ELEMENTS,
   SPEC_NAME,
   ITEM,
   ITEM_DESC
)
AS
   SELECT transaction_interface_id,
          qa_last_updated_by_name,
          qa_created_by_name,
          collection_id,
          source_code,
          source_line_id,
          process_status,
          organization_code,
          operating_unit_id,
          operating_unit,
          plan_name,
          insert_type,
          matching_elements,
          spec_name,
          ITEM,
          CHARACTER1 "ITEM_DESC"
     FROM QA_RESULTS_INTERFACE;
