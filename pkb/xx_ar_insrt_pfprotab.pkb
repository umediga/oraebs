DROP PACKAGE BODY APPS.XX_AR_INSRT_PFPROTAB;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_INSRT_PFPROTAB" 
AS
----------------------------------------------------------------------------------------
--| Program:     Integra Life Sciences - PO Number Line Details Interface To Paypal Pkg |
--| Author:      Vargab Pathak  - OCS                                                   |
--| Created:     20-May-12                                                              |
--|                                                                                     |
--| Description: ITGR_INSRT_PFPROTAB contains procedure call to insert po detls n line  |
--|              dtls of a receipt into ipayment tables.                                |
--|                                                                                     |
--| Modifications:                                                                      |
--| -------------                                                                       |
--| Date          Name                Version       Description                         |
--| ---------   ---------------       -------       -----------                         |
--| 20-May-12   IBM Development           1.0       Initial Version                     |
--| 11-FEB-13   Sharath Babu              2.0       Modified as per Case#001904         |
--| 30-JUL-14   Jaya Maran                3.0       Modified as per Case#009107         |
--| 08-AUG-14   Jaya Maran                4.0       Modified as per Case#009342         |
----------------------------------------------------------------------------------------|
--- Package Body
   PROCEDURE itgr_pfpro_polinedtls (errbuf OUT VARCHAR2, retcode OUT NUMBER)
   IS
      vresp_appl_id    NUMBER;
      vresp_id         NUMBER;
      vuser_id         NUMBER;
      --pragma autonomous_transaction;
      v_creditcardno   VARCHAR2 (100);
      v_pcardtype      VARCHAR2 (100);
      errorcode        VARCHAR2 (1000);
      errmsg           VARCHAR2 (1000);

----The below cursor will extract header level data from ar invoice-----
      CURSOR cur_po_no
      IS
         SELECT   SUBSTR(ract.purchase_order,1,40) cust_po_no, ract.customer_trx_id,
                  NVL (its.tangibleid, 0) tangible_id,
                  NVL (its.payeeid, 0) payeeid,
                  NVL (its.trxntypeid, 0) trxntypeid, itc.referencecode,
                  hzl.postal_code shiptozip, hrl.postal_code shipfromzip,
                  SUM (ps.tax_original) taxamount, 'C' tender,
                  ract.trx_number invnum, 0.00 discount,
                  SUM (ps.freight_original) freightamt, '111111' vatregnum,
                  -- do we still need these hard codings
                  '111111' custvatregnum, mcc.commodity_code, 0 dutyamt
             FROM ar_cash_receipt_history_all acrh,
                  ar_cash_receipts_all acr,
                  ar_receipt_methods crm,
                  mtl_system_items_b msi,
                  ra_customer_trx_all ract,
                  ra_customer_trx_lines_all rctl,
                  ar_payment_schedules_all ps,
                  iby_trxn_summaries_all its,
                  iby_trxn_core itc,
                  hz_parties hzp,
                  hz_party_sites hps,
                  hz_cust_acct_sites_all hcas,
                  hz_cust_site_uses_all hcsu,
                  hz_locations hzl,
                  ar_receivable_applications_all arp,
                  mtl_commodity_codes mcc,
                  iby_fndcpt_tx_operations ibyo,
                  hr_locations hrl,
                  hr_organization_units hou
            WHERE 1 = 1
              AND acrh.cash_receipt_id = acr.cash_receipt_id
              AND ACRH.CURRENT_RECORD_FLAG = 'Y'
             -- AND acrh.status = 'REMITTED'
              AND acrh.status != 'REVERSED'
              AND acr.receipt_number IS NOT NULL
              AND acr.receipt_method_id = crm.receipt_method_id
              AND crm.NAME = 'CREDIT CARD RECEIPT'
              AND acr.status = 'APP'
              AND ract.customer_trx_id = rctl.customer_trx_id
              AND ract.customer_trx_id = ps.customer_trx_id
              AND rctl.inventory_item_id = msi.inventory_item_id
              AND rctl.warehouse_id = msi.organization_id
              AND rctl.warehouse_id = hou.organization_id
              AND hrl.location_id = hou.location_id
              AND rctl.line_type = 'LINE'
              AND acr.payment_trxn_extension_id = ibyo.trxn_extension_id
              AND ibyo.transactionid = its.transactionid
              AND its.reqtype = 'ORAPMTREQ'
              AND its.status = '0'
              AND its.trxnmid = itc.trxnmid
              AND NVL (ract.ship_to_customer_id, ract.bill_to_customer_id) =
                                                          hcas.cust_account_id
              AND NVL (ract.ship_to_site_use_id, ract.bill_to_site_use_id) =
                                                              hcsu.site_use_id
              AND hzp.party_id = hps.party_id
              AND hps.party_site_id = hcas.party_site_id
              AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
              AND hps.location_id = hzl.location_id
              AND ract.customer_trx_id = arp.applied_customer_trx_id
              AND arp.display = 'Y'
              AND arp.cash_receipt_id = acr.cash_receipt_id
              AND mcc.commodity_code_id = '2'
              AND NOT EXISTS (SELECT 1
                                FROM pfpro_extend_data ped
                               WHERE ped.tangibleid = its.tangibleid)
         -- to stop processing same data
         GROUP BY ract.purchase_order,
                  ract.customer_trx_id,
                  NVL (its.tangibleid, 0),
                  NVL (its.payeeid, 0),
                  NVL (its.trxntypeid, 0),
                  itc.referencecode,
                  hzl.postal_code,
                  hrl.postal_code,
                  'C',
                  ract.trx_number,
                  0.00,
                  '111111',
                  '111111',
                  mcc.commodity_code;

