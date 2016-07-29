DROP VIEW APPS.XX_CST_XLA_INV_LINES_V;

/* Formatted on 6/6/2016 4:58:44 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CST_XLA_INV_LINES_V
(
   EVENT_ID,
   LINE_NUMBER,
   CODE_COMBINATION_ID,
   ENTERED_AMOUNT,
   ACCOUNTING_LINE_TYPE_CODE,
   ACCOUNTED_AMOUNT,
   RATE_OR_AMOUNT,
   INV_TXN_BASIS_TYPE,
   CURRENCY_CODE,
   CURRENCY_CONVERSION_DATE,
   CURRENCY_CONVERSION_RATE,
   CURRENCY_CONVERSION_TYPE,
   MATERIAL_OVERHEAD_ID,
   COST_ELEMENT_ID,
   SUBINVENTORY_CODE,
   TRANSFER_SUBINVENTORY,
   LOCATOR_ID,
   TRANSFER_LOCATOR_ID,
   COST_GROUP_ID,
   TRANSFER_COST_GROUP_ID,
   TO_PROJECT_ID,
   PROJECT_ID,
   TO_TASK_ID,
   TASK_ID,
   LEDGER_ID,
   L_ORGANIZATION_ID,
   DISTRIBUTION_IDENTIFIER,
   TRANSACTION_ID,
   L_ORGANIZATION_CODE
)
AS
   SELECT cxihv.event_id,
          /* EVENT IDENTIFIER */
          ROW_NUMBER ()
             OVER (PARTITION BY cxihv.event_id ORDER BY cxihv.event_id)
             AS line_number,
          /* LINE NUMBER */
          mta.reference_account code_combination_id,
          /* REFERENCE_ACCOUNT */
          -- nvl(mta.transaction_value, mta.base_transaction_value) entered_amount
          intg_ic_pricing_pkg.get_entered_amount (
             mmt.transaction_id,
             mmt.inventory_item_Id,
             mmt.organization_id,
             mta.accounting_line_type,
             mta.transaction_value,
             mmt.transaction_type_Id,
             mta.primary_quantity,
             mta.base_transaction_value,
             NVL (
                mmt.currency_code,
                intg_ic_pricing_pkg.get_functional_currency (
                   mmt.organization_id)),
             NVL (mmt.currency_conversion_rate, 1))
             entered_amount,
          /* ENTERED_AMOUNT */
          mta.accounting_line_type accounting_line_type_code,
          /* ACCOUNTING_LINE_TYPE_CODE */
          --mta.base_transaction_value accounted_amount
          intg_ic_pricing_pkg.get_functional_amount (
             mmt.transaction_id,
             mmt.inventory_item_Id,
             mmt.organization_id,
             mta.accounting_line_type,
             mmt.transaction_type_Id,
             mta.primary_quantity,
             mta.base_transaction_value)
             accounted_amount,
          /* ACCOUNTED_AMOUNT */
          mta.rate_or_amount,
          /* RATE_OR_AMOUNT */
          mta.basis_type inv_txn_basis_type,
          /* BASIS_TYPE */
          NVL (mta.currency_code, gl.currency_code) currency_code,
          DECODE (
             mta.currency_code,
             NULL, NVL (mta.currency_conversion_date,
                        mmt.currency_conversion_date),
             gl.currency_code, mta.currency_conversion_date,
             NVL (mta.currency_conversion_date,
                  NVL (mmt.currency_conversion_date, cxihv.transaction_date)))
             currency_conversion_date,
          DECODE (mta.currency_code,
                  NULL, TO_NUMBER (NULL),
                  gl.currency_code, TO_NUMBER (NULL),
                  mta.currency_conversion_rate)
             currency_conversion_rate,
          DECODE (mta.currency_code,
                  NULL, NULL,
                  gl.currency_code, NULL,
                  mta.currency_conversion_type)
             currency_conversion_type,
          mta.resource_id material_overhead_id,
          /* MATERIAL_OVERHEAD_ID */
          mta.cost_element_id,
          /* COST_ELEMENT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                   cxihv.h_transfer_subinventory),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                   cxihv.h_transfer_subinventory),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                    cxihv.h_transfer_subinventory),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                    cxihv.h_transfer_subinventory),
             h_subinventory_code)
             subinventory_code,
          /* SUBINVENTORY_CODE */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                   cxihv.h_subinventory_code),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                   cxihv.h_subinventory_code),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                    cxihv.h_subinventory_code),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                    cxihv.h_subinventory_code),
             h_transfer_subinventory)
             transfer_subinventory,
          /* TRANSFER_SUBINVENTORY */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                        cxihv.h_transfer_locator_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                        cxihv.h_transfer_locator_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                         cxihv.h_transfer_locator_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                         cxihv.h_transfer_locator_id),
             h_locator_id)
             locator_id,
          /* LOCATOR_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                   cxihv.h_locator_id),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                   cxihv.h_locator_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                    cxihv.h_locator_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                    cxihv.h_locator_id),
             h_transfer_locator_id)
             transfer_locator_id,
          /* TRANSFER_LOCATOR_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                        cxihv.h_transfer_cost_group_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                        cxihv.h_transfer_cost_group_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                    cxihv.h_transfer_cost_group_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                    cxihv.h_transfer_cost_group_id),
             h_cost_group_id)
             cost_group_id,
          /*COST_GROUP_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                   cxihv.h_cost_group_id),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                   cxihv.h_cost_group_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                    cxihv.h_cost_group_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                    cxihv.h_cost_group_id),
             h_transfer_cost_group_id)
             transfer_cost_group_id,
          /*TRANSFER_COST_GROUP_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                        cxihv.h_project_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                        cxihv.h_project_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                    cxihv.h_project_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                    cxihv.h_project_id),
             h_to_project_id)
             to_project_id,
          /* TO_PROJECT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                        cxihv.h_to_project_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                        cxihv.h_to_project_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                         cxihv.h_to_project_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                         cxihv.h_to_project_id),
             h_project_id)
             project_id,
          /* PROJECT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                        cxihv.h_task_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                        cxihv.h_task_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                         cxihv.h_task_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                         cxihv.h_task_id),
             h_to_task_id)
             to_task_id,
          /* TO_TASK_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                        cxihv.h_to_task_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                        cxihv.h_to_task_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                         cxihv.h_to_task_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                         cxihv.h_to_task_id),
             h_task_id)
             task_id,
          /* TASK_ID */
          cxihv.h_ledger_id ledger_id,
          cxihv.organization_id l_organization_id,
          mta.inv_sub_ledger_id distribution_identifier,
          mta.transaction_id,
          mp.organization_code l_organization_code
     FROM mtl_transaction_accounts mta,
          cst_xla_inv_headers_v cxihv,
          gl_ledgers gl,
          mtl_material_transactions mmt,
          xla_events_gt xgt,
          mtl_parameters mp
    WHERE     mta.transaction_id = cxihv.transaction_id
          AND mta.transaction_source_type_id =
                 cxihv.transaction_source_type_id
          AND mta.transaction_id = mmt.transaction_id
          AND cxihv.event_id = xgt.event_id
          AND cxihv.organization_id = mta.organization_id
          AND gl.ledger_id = cxihv.h_ledger_id
          AND mta.organization_id = mp.organization_id
          AND (CASE
                  WHEN (    mta.accounting_line_type = 1
                        AND mmt.transaction_type_id IN (11, 14))
                  THEN
                     mta.cost_element_id
                  ELSE
                     1
               END) = 1
   UNION ALL
   SELECT cxihv.event_id,
          /* EVENT IDENTIFIER */
          ROW_NUMBER ()
             OVER (PARTITION BY cxihv.event_id ORDER BY cxihv.event_id)
             AS line_number,
          /* LINE NUMBER */
          /*nvl((select purchase_price_var_account
          from   mtl_parameters
          where  organization_id = mmt.organization_id)
          , -1)
          code_combination_id,*/
          NVL (intg_ic_pricing_pkg.get_profit_inv_acct (
                  mmt.transfer_organization_id,
                  mmt.organization_id,
                  mmt.transaction_type_id,
                  mmt.rcv_transaction_id),
               -1)
             code_combination_id,
          intg_ic_pricing_pkg.get_ppv_amt (
             'ENTERED',
             mmt.transaction_id,
             mmt.inventory_item_Id,
             mmt.organization_id,
             mta.accounting_line_type,
             mta.transaction_value,
             mmt.transaction_type_Id,
             mta.primary_quantity,
             mta.base_transaction_value,
             NVL (
                mmt.currency_code,
                intg_ic_pricing_pkg.get_functional_currency (
                   mmt.organization_id)),
             NVL (mmt.currency_conversion_rate, 1))
             entered_amount,
          6 accounting_line_type_code,
          intg_ic_pricing_pkg.get_ppv_amt (
             'ACCOUNTED',
             mmt.transaction_id,
             mmt.inventory_item_Id,
             mmt.organization_id,
             mta.accounting_line_type,
             mta.transaction_value,
             mmt.transaction_type_Id,
             mta.primary_quantity,
             mta.base_transaction_value,
             NVL (
                mmt.currency_code,
                intg_ic_pricing_pkg.get_functional_currency (
                   mmt.organization_id)),
             NVL (mmt.currency_conversion_rate, 1))
             accounted_amount,
          /* ACCOUNTED_AMOUNT */
          mta.rate_or_amount,
          /* RATE_OR_AMOUNT */
          mta.basis_type inv_txn_basis_type,
          /* BASIS_TYPE */
          NVL (mta.currency_code, gl.currency_code) currency_code,
          DECODE (
             mta.currency_code,
             NULL, NVL (mta.currency_conversion_date,
                        mmt.currency_conversion_date),
             gl.currency_code, mta.currency_conversion_date,
             NVL (mta.currency_conversion_date,
                  NVL (mmt.currency_conversion_date, cxihv.transaction_date)))
             currency_conversion_date,
          DECODE (mta.currency_code,
                  NULL, TO_NUMBER (NULL),
                  gl.currency_code, TO_NUMBER (NULL),
                  mta.currency_conversion_rate)
             currency_conversion_rate,
          DECODE (mta.currency_code,
                  NULL, NULL,
                  gl.currency_code, NULL,
                  mta.currency_conversion_type)
             currency_conversion_type,
          mta.resource_id material_overhead_id,
          /* MATERIAL_OVERHEAD_ID */
          mta.cost_element_id,
          /* COST_ELEMENT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                   cxihv.h_transfer_subinventory),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                   cxihv.h_transfer_subinventory),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                    cxihv.h_transfer_subinventory),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_subinventory_code,
                    cxihv.h_transfer_subinventory),
             h_subinventory_code)
             subinventory_code,
          /* SUBINVENTORY_CODE */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                   cxihv.h_subinventory_code),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                   cxihv.h_subinventory_code),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                    cxihv.h_subinventory_code),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_subinventory,
                    cxihv.h_subinventory_code),
             h_transfer_subinventory)
             transfer_subinventory,
          /* TRANSFER_SUBINVENTORY */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                        cxihv.h_transfer_locator_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                        cxihv.h_transfer_locator_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                         cxihv.h_transfer_locator_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_locator_id,
                         cxihv.h_transfer_locator_id),
             h_locator_id)
             locator_id,
          /* LOCATOR_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                   cxihv.h_locator_id),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                   cxihv.h_locator_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                    cxihv.h_locator_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_locator_id,
                    cxihv.h_locator_id),
             h_transfer_locator_id)
             transfer_locator_id,
          /* TRANSFER_LOCATOR_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                        cxihv.h_transfer_cost_group_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                        cxihv.h_transfer_cost_group_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                    cxihv.h_transfer_cost_group_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_cost_group_id,
                    cxihv.h_transfer_cost_group_id),
             h_cost_group_id)
             cost_group_id,
          /*COST_GROUP_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                   cxihv.h_cost_group_id),
             5, DECODE (
                   SIGN (mta.primary_quantity),
                   SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                   cxihv.h_cost_group_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                    cxihv.h_cost_group_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_transfer_cost_group_id,
                    cxihv.h_cost_group_id),
             h_transfer_cost_group_id)
             transfer_cost_group_id,
          /*TRANSFER_COST_GROUP_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                        cxihv.h_project_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                        cxihv.h_project_id),
             28, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                    cxihv.h_project_id),
             55, DECODE (
                    SIGN (mta.primary_quantity),
                    SIGN (cxihv.primary_quantity), cxihv.h_to_project_id,
                    cxihv.h_project_id),
             h_to_project_id)
             to_project_id,
          /* TO_PROJECT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                        cxihv.h_to_project_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                        cxihv.h_to_project_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                         cxihv.h_to_project_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_project_id,
                         cxihv.h_to_project_id),
             h_project_id)
             project_id,
          /* PROJECT_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                        cxihv.h_task_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                        cxihv.h_task_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                         cxihv.h_task_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_to_task_id,
                         cxihv.h_task_id),
             h_to_task_id)
             to_task_id,
          /* TO_TASK_ID */
          DECODE (
             cxihv.transaction_action_id,
             2, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                        cxihv.h_to_task_id),
             5, DECODE (SIGN (mta.primary_quantity),
                        SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                        cxihv.h_to_task_id),
             28, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                         cxihv.h_to_task_id),
             55, DECODE (SIGN (mta.primary_quantity),
                         SIGN (cxihv.primary_quantity), cxihv.h_task_id,
                         cxihv.h_to_task_id),
             h_task_id)
             task_id,
          /* TASK_ID */
          cxihv.h_ledger_id ledger_id,
          cxihv.organization_id l_organization_id,
          (SELECT intg_ic_pricing_pkg.get_sequence
             FROM DUAL)
             distribution_identifier,
          mta.transaction_id,
          mp.organization_code l_organization_code
     FROM mtl_transaction_accounts mta,
          cst_xla_inv_headers_v cxihv,
          gl_ledgers gl,
          mtl_material_transactions mmt,
          xla_events_gt xgt,
          mtl_parameters mp
    WHERE     mta.transaction_id = cxihv.transaction_id
          AND mta.transaction_source_type_id =
                 cxihv.transaction_source_type_id
          AND mta.transaction_id = mmt.transaction_id
          AND cxihv.event_id = xgt.event_id
          AND cxihv.organization_id = mta.organization_id
          AND gl.ledger_id = cxihv.h_ledger_id
          AND mta.organization_id = mp.organization_id
          AND mmt.transaction_type_id IN (10,
                                          13,
                                          19,
                                          39,
                                          69)
          AND mta.accounting_line_type = 1;
