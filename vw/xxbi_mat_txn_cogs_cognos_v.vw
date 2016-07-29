DROP VIEW APPS.XXBI_MAT_TXN_COGS_COGNOS_V;

/* Formatted on 6/6/2016 5:00:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXBI_MAT_TXN_COGS_COGNOS_V
(
   GL_ACCOUNT,
   COMPANY,
   DEPT,
   ACCOUNT,
   ORG_CODE,
   ORDERTYPE,
   TRANSACTIONTYPE,
   SUBINV,
   TXN_DATE,
   SOURCE,
   LINE_NUMBER,
   SHIPMENT_NUMBER,
   ITEM,
   DESCRIPTION,
   CURRENCYCODE,
   PRIMARY_UOM,
   QUANTITY,
   COST,
   STANDARDCOGS,
   TRANS_CREATION_DT
)
AS
   SELECT    gcc.segment1
          || '-'
          || gcc.segment2
          || '-'
          || gcc.segment3
          || '-'
          || gcc.segment4
          || '-'
          || gcc.segment5
          || '-'
          || gcc.segment6
          || '-'
          || gcc.segment7
          || '-'
          || gcc.segment8
             gl_account,
          gcc.segment1 company,
          gcc.segment2 dept,
          gcc.segment3 ACCOUNT,
          ood.organization_code org_code,
          (SELECT transaction_source_type_name
             FROM mtl_txn_source_types mtst
            WHERE mtst.transaction_source_type_id =
                     mta.transaction_source_type_id)
             ordertype,
          (SELECT transaction_type_name
             FROM mtl_transaction_types mtt
            WHERE mtt.transaction_type_id = mmt.transaction_type_id)
             transactiontype,
          DECODE (
             mmt.transaction_action_id,
             3, DECODE (mmt.organization_id,
                        mta.organization_id, mmt.subinventory_code,
                        mmt.transfer_subinventory),
             2, DECODE (SIGN (mta.primary_quantity),
                        -1, mmt.subinventory_code,
                        1, mmt.transfer_subinventory,
                        mmt.subinventory_code),
             28, DECODE (SIGN (mta.primary_quantity),
                         -1, mmt.subinventory_code,
                         1, mmt.transfer_subinventory,
                         mmt.subinventory_code),
             5, mmt.subinventory_code,
             mmt.subinventory_code)
             subinv,
          mta.transaction_date txn_date,
          DECODE (
             mta.transaction_source_type_id,
             1, TO_CHAR (mmt.transaction_source_id),
             4, TO_CHAR (mmt.transaction_source_id),
             5, TO_CHAR (mmt.transaction_source_id),
             7, TO_CHAR (mmt.transaction_source_id),
             9, TO_CHAR (mmt.transaction_source_id),
             10, TO_CHAR (mmt.transaction_source_id),
             11, TO_CHAR (mmt.transaction_source_id),
             NVL (mmt.transaction_source_name,
                  TO_CHAR (mmt.transaction_source_id)))
             SOURCE,
          NULL line_number,
          mmt.shipment_number,
          msi.segment1 item,
          msi.description description,
          gsob.currency_code currencycode,
          msi.primary_uom_code primary_uom,
          DECODE (mta.transaction_source_type_id,
                  11, mmt.quantity_adjusted,
                  mta.primary_quantity)
             quantity,
          DECODE (
             mmt.transaction_action_id,
             30, ABS (
                    NVL (
                       mta.rate_or_amount,
                         mta.base_transaction_value
                       / DECODE (mta.primary_quantity,
                                 0, 1,
                                 NULL, 1,
                                 mta.primary_quantity))),
             (  ABS (
                   NVL (
                      mta.rate_or_amount,
                        mta.base_transaction_value
                      / DECODE (mta.primary_quantity,
                                0, 1,
                                NULL, 1,
                                mta.primary_quantity)))
              * SIGN (mta.base_transaction_value)
              * SIGN (mta.primary_quantity)))
             COST,
          NVL (mta.base_transaction_value, 0) standardcogs,
          mmt.creation_date trans_creation_dt
     FROM mtl_system_items msi,
          mtl_material_transactions mmt,
          gl_code_combinations gcc,
          mtl_transaction_accounts mta,
          gl_sets_of_books gsob,
          org_organization_definitions ood
    WHERE     mta.transaction_id = mmt.transaction_id
          AND mta.inventory_item_id = msi.inventory_item_id
          AND mta.reference_account = gcc.code_combination_id
          AND gsob.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.organization_id = msi.organization_id
          AND ood.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND mta.organization_id = msi.organization_id
          /*AND ood.organization_code IN (SELECT organization_code
          FROM org_organization_definitions)*/
          AND mta.transaction_source_type_id NOT IN (2,
                                                     3,
                                                     6,
                                                     8,
                                                     12)
          -- AND mta.transaction_date BETWEEN to_date(p_start_date,'DD-MON-YYYY') AND to_date(p_end_date,'DD-MON-YYYY')
          --  AND mta.transaction_date BETWEEN to_date(ld_begin_date,'YYYY/MM/DD HH24:MI:SS') AND to_date(ld_end_date,'YYYY/MM/DD HH24:MI:SS')
          --and trunc (mta.transaction_date) between '06-APR-2011' and '11-APR-2011'
          AND mta.accounting_line_type <> 15
          AND SUBSTR (gcc.segment3, 1, 1) = '4'
   UNION ALL
   SELECT    gcc.segment1
          || '-'
          || gcc.segment2
          || '-'
          || gcc.segment3
          || '-'
          || gcc.segment4
          || '-'
          || gcc.segment5
          || '-'
          || gcc.segment6
          || '-'
          || gcc.segment7
          || '-'
          || gcc.segment8
             gl_account,
          gcc.segment1 company,
          gcc.segment2 dept,
          gcc.segment3 ACCOUNT,
          ood.organization_code org_code,
          (SELECT transaction_source_type_name
             FROM mtl_txn_source_types mtst
            WHERE mtst.transaction_source_type_id =
                     mta.transaction_source_type_id)
             ordertype,
          (SELECT transaction_type_name
             FROM mtl_transaction_types mtt
            WHERE mtt.transaction_type_id = mmt.transaction_type_id)
             transactiontype,
          DECODE (
             mmt.transaction_action_id,
             3, DECODE (mmt.organization_id,
                        mta.organization_id, mmt.subinventory_code,
                        mmt.transfer_subinventory),
             2, DECODE (SIGN (mta.primary_quantity),
                        -1, mmt.subinventory_code,
                        1, mmt.transfer_subinventory,
                        mmt.subinventory_code),
             28, DECODE (SIGN (mta.primary_quantity),
                         -1, mmt.subinventory_code,
                         1, mmt.transfer_subinventory,
                         mmt.subinventory_code),
             5, mmt.subinventory_code,
             mmt.subinventory_code)
             subinv,
          mta.transaction_date txn_date,
          mkts.segment1 SOURCE,
          ool.line_number,
          mmt.shipment_number,
          msi.segment1 item,
          msi.description description,
          gsob.currency_code currencycode,
          msi.primary_uom_code primary_uom,
          DECODE (MTA.TRANSACTION_SOURCE_TYPE_ID,
                  11, MMT.QUANTITY_ADJUSTED,
                  MTA.PRIMARY_QUANTITY)
             QUANTITY,
          -- DECODE (mmt.transaction_action_id, 30, ABS (NVL (mta.rate_or_amount, mta.base_transaction_value / DECODE (mta.primary_quantity, 0, 1, NULL, 1, mta.primary_quantity ) ) ), ( ABS (NVL (mta.rate_or_amount, mta.base_transaction_value / DECODE (mta.primary_quantity, 0, 1, NULL, 1, mta.primary_quantity ) ) ) * SIGN (mta.base_transaction_value) * SIGN (mta.primary_quantity) ) ) COST,
          XDL.UNROUNDED_ACCOUNTED_DR / MTA.PRIMARY_QUANTITY cost,
          --NVL (mta.base_transaction_value, 0) standardcogs,
          NVL (XDL.UNROUNDED_ACCOUNTED_DR, 0) standardcogs,
          mmt.creation_date trans_creation_dt
     FROM mtl_system_items msi,
          mtl_material_transactions mmt,
          gl_code_combinations gcc,
          mtl_sales_orders mkts,
          mtl_transaction_accounts mta,
          gl_sets_of_books gsob,
          org_organization_definitions ood,
          OE_ORDER_LINES_ALL OOL,
          XLA_TRANSACTION_ENTITIES_UPG XTEU,
          XLA_AE_HEADERS XAH,
          xla_ae_lines xal,
          xla_distribution_links xdl
    WHERE     mta.transaction_id = mmt.transaction_id
          AND mta.inventory_item_id = msi.inventory_item_id
          --AND mta.reference_account = gcc.code_combination_id
          AND gsob.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.organization_id = msi.organization_id
          AND ood.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND mta.organization_id = msi.organization_id
          AND mmt.trx_source_line_id = ool.line_id
          /*aND ood.organization_code IN (SELECT organization_code
          FROM org_organization_definitions)*/
          AND mta.transaction_source_id = mkts.sales_order_id
          AND mta.transaction_source_type_id IN (2, 8, 12)
          AND mta.accounting_line_type <> 15
          -- AND mta.transaction_date BETWEEN to_date(p_start_date,'DD-MON-YYYY') AND to_date(p_end_date,'DD-MON-YYYY')
          -- AND mta.transaction_date BETWEEN to_date(ld_begin_date,'YYYY/MM/DD HH24:MI:SS') AND to_date(ld_end_date,'YYYY/MM/DD HH24:MI:SS')
          -- and trunc (mta.transaction_date) between '06-APR-2011' and '11-APR-2011'
          AND SUBSTR (gcc.segment3, 1, 1) = '4'
          AND MMT.TRANSACTION_ID = XTEU.SOURCE_ID_INT_1
          AND ENTITY_CODE = 'MTL_ACCOUNTING_EVENTS'
          AND XAH.ENTITY_ID = XTEU.ENTITY_ID
          AND xteu.application_id = xah.application_id
          AND xal.application_id = xah.application_id
          AND XAL.AE_HEADER_ID = XAH.AE_HEADER_ID
          AND XTEU.APPLICATION_ID = 707
          AND ACCOUNTING_CLASS_CODE = 'COST_OF_GOODS_SOLD'
          AND GL_SL_LINK_TABLE = 'XLAJEL'
          AND xal.code_combination_id = gcc.code_combination_id
          AND xdl.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
          AND xdl.source_distribution_id_num_1 = mta.inv_sub_ledger_id
          AND xal.ae_header_id = xdl.ae_header_id
          AND XAL.AE_LINE_NUM = XDL.AE_LINE_NUM
          AND XAL.APPLICATION_ID = XDL.APPLICATION_ID
          AND xdl.event_id = XAH.event_id
          AND mta.transaction_date BETWEEN '1-May-2014' AND TRUNC (SYSDATE)
   UNION ALL
   SELECT    gcc.segment1
          || '-'
          || gcc.segment2
          || '-'
          || gcc.segment3
          || '-'
          || gcc.segment4
          || '-'
          || gcc.segment5
          || '-'
          || gcc.segment6
          || '-'
          || gcc.segment7
          || '-'
          || gcc.segment8
             gl_account,
          gcc.segment1 company,
          gcc.segment2 dept,
          gcc.segment3 ACCOUNT,
          ood.organization_code org_code,
          (SELECT transaction_source_type_name
             FROM mtl_txn_source_types mtst
            WHERE mtst.transaction_source_type_id =
                     mta.transaction_source_type_id)
             ordertype,
          (SELECT transaction_type_name
             FROM mtl_transaction_types mtt
            WHERE mtt.transaction_type_id = mmt.transaction_type_id)
             transactiontype,
          DECODE (
             mmt.transaction_action_id,
             3, DECODE (mmt.organization_id,
                        mta.organization_id, mmt.subinventory_code,
                        mmt.transfer_subinventory),
             2, DECODE (SIGN (mta.primary_quantity),
                        -1, mmt.subinventory_code,
                        1, mmt.transfer_subinventory,
                        mmt.subinventory_code),
             28, DECODE (SIGN (mta.primary_quantity),
                         -1, mmt.subinventory_code,
                         1, mmt.transfer_subinventory,
                         mmt.subinventory_code),
             5, mmt.subinventory_code,
             mmt.subinventory_code)
             subinv,
          mta.transaction_date txn_date,
          mdsp.segment1 SOURCE,
          NULL line_number,
          mmt.shipment_number,
          msi.segment1 item,
          msi.description description,
          gsob.currency_code currencycode,
          msi.primary_uom_code primary_uom,
          DECODE (mta.transaction_source_type_id,
                  11, mmt.quantity_adjusted,
                  mta.primary_quantity)
             quantity,
          DECODE (
             mmt.transaction_action_id,
             30, ABS (
                    NVL (
                       mta.rate_or_amount,
                         mta.base_transaction_value
                       / DECODE (mta.primary_quantity,
                                 0, 1,
                                 NULL, 1,
                                 mta.primary_quantity))),
             (  ABS (
                   NVL (
                      mta.rate_or_amount,
                        mta.base_transaction_value
                      / DECODE (mta.primary_quantity,
                                0, 1,
                                NULL, 1,
                                mta.primary_quantity)))
              * SIGN (mta.base_transaction_value)
              * SIGN (mta.primary_quantity)))
             COST,
          NVL (mta.base_transaction_value, 0) standardcogs,
          mmt.creation_date trans_creation_dt
     FROM mtl_system_items msi,
          mtl_material_transactions mmt,
          gl_code_combinations gcc,
          mtl_generic_dispositions mdsp,
          mtl_transaction_accounts mta,
          gl_sets_of_books gsob,
          org_organization_definitions ood
    WHERE     mta.transaction_id = mmt.transaction_id
          AND mta.inventory_item_id = msi.inventory_item_id
          AND mta.reference_account = gcc.code_combination_id
          AND gsob.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.organization_id = msi.organization_id
          AND ood.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND mta.organization_id = msi.organization_id
          /*  AND ood.organization_code IN (SELECT organization_code
          FROM org_organization_definitions)*/
          AND mta.transaction_source_id = mdsp.disposition_id
          AND mta.transaction_source_type_id = 6
          AND mta.accounting_line_type <> 15
          --  AND mta.transaction_date BETWEEN to_date(p_start_date,'DD-MON-YYYY') AND to_date(p_end_date,'DD-MON-YYYY')
          --AND mta.transaction_date BETWEEN to_date(ld_begin_date,'YYYY/MM/DD HH24:MI:SS') AND to_date(ld_end_date,'YYYY/MM/DD HH24:MI:SS')
          --and trunc (mta.transaction_date) between '06-APR-2011' and '11-APR-2011'
          AND SUBSTR (gcc.segment3, 1, 1) = '4'
   UNION ALL
   SELECT    gcc.segment1
          || '-'
          || gcc.segment2
          || '-'
          || gcc.segment3
          || '-'
          || gcc.segment4
          || '-'
          || gcc.segment5
          || '-'
          || gcc.segment6
          || '-'
          || gcc.segment7
          || '-'
          || gcc.segment8
             gl_account,
          gcc.segment1 company,
          gcc.segment2 dept,
          gcc.segment3 ACCOUNT,
          ood.organization_code org_code,
          (SELECT transaction_source_type_name
             FROM mtl_txn_source_types mtst
            WHERE mtst.transaction_source_type_id =
                     mta.transaction_source_type_id)
             ordertype,
          (SELECT transaction_type_name
             FROM mtl_transaction_types mtt
            WHERE mtt.transaction_type_id = mmt.transaction_type_id)
             transactiontype,
          DECODE (
             mmt.transaction_action_id,
             3, DECODE (mmt.organization_id,
                        mta.organization_id, mmt.subinventory_code,
                        mmt.transfer_subinventory),
             2, DECODE (SIGN (mta.primary_quantity),
                        -1, mmt.subinventory_code,
                        1, mmt.transfer_subinventory,
                        mmt.subinventory_code),
             28, DECODE (SIGN (mta.primary_quantity),
                         -1, mmt.subinventory_code,
                         1, mmt.transfer_subinventory,
                         mmt.subinventory_code),
             5, mmt.subinventory_code,
             mmt.subinventory_code)
             subinv,
          mta.transaction_date txn_date,
          NULL SOURCE,
          NULL line_number,
          mmt.shipment_number,
          msi.segment1 item,
          msi.description description,
          gsob.currency_code currencycode,
          msi.primary_uom_code primary_uom,
          DECODE (mta.transaction_source_type_id,
                  11, mmt.quantity_adjusted,
                  mta.primary_quantity)
             quantity,
          DECODE (
             mmt.transaction_action_id,
             30, ABS (
                    NVL (
                       mta.rate_or_amount,
                         mta.base_transaction_value
                       / DECODE (mta.primary_quantity,
                                 0, 1,
                                 NULL, 1,
                                 mta.primary_quantity))),
             (  ABS (
                   NVL (
                      mta.rate_or_amount,
                        mta.base_transaction_value
                      / DECODE (mta.primary_quantity,
                                0, 1,
                                NULL, 1,
                                mta.primary_quantity)))
              * SIGN (mta.base_transaction_value)
              * SIGN (mta.primary_quantity)))
             COST,
          NVL (mta.base_transaction_value, 0) standardcogs,
          mmt.creation_date trans_creation_dt
     FROM mtl_system_items msi,
          mtl_material_transactions mmt,
          gl_code_combinations gcc,
          gl_code_combinations gl,
          mtl_transaction_accounts mta,
          gl_sets_of_books gsob,
          org_organization_definitions ood
    WHERE     mta.transaction_id = mmt.transaction_id
          AND mta.inventory_item_id = msi.inventory_item_id
          AND mta.reference_account = gcc.code_combination_id
          AND gsob.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.organization_id = msi.organization_id
          AND ood.chart_of_accounts_id = gcc.chart_of_accounts_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND mta.organization_id = msi.organization_id
          AND mta.transaction_source_id = gl.code_combination_id
          AND mta.transaction_source_type_id = 3
          /*AND ood.organization_code IN (SELECT organization_code
          FROM org_organization_definitions)*/
          AND mta.accounting_line_type <> 15
          --AND mta.transaction_date BETWEEN to_date(p_start_date,'DD-MON-YYYY') AND to_date(p_end_date,'DD-MON-YYYY')
          -- AND mta.transaction_date BETWEEN to_date(ld_begin_date,'YYYY/MM/DD HH24:MI:SS') AND to_date(ld_end_date,'YYYY/MM/DD HH24:MI:SS')
          --  and trunc (mta.transaction_date) between '06-APR-2011' and '11-APR-2011'
          AND SUBSTR (gcc.segment3, 1, 1) = '4'
   ORDER BY txn_date, item;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXBI_MAT_TXN_COGS_COGNOS_V FOR APPS.XXBI_MAT_TXN_COGS_COGNOS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXBI_MAT_TXN_COGS_COGNOS_V FOR APPS.XXBI_MAT_TXN_COGS_COGNOS_V;


CREATE OR REPLACE SYNONYM XXBI.XXBI_MAT_TXN_COGS_COGNOS_V FOR APPS.XXBI_MAT_TXN_COGS_COGNOS_V;


CREATE OR REPLACE SYNONYM XXINTG.XXBI_MAT_TXN_COGS_COGNOS_V FOR APPS.XXBI_MAT_TXN_COGS_COGNOS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXBI_MAT_TXN_COGS_COGNOS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXBI_MAT_TXN_COGS_COGNOS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXBI_MAT_TXN_COGS_COGNOS_V TO XXINTG;