------------------------end of the header level cursor------------------------------------------

      ------------------The below cursor will retrieve line level data from ar lines-------------------
      CURSOR cur_line_dtls (p_cust_trx_id NUMBER)
      IS
         SELECT   rctl.line_number lineitemnumber, msi.segment1 item_code,

                  --p_tangibleid tangibleid,           --its.tangibleid tangibleid, -- header
                  msi.description item_description,
                  NVL (rctl.quantity_ordered, 0) item_quantity,
                  rctl.unit_selling_price item_cost,
                  uom_code item_unit_of_measure, mcc.commodity_code,
                  apca.tax_original taxamt, NVL (rctl.tax_rate, 0) taxrate,
                  rctl.extended_amount item_price, 0.00 discount,
                                                                 --p_referencecode,               --itc.referencecode , --header
                  0 lineamt
             FROM ar_cash_receipt_history_all acrh,
                  ar_cash_receipts_all acr,
                  mtl_system_items_b msi,
                  ra_customer_trx_all ract,
                  ra_customer_trx_lines_all rctl,
                  ar_payment_schedules_all apca,
                  ar_receivable_applications_all arp,
                  ar_receipt_methods crm,
                  mtl_commodity_codes mcc
            WHERE                                                        --AND
                  acrh.cash_receipt_id = acr.cash_receipt_id
              AND ACRH.CURRENT_RECORD_FLAG = 'Y'
              --AND acrh.status = 'REMITTED'
              AND acrh.status != 'REVERSED'
              AND acr.receipt_number IS NOT NULL
              AND acr.receipt_method_id = crm.receipt_method_id
              AND crm.NAME = 'CREDIT CARD RECEIPT'
              AND acr.status = 'APP'
              AND rctl.inventory_item_id = msi.inventory_item_id
              AND ract.customer_trx_id = rctl.customer_trx_id
              AND apca.customer_trx_id = rctl.customer_trx_id
              AND rctl.customer_trx_id = p_cust_trx_id
              AND rctl.line_type = 'LINE'
              AND ract.customer_trx_id = arp.applied_customer_trx_id
              AND arp.display = 'Y'
              AND arp.cash_receipt_id = acr.cash_receipt_id
              AND ract.customer_trx_id = arp.applied_customer_trx_id
              AND arp.display = 'Y'
              AND mcc.commodity_code_id = '2'
         GROUP BY msi.description,
                  rctl.line_number,
                  msi.segment1,
                  --p_tangibleid,
                  NVL (rctl.quantity_ordered, 0),
                  rctl.unit_selling_price,
                  uom_code,
                  apca.tax_original,
                  NVL (rctl.tax_rate, 0),
                  rctl.extended_amount,
                  --p_referencecode,
                  mcc.commodity_code;
   ------------------------------------end of the line level query----------------------------------------
   BEGIN
----*********************************************************************************---------
         --The Package is initialized globally with the below initialization--
----*********************************************************************************----------
      vresp_appl_id := apps.fnd_profile.VALUE ('RESP_APPL_ID');
      vresp_id := apps.fnd_profile.VALUE ('RESP_ID');
      vuser_id := apps.fnd_profile.VALUE ('USER_ID');
      fnd_global.apps_initialize (vuser_id, vresp_id, vresp_appl_id);

--------*************************************************************************************-------
                              -- Initilization is done --
-------**************************************************************************************-------
      BEGIN
--------**************************************************************************-----------------
                 -- The procedure ITGR_pfpro_POLINEDTLS begins
