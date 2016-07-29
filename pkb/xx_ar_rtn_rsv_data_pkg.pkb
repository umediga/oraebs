DROP PACKAGE BODY APPS.XX_AR_RTN_RSV_DATA_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_RTN_RSV_DATA_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 30-JAN-2014
 File Name     : XXARRTNRSVRPT.pkb
 Description   : This script creates the body of the package
                 xx_ar_rtn_rsv_data_pkg to create code to fetch
                 report data
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-JAN-2014 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------

--Function to fetch credit memo data
PROCEDURE get_rtn_rsv_report_data ( p_org_id     IN NUMBER
                                   ,p_date_from  IN DATE
                                   ,p_date_to    IN DATE
                                   )
IS
   --Cursor to fetch credit memo data
  CURSOR c_cm_data
  IS
  SELECT RCT.TRX_NUMBER cm_num
        --,RCT.customer_trx_id,rctl.customer_trx_line_id
        ,RCT.TRX_DATE cm_date
        ,hca.account_number cust_num
        ,(select hp.party_name
            FROM hz_parties hp
           where hp.party_id = hca.party_id ) cust_name
        ,RCT.REASON_CODE ret_reason
        ,RCT.PURCHASE_ORDER ret_po_num
        ,RCT.INTERFACE_HEADER_ATTRIBUTE1 ret_ord_num
        ,(SELECT ott.NAME
            FROM oe_transaction_types_tl ott
                ,oe_order_headers_all ooh
           WHERE ott.transaction_type_id = ooh.order_type_id
             AND ott.language = 'US'
             and to_char(ooh.order_number) = RCT.INTERFACE_HEADER_ATTRIBUTE1 ) ret_ord_type
  	,msib.segment1  credited_item
  	,rctl.description credited_item_desc
  	,(aps.amount_due_original * nvl(aps.exchange_rate, 1)) cinv_amt_func
  	,nvl(aps.exchange_rate, 1) cinv_exchg_rate
        ,glcc.attribute1||'.'||glcc.attribute2  divisionalization
        ,RCTL.EXTENDED_AMOUNT credit_line_amt
        ,RCTL.LINE_TYPE credit_line_type
        ,APS.AMOUNT_DUE_ORIGINAL credit_inv_amt
        ,RCT.INVOICE_CURRENCY_CODE inv_cur
        ,glcc.concatenated_segments  ret_rev_acct
        ,DECODE(rct.previous_customer_trx_id,NULL,NULL,rct3.trx_number) orig_inv_num
        ,DECODE(rct.previous_customer_trx_id,NULL,NULL,rct3.interface_header_attribute1) orig_order_num
        ,DECODE(rct.previous_customer_trx_id,NULL,NULL,rct3.trx_date) orig_inv_date
        ,DECODE(rct.previous_customer_trx_id,NULL,NULL,rct3.purchase_order) orig_po_num
        ,DECODE(rct.previous_customer_trx_id,NULL,NULL,aps3.amount_due_original) orig_inv_amount
        /*,DECODE(RCT.PREVIOUS_CUSTOMER_TRX_ID,NULL, orig.TRX_NUMBER,
             RCT3.trx_number
             ) ORIG_INV_NUM
        ,DECODE(RCT.PREVIOUS_CUSTOMER_TRX_ID,NULL, orig.order_number,
             RCT3.INTERFACE_HEADER_ATTRIBUTE1
           ) ORIG_ORDER_NUM
        ,DECODE(RCT.PREVIOUS_CUSTOMER_TRX_ID,NULL, orig.TRX_DATE,
             RCT3.trx_date
           ) ORIG_INV_DATE
        ,DECODE(RCT.PREVIOUS_CUSTOMER_TRX_ID,NULL, orig.purchase_order,
             RCT3.purchase_order
           ) ORIG_PO_NUM
        ,DECODE(RCT.PREVIOUS_CUSTOMER_TRX_ID,NULL, orig.AMOUNT_DUE_ORIGINAL,
             aps3.amount_due_original
           ) ORIG_INV_AMOUNT*/
           ,RCT.PREVIOUS_CUSTOMER_TRX_ID
           ,rctl.interface_line_attribute1
           ,rctl.interface_line_attribute6
           ,NULL orig_line_id
           ,NULL orig_cust_trx_id
           ,NULL orig_cust_trx_line_id
   FROM  RA_CUSTOMER_TRX_ALL RCT
        ,RA_CUSTOMER_TRX_LINES_ALL rctl
        ,AR_PAYMENT_SCHEDULES_ALL APS
        ,RA_CUST_TRX_LINE_GL_DIST_ALL rgld
        ,HZ_CUST_ACCOUNTS HCA
        ,ra_cust_trx_types_all rctt
        --,xx_ra_trx_original_data orig
        ,RA_CUSTOMER_TRX_ALL RCT3
        ,AR_PAYMENT_SCHEDULES_ALL APS3
        ,mtl_system_items_b msib
        ,GL_CODE_COMBINATIONS_KFV glcc
  WHERE 1=1
    AND rgld.code_combination_id = glcc.code_combination_id(+)
    AND rctl.inventory_item_id = msib.inventory_item_id(+)
    AND msib.organization_id(+) = 87
    AND RCT3.CUSTOMER_TRX_ID = APS3.CUSTOMER_TRX_ID(+)
    AND RCT.previous_customer_trx_id = RCT3.CUSTOMER_TRX_ID(+)
    AND rgld.account_set_flag = 'N'
    and rgld.account_class in ('REV', 'FREIGHT', 'TAX')
    AND rctl.customer_trx_line_id = rgld.customer_trx_line_id
    and hca.customer_type = 'R'
    and HCA.CUST_ACCOUNT_ID = RCT.BILL_TO_CUSTOMER_ID
    and rct.customer_trx_id = aps.customer_trx_id
    --and rctl.interface_line_attribute6 = orig.interface_line_attribute6(+)
    --and rctl.interface_line_attribute1 = orig.interface_line_attribute1(+)
    AND EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values fnd
                    WHERE fnd.LOOKUP_type = 'INTG_RTNRSV_CMTYPES'
                      AND fnd.meaning = RCTT.name
                      AND language = 'US'
                      AND enabled_flag = 'Y'
                    AND NVL(FND.END_DATE_ACTIVE, SYSDATE) >= TRUNC(SYSDATE))
    --and RCTT.STATUS = 'A'
    AND RCTT.TYPE = 'CM'
    AND TRUNC(SYSDATE) >= TRUNC(NVL(rctt.start_date, SYSDATE))
    AND TRUNC(SYSDATE) <= TRUNC(NVL(rctt.end_date, SYSDATE + 1))
    --AND RCT.trx_number = '23591'
    and RCT.org_id = rctt.org_id
    AND RCT.CUST_TRX_TYPE_ID = RCTT.CUST_TRX_TYPE_ID
    and rctl.extended_amount <> 0
    AND RCT.customer_trx_id = rctl.customer_trx_id
    and rct.org_id = nvl(p_org_id, rct.org_id)
    --and trunc(rct.trx_date) between fnd_date.canonical_to_date (:p_date_from) and fnd_date.canonical_to_date (:p_date_to)
    and trunc(rct.trx_date) between p_date_from AND p_date_to
    ORDER BY 1,3;

   --table type declaration
   TYPE g_cm_data IS TABLE OF c_cm_data%ROWTYPE;
   x_cm_data g_cm_data;