--------**************************************************************************-----------------
         fnd_file.put_line (fnd_file.LOG,
                            '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'Inside procedure ITGR_pfpro_POLINEDTLS '
                           );
         fnd_file.put_line (fnd_file.LOG,
                            '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
                           );

---------------------------------------HEADER LEVEL-------------------------------------------------------------

         -- ********************************************************************************************************-----
               -- The Header cursor is started fetching the data into pfpro_extend_data(Header table)  --
-- ********************************************************************************************************-----
         FOR i IN cur_po_no
         LOOP
            EXIT WHEN CUR_PO_NO%NOTFOUND;
            begin
            INSERT INTO pfpro_extend_data
                        (ponum, tangibleid, tender, payeeid, trxntypeid,
                         origid, shiptozip, shipfromzip,
                         taxamt, invnum, discount,
                         freightamt, vatregnum, custvatregnum,
                         commcode, dutyamt,custcode
                        )
                 VALUES (i.cust_po_no, i.tangible_id, '1', i.payeeid, '8',
                         i.referencecode, i.shiptozip, i.shipfromzip,
                         i.taxamount, i.invnum,  --i.cust_po_no,   Modified as per Case#001904
                         i.discount,
                         i.freightamt, i.vatregnum, i.custvatregnum,
                         SUBSTR(i.commodity_code,1,4), i.dutyamt,i.cust_po_no
                        );

            COMMIT;
            fnd_file.put_line
                        (fnd_file.LOG,
                         'Data had been inserted into pfpro_extend_data table'
                        );
            exception
            WHEN OTHERS THEN

            errorcode := SQLCODE;
            errmsg := SUBSTR (SQLERRM, 1, 100);
            apps.fnd_file.put_line (fnd_file.LOG,
                                    'Error Message: ' || ERRORCODE || ERRMSG
                                   );
            retcode := 1;
            end;

-- ********************************************************************************************************-----
                           --The data had been inserted into header table --
-- ********************************************************************************************************-----

            ----------------------------------------------LINE LEVEL----------------------------------------------------------
-- ********************************************************************************************************-----
            --The Cursor is fetching line level data into pfpro_extend_lineitem_data(Line Table)  --
-- ********************************************************************************************************-----
            FOR k IN cur_line_dtls (i.customer_trx_id)
            LOOP
               EXIT WHEN cur_line_dtls%NOTFOUND;

               --  IF i.header_id = k.header_id
               --  THEN
               begin
               INSERT INTO pfpro_extend_lineitem_data
                           (tangibleid, lineitemnumber, l_upc,
                            l_amt, l_cost, l_desc,
                            l_qty, l_taxamt, l_taxrate,
                            l_uom, l_commcode,
                            l_prodcode, l_discount
                           )
                    VALUES (i.tangible_id, k.lineitemnumber, k.item_code,
                            k.item_price, k.item_cost, k.item_description,
                            k.item_quantity, k.taxamt, k.taxrate,
                            k.item_unit_of_measure, SUBSTR(k.commodity_code,1,4),
                            i.cust_po_no, k.discount
                           );

-- ********************************************************************************************************-----
                                  --The data had been inserted into Line table --
-- ********************************************************************************************************-----
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Data had been inserted into pfpro_extend_lineitem_data table'
                  );
               COMMIT;
            -- END IF;
             exception
            WHEN OTHERS THEN

            errorcode := SQLCODE;
            errmsg := SUBSTR (SQLERRM, 1, 100);
            apps.fnd_file.put_line (fnd_file.LOG,
                                    'Error Message: ' || ERRORCODE || ERRMSG
                                   );
            retcode := 1;
            END;

            END LOOP;
         END LOOP;
-- ********************************************************************************************************-----
                        --EXCEPTIONS to handle the errors raised if any during process--
-- ********************************************************************************************************-----
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            retcode := 1;
            apps.fnd_file.put_line (fnd_file.LOG,
                                    'No data avialable to insert into table'
                                   );
         WHEN TOO_MANY_ROWS
         THEN
            retcode := 1;
            apps.fnd_file.put_line
                    (fnd_file.LOG,
                     'Too many rows have been retrieved and unable to insert'
                    );
         WHEN OTHERS
         THEN
            retcode := 1;
            errorcode := SQLCODE;
            errmsg := SUBSTR (SQLERRM, 1, 100);
            apps.fnd_file.put_line (fnd_file.LOG,
                                    'Error Message: ' || errorcode || errmsg
                                   );
      END;
   END itgr_pfpro_polinedtls;
END xx_ar_insrt_pfprotab;
/