BEGIN
   --Fetch Credit Memo data into temporary table
   BEGIN
         OPEN c_cm_data;
         LOOP
         FETCH c_cm_data
         BULK COLLECT INTO x_cm_data LIMIT 1000;
         FORALL i IN 1 .. x_cm_data.COUNT
        INSERT INTO xx_ar_rtn_rsv_gbltmp_tbl
        VALUES x_cm_data (i);
        EXIT WHEN c_cm_data%NOTFOUND;
     END LOOP;
     CLOSE c_cm_data;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk insert:Credit Memo Data'||SQLERRM);
   END;
   --Update Original Order Details for return_context ORDER
   BEGIN
      UPDATE xx_ar_rtn_rsv_gbltmp_tbl rtn
         SET (rtn.orig_order_num
             ,rtn.orig_po_num
             ,rtn.orig_line_id ) = ( SELECT TO_CHAR(ooh_orig.order_number)
                                           ,ooh_orig.cust_po_number purchase_order
                                           ,ool2.return_attribute2 orig_line_id
                                       FROM oe_order_headers_all ooh_orig
                                           ,oe_order_headers_all ooh2
                                           ,oe_order_lines_all ool2
                                      WHERE ool2.return_attribute1 = TO_CHAR(ooh_orig.header_id)
                                        AND ool2.header_id = ooh2.header_id
                                        AND ool2.return_context = 'ORDER'
                                        AND ool2.line_id = rtn.intf_line_attr6
                                        AND ooh2.order_number = rtn.intf_line_attr1
                                   )
        WHERE rtn.prev_cust_trx_id IS NULL;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating Original Order Details for return_context ORDER: '||SQLERRM);
   END;
   --Update Original Invoice Details for return_context ORDER
   BEGIN
      UPDATE xx_ar_rtn_rsv_gbltmp_tbl rtn
         SET (rtn.orig_inv_num
             ,rtn.ORIG_INV_DATE
             ,rtn.orig_inv_amount) = ( SELECT rct_orig.trx_number
                                             ,rct_orig.trx_date
                                             ,aps_orig.amount_due_original
                                         FROM ra_customer_trx_all rct_orig
                                             ,ra_customer_trx_lines_all rctl_orig
                                             ,ar_payment_schedules_all aps_orig
                                        WHERE rct_orig.customer_trx_id = aps_orig.customer_trx_id
                                          AND rctl_orig.interface_line_attribute6 = rtn.orig_line_id
                                          AND rct_orig.customer_trx_id = rctl_orig.customer_trx_id
                                          AND rctl_orig.interface_line_attribute1 = rtn.orig_order_num
			             )
       WHERE rtn.prev_cust_trx_id IS NULL;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating Original Invoice Details for return_context ORDER: '||SQLERRM);
   END;
   --Update Original Order Details for return_context INVOICE
   BEGIN
      UPDATE xx_ar_rtn_rsv_gbltmp_tbl rtn
         SET (rtn.orig_cust_trx_id
             ,rtn.orig_cust_trx_line_id ) = ( SELECT ool2.return_attribute1
      					            ,ool2.return_attribute2
      				                FROM oe_order_headers_all ooh2
      					            ,oe_order_lines_all ool2
      				               WHERE ool2.return_context = 'INVOICE'
      					         AND ool2.line_id = rtn.intf_line_attr6
      					         AND ooh2.header_id = ool2.header_id
      					         AND ooh2.order_number = rtn.intf_line_attr1
      			                    )
       WHERE rtn.orig_order_num IS NULL
         AND rtn.prev_cust_trx_id IS NULL;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating RA Cust Trx Id Details for return_context INVOICE: '||SQLERRM);
   END;
   --Update Original Order and Invoice Details for return_context INVOICE
   BEGIN
      UPDATE xx_ar_rtn_rsv_gbltmp_tbl rtn
         SET (rtn.orig_inv_num
             ,rtn.ORIG_ORDER_NUM
             ,rtn.ORIG_INV_DATE
             ,rtn.ORIG_PO_NUM
             ,rtn.ORIG_INV_AMOUNT) = ( SELECT rct_orig.trx_number
      					     ,rctl_orig.sales_order
      					     ,rct_orig.trx_date
      					     ,rct_orig.purchase_order
      					     ,aps_orig.amount_due_original
      					FROM ra_customer_trx_all rct_orig
      					    ,ra_customer_trx_lines_all rctl_orig
      					    ,ar_payment_schedules_all aps_orig
      				       WHERE rct_orig.customer_trx_id = aps_orig.customer_trx_id
      					 AND rct_orig.customer_trx_id = rctl_orig.customer_trx_id
      					 AND rctl_orig.customer_trx_line_id = rtn.orig_cust_trx_line_id
      					 AND rct_orig.customer_trx_id = rtn.orig_cust_trx_id
      				      )
      WHERE rtn.orig_cust_trx_id IS NOT NULL
        AND rtn.prev_cust_trx_id IS NULL;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating Original Order and Invoice Details for return_context INVOICE: '||SQLERRM);
   END;


 EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error inside get_rtn_rsv_report_data');

END get_rtn_rsv_report_data;

END xx_ar_rtn_rsv_data_pkg;
/
