DROP PACKAGE BODY APPS.XXOM_MAT_ISS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_MAT_ISS_PKG" IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_MAT_ISS_PKG.pkb
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES
*
*   CALLED BY
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     1.0  29-DEC-2013 Brian Stadnik
*     2.0  09-MAY-2014 Brian Stadnik      Added logic to look at attribute on the subinventory
*                                        for dealers/reps with multiple resources.  also exclude
*                                        KIT_EXPLOSION_150 and transactions initiated in SS from
*                                        the file.
*          23-MAY-2014 Brian Stadnik     Changed to include Intransit Shipments again
*          21-JUN-2014 Brian Stadnik     Include To Surgisoft (TOSS) transactions; exlude
*                                          Subinventory transfers and No Surgisoft (NOSS)
*                                        Exclude Hospital and International for all transactions
*                                        Use the DFF for Case (external order) rather than Order_source
*                                        so SS can reconcile manually created orders.
*
* ISSUES:
*
******************************************************************************************/

PROCEDURE INTG_INV_ISSUE (errbuf             OUT VARCHAR2,
                          retcode            OUT VARCHAR2,
                          p_orgn_id          IN  NUMBER,
                          p_subinv_code      IN  VARCHAR2,
                          p_trans_date        IN  VARCHAR2,
                          p_set_org_id        IN  NUMBER)

IS

v_status        VARCHAR2(20);
lv_count        NUMBER:=0;
l_proc_status   VARCHAR2(1):= 'P';

-- Cursor to get the inventory issue details
CURSOR c1_issue is
select mtt.transaction_type_name,
     mmt.inventory_item_id,
     mmt.organization_id,
     decode(msib.item_type,'K','Y','N') is_set, -- bbom.attribute1 is_set, bbom.attribute1 is_set,
     NVL (mut.serial_number, mtln.lot_number) lot_serial,
     mut.serial_number,
     mtln.lot_number,
           CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               -1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
         END * -1
            quantity,
     mmt.transaction_date issue_trans_date,
     nvl(jrs.salesrep_number, -999) trans_init, -- rep or dealer on order       -- ooha.attribute17 trans_init,
     hp.party_name trans_recipt, -- hospital consignment for the case of a subinventory transfer
     nvl(ooha.attribute12,substr(ooha.orig_sys_document_ref,1,23)) order_id,
     ooha.order_number Salesorderno,
     ooha.cust_po_number,
     mmt.transaction_id ORG_TRANS_ID,
     mmt.transaction_reference
from mtl_sales_orders mso,
     oe_order_headers_all ooha,
     mtl_material_transactions mmt,
     mtl_transaction_types mtt,
     mtl_system_items_b msib,
     mtl_transaction_lot_numbers mtln,
     mtl_unit_transactions mut,
     mtl_lot_numbers mln,
     hz_parties hp,
     hz_cust_accounts hca,
     jtf_rs_salesreps jrs,
     mtl_secondary_inventories msi
     --,
   --  XXOM_MAT_ISSUE_STG xmis
 where mso.segment1 = ooha.order_number
 and mso.sales_order_id = mmt.transaction_source_id
 and mmt.transaction_type_id = mtt.transaction_type_id
 and mmt.transaction_quantity < 0
 and mmt.transaction_id = mtln.transaction_id(+)
 and mmt.transaction_id = mut.transaction_id(+)
 AND msib.inventory_item_id = mmt.inventory_item_id
 and msib.organization_id = mmt.organization_id
 -- exclude Hospitals and International
 AND msi.secondary_inventory_name = mmt.subinventory_code
 AND msi.organization_id = mmt.organization_id
 AND msi.attribute1 not in ('H','I')
 --
 and mtln.inventory_item_id = mln.inventory_item_id(+)
 and mtln.organization_id = mln.organization_id(+)
 and mtln.lot_number = mln.lot_number(+)
 AND ooha.sold_to_org_id = hca.cust_account_id
 AND hca.party_id = hp.party_id
 AND ooha.salesrep_id = jrs.salesrep_id
 and mtt.transaction_type_id in (33,52) -- sales order, pick confirm
 /*
 and (
       ( mtt.transaction_type_id = 33 and ooha.sales_channel_code = 'FIA' ) -- only ones inititaed from SS?
      OR mtt.transaction_type_id = 52
     )
     */
 and trunc(mmt.transaction_date) >= to_date(p_trans_date, 'YYYY/MM/DD HH24:MI:SS')
 and mmt.organization_id = p_orgn_id
 and mtt.transaction_type_name IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name =
                                                'INTG_INV_ISSUE_TXN_TYPE'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
 --AND mtt.transaction_type_name in ('Account alias issue','Intransit Shipment','Subinventory Transfer','Sales Order Pick')
 --AND mmt.attribute2 IS NULL
 /* Amin 05/29/2014 eliminate duplicate unpacks*/
         AND NOT EXISTS ( SELECt 1 from XXOM_MAT_ISSUE_STG xmis where xmis.ORG_TRANS_ID=mmt.transaction_id)

 /*and mmt.transaction_id = xmis.ORG_TRANS_ID (+)
 and mmt.transaction_date >= NVL ( (TO_DATE (xmis.transaction_date, 'DD-MON-YYYY HH24:MI:SS')), mmt.transaction_date- 1)
 */
 
 UNION
 SELECT   decode(mtt.transaction_type_name,'TOSS-Sub Transfer','Subinventory Transfer',mtt.transaction_type_name),
          mmt.inventory_item_id,
          mmt.organization_id,
          decode(msib.item_type,'K','Y','N') is_set, -- bbom.attribute1 is_set, bbom.attribute1 is_set,
          NVL (mut.serial_number, mtln.lot_number) lot_serial,
          mut.serial_number,
          mtln.lot_number,
           CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               -1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
         END * -1
            quantity,
         mmt.transaction_date issue_trans_date,
        NVL ( (
/*
      select  nvl(nvl(milk.attribute3,msi.attribute2),-999)
      from
           mtl_secondary_inventories msi,
           hr_locations hl,
           po_location_associations_all pla,
           mtl_item_locations milk
      where pla.location_id = hl.location_id
      and hl.location_id = msi.location_id
      and msi.secondary_inventory_name = mmt.subinventory_code
      and milk.inventory_location_id = mmt.locator_id
      */
        select nvl(milk.attribute3,msi.attribute2)
        from  mtl_secondary_inventories msi, mtl_item_locations_kfv milk, mtl_parameters mp
        where mp.organization_code = '150' 
          and mp.organization_id = msi.organization_id
          and msi.organization_id = milk.organization_id 
          and msi.secondary_inventory_name = milk.subinventory_code 
          and (milk.disable_date is null or trunc(milk.disable_date) > sysdate)
          and milk.inventory_location_id = mmt.locator_id
         ),-999)  trans_init,
        -- party_recv_transfer
         -- mmt.attribute3 trans_init,
          NVL (DECODE (mtt.transaction_type_name,
                      'Account alias issue',
                      '-1',
                      'Expired Lot Issue',
                      '-1',
                      'FI SS CS ADJ',
                      '-1',
                      -- Exclude normal Subinventory Transfer
                      -- 'Subinventory Transfer',
                      -- Instead include To Surgisoft Sub transfer
                      'TOSS-Sub Transfer',
                            NVL ( (
        select nvl(milk.attribute3,msi.attribute2)
        from  mtl_secondary_inventories msi, mtl_item_locations_kfv milk, mtl_parameters mp
        where mp.organization_code = '150' 
          and mp.organization_id = msi.organization_id
          and msi.organization_id = milk.organization_id 
          and msi.secondary_inventory_name = milk.subinventory_code 
          and (milk.disable_date is null or trunc(milk.disable_date) > sysdate)
          and milk.inventory_location_id = mmt.transfer_locator_id
                            /*

          select nvl(msi.attribute2, -999)
      from
           mtl_secondary_inventories msi,
           hr_locations hl,
           po_location_associations_all pla
      where pla.location_id = hl.location_id
      and hl.location_id = msi.location_id
      and msi.secondary_inventory_name = mmt.transfer_subinventory
      */
         ),-999)

                    --  mmt.transfer_subinventory

                      ), organization_name) trans_recipt,
          null order_id,
          null Salesorderno,
          null cust_po_number,
          mmt.transaction_id ORG_TRANS_ID,
          mmt.transaction_reference
  FROM   mtl_material_transactions mmt,
         mtl_transaction_types mtt,
         mtl_system_items_b msib,
         mtl_transaction_lot_numbers mtln,
         mtl_unit_transactions mut,
         org_organization_definitions ood,
         mtl_secondary_inventories msi
          /* Amin 05/29/2014 eliminate duplicate unpacks*/
      --,
         --XXOM_MAT_ISSUE_STG xmis
 WHERE      mtt.transaction_type_id in (2,3,21,31,100,200) -- 2 sub transfer
         AND mmt.transaction_id = mtln.transaction_id(+)
         AND mmt.transaction_id = mut.transaction_id(+)
         AND mmt.transaction_type_id = mtt.transaction_type_id
         AND ood.organization_id(+) = mmt.transfer_organization_id
         AND msib.inventory_item_id = mmt.inventory_item_id
         and msib.organization_id = mmt.organization_id
         -- exclude Hospitals and International
         AND msi.secondary_inventory_name = mmt.subinventory_code
         AND msi.organization_id = p_orgn_id
         AND msi.attribute1 not in ('H','I')
         --
         AND mmt.transaction_quantity < 0
         AND mmt.organization_id = p_orgn_id
         AND mtt.transaction_type_name IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name = 'INTG_INV_ISSUE_TXN_TYPE'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
        -- exclude implosions and the SS initiated transfers
        AND nvl(mmt.transaction_source_id,-99999) not in
                      ( SELECT disposition_id -- distribution_account
                        FROM   apps.mtl_generic_dispositions
                        WHERE  organization_id = p_orgn_id
                        AND    segment1 = 'KIT_EXPLOSION_150'
                      )
           AND  ( nvl(mmt.source_code,'XYZYZX') <> 'Txn from SS'
                 and  nvl(mmt.transaction_source_name, 'XYZYZX') <> 'NOSS'
                )
         AND trunc(mmt.transaction_date) >= to_date(p_trans_date, 'YYYY/MM/DD HH24:MI:SS') -- commented today
--         AND mmt.attribute2 IS NULL;
 /* Amin 05/29/2014 eliminate duplicate unpacks*/
         AND NOT EXISTS ( SELECt 1 from XXOM_MAT_ISSUE_STG xmis where xmis.ORG_TRANS_ID=mmt.transaction_id);

 /*and mmt.transaction_id = xmis.ORG_TRANS_ID (+)
 and mmt.transaction_date >= NVL ( (TO_DATE (xmis.transaction_date, 'DD-MON-YYYY HH24:MI:SS')), mmt.transaction_date- 1)
 */

BEGIN
  apps.fnd_file.put_line ( fnd_file.LOG, 'p_orgn_id: ' || p_orgn_id );
  apps.fnd_file.put_line ( fnd_file.LOG, 'p_subinv_code: ' || p_subinv_code );

  FOR inv_issue IN c1_issue LOOP
  EXIT when c1_issue%NOTFOUND;

  IF NOT(inv_issue.transaction_type_name IN ('Subinventory Transfer','Intransit Shipment') AND nvl(inv_issue.is_set,'N') = 'Y') THEN

      INSERT INTO XXOM_MAT_ISSUE_STG
                        (    TRANSACTION_ID
                            ,TRANSACTION_DATE
                            ,ORACLE_TRANS_TYPE
                            ,ITEM
                            ,IS_SET
                            ,LOTSERIAL
                            ,LOT_NUMBER
                            ,SERIAL_NUMBER
                            ,QUANTITY
                            ,ISSUE_TRANSACTION_DATE
                            ,TRANS_INITIATOR
                            ,TRANS_RECIPIENT
                            ,ORDER_ID
                            ,SALES_ORDER_NO
                            ,CUST_PO_NUM
                            ,STATUS
                            ,MESSAGE
                            ,ORG_TRANS_ID
                            ,TRANSACTION_REFERENCE
                            ,INVENTORY_ITEM_ID
                            ,ORGANIZATION_ID
                         )
                            VALUES
                         (
                            XXOM_MAT_ISS_TRANS_SEQ.NEXTVAL,                -- transaction_id
                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    -- transaction_date
                            inv_issue.transaction_type_name,               -- oracle_trans_type
                            inv_issue.inventory_item_id,                   -- inventory_item_id
                            inv_issue.is_set,                              -- is_set
                            inv_issue.lot_serial,                          -- lot_Serial
                            inv_issue.lot_number,                          -- lot_number
                            inv_issue.serial_number,                       -- serial_number
                            inv_issue.quantity,                            -- quantity
                            inv_issue.issue_trans_date,                    -- issue_transaction_date
                            inv_issue.trans_init,                          -- Transaction Initiator
                            inv_issue.trans_recipt,                        -- Transaction Recipient
                            inv_issue.order_id,                            -- Order ID
                            inv_issue.Salesorderno,                        -- Sales Order No
                            inv_issue.cust_po_number,                      -- Customer PO Number
                            NULL,                                          -- Status
                            NULL,
                            inv_issue.org_trans_id,
                            substr(inv_issue.transaction_reference,1,78),   -- Message
                            inv_issue.inventory_item_id,
                            inv_issue.organization_id
                          );


           lv_count := lv_count + 1;
     END IF;
    END LOOP;

    fnd_file.put_line (fnd_file.LOG, 'The Total Records Inserted into XXOM_MAT_ISSUE_STG Table is:' || lv_count );
    l_proc_status := 'P';
    COMMIT;

    IF l_proc_status = 'P' THEN
      INTG_INV_ISSUE_EXP_PRC;
    END IF;

EXCEPTION
WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line
            (fnd_file.LOG, 'Unable to insert into Staging table XXOM_MAT_ISSUE_STG:'
             || SQLERRM );
END INTG_INV_ISSUE;

PROCEDURE INTG_ERROR_MESSAGE(  p_msg         IN VARCHAR2,
                               p_status      IN VARCHAR2,
                               p_trans_id    IN NUMBER)
   IS
   BEGIN
      UPDATE   XXOM_MAT_ISSUE_STG
         SET   status = p_status,
               message = p_msg
       WHERE   transaction_id = p_trans_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
   END INTG_ERROR_MESSAGE;

PROCEDURE INTG_INV_ISSUE_EXP_PRC
   -------------------------------------------------------------------------------------------------------------|
   --|   This Procedure(INTG_INV_ISSUE_EXP_PRC ) will create the data files from staging tables                 |
   --|   XXOM_MAT_ISSUE_STG and Update File Name and Processed Date with current                                |
   --|   date and time as Exported_date and Exported_status as processed_date and 'Yes' .                       |
   -------------------------------------------------------------------------------------------------------------|

   IS

      l_batch_no          NUMBER;
      l_comm_seq_no       NUMBER;
      l_int_seq_no        NUMBER;
      l_errmsg            VARCHAR2(1000);

      l_file_handle   UTL_FILE.file_type;
      l_file_dir      VARCHAR2(100) := 'XXSGSFTOUT';
      l_file_name     VARCHAR2 (50);
      l_file_name1    VARCHAR2 (50);
      lv_count        NUMBER:=0;
      l_division      VARCHAR2(50);

      CURSOR c_div
      IS
         SELECT distinct nvl(xsms.snm_division, 'nodiv') snm_division
           FROM XXOM_MAT_ISSUE_STG xmis, XXOM_SALES_MARKETING_SET_V xsms
          WHERE xmis.MAT_ISSUE_INTF_DATE IS NULL
            AND xmis.inventory_item_id = xsms.inventory_item_id (+)
            AND xmis.organization_id = xsms.organization_id (+)
          ORDER BY snm_division;

      CURSOR c1(cp_division in varchar2)
      IS
         SELECT xmis.transaction_id
                ,xmis.transaction_date
                ,xmis.oracle_trans_type
                ,xmis.item
                ,xmis.is_set
                ,xmis.lotserial
                ,xmis.lot_number
                ,xmis.serial_number
                ,xmis.quantity
                ,xmis.issue_transaction_date
                ,xmis.trans_initiator
                ,xmis.trans_recipient
                ,xmis.order_id
                ,xmis.sales_order_no
                ,xmis.cust_po_num
                ,xmis.org_trans_id
                ,xmis.transaction_reference
           FROM XXOM_MAT_ISSUE_STG xmis, XXOM_SALES_MARKETING_SET_V xsms
          WHERE xmis.MAT_ISSUE_INTF_DATE IS NULL
            AND xmis.inventory_item_id = xsms.inventory_item_id (+)
            AND xmis.organization_id = xsms.organization_id (+)
            AND nvl(xsms.snm_division, 'nodiv') = cp_division
           ORDER BY transaction_id;

   BEGIN

   FOR r_div in c_div LOOP
     l_division := r_div.snm_division;

        BEGIN
        SELECT   XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
        INTO   l_comm_seq_no
        FROM   DUAL;
        EXCEPTION
        WHEN OTHERS THEN
           apps.fnd_file.put_line ( fnd_file.LOG,
             'Unable to fetch common sequence value: ' || l_comm_seq_no
           );
        END;

        BEGIN
        SELECT   XXOM_MAT_ISSUE_STG_SEQ.NEXTVAL
        INTO l_int_seq_no
        FROM DUAL;

         fnd_file.put_line (fnd_file.LOG, 'l_int_seq_no : ' || l_int_seq_no );
        EXCEPTION
        WHEN OTHERS THEN
            apps.fnd_file.put_line ( fnd_file.LOG,
               'Unable to fetch sequence l_int_seq_no value: ' || l_int_seq_no
            );
        END;

        -- Find the path where the file has to be stored.
        apps.fnd_file.put_line ( fnd_file.LOG, 'l_file_dir: ' || l_file_dir
                   );

        l_file_name  := l_comm_seq_no || '_INVI_' || l_int_seq_no ||'_'||l_division||'.tx1';
            l_file_name1 := l_comm_seq_no || '_INVI_' || l_int_seq_no ||'_'||l_division||'.txt';

        apps.fnd_file.put_line ( fnd_file.LOG,
                      'l_file_name: ' || l_file_name1
                   );
        l_file_handle := UTL_FILE.fopen (l_file_dir, l_file_name, 'w');



        UTL_FILE.put_line (
                    l_file_handle,
                       'TRANSACTION_ID'
                    || '|'
                    || 'TRANSACTION_DATE'
                    || '|'
                    || 'ORACLE_TRANS_TYPE'
                    || '|'
                    || 'ITEM'
                    || '|'
                    || 'IS_SET'
                    || '|'
                    || 'LOT_SERIAL_NUMBER'
                    || '|'
                    || 'QUANTITY'
                    || '|'
                    || 'ISSUE_TRANSACTION_DATE'
                    || '|'
                    || 'TRANS_INITIATOR'
                    || '|'
                    || 'TRANS_RECIPIENT'
                    || '|'
                    || 'ORDER_ID'
                    || '|'
                    || 'SALES_ORDER_NO'
                    || '|'
                    || 'CUST_PO_NUM'
                    || '|'
                    || 'ORACLE_TRANSACTION_ID'
                    || '|'
                    || 'TRANSACTION_REFERENCE'
                    || '|'
               );

        FOR c1_rec in c1(r_div.snm_division) LOOP

           UTL_FILE.put_line (
                  l_file_handle,
                     c1_rec.transaction_id
                  || '|'
                  || c1_rec.transaction_date
                  || '|'
                  || c1_rec.oracle_trans_type
                  || '|'
                  || c1_rec.item
                  || '|'
                  || c1_rec.is_set
                  || '|'
                  || c1_rec.lotserial
                  || '|'
                  || c1_rec.quantity
                  || '|'
                  || c1_rec.issue_transaction_date
                  || '|'
                  || c1_rec.trans_initiator
                  || '|'
                  || c1_rec.trans_recipient
                  || '|'
                  || c1_rec.order_id
                  || '|'
                  || c1_rec.sales_order_no
                  || '|'
                  || c1_rec.cust_po_num
                  || '|'
                  || c1_rec.org_trans_id
                  ||  '|'
                  || c1_rec.transaction_reference
                  || '|'
               );
           lv_count := lv_count + 1;

           UPDATE XXOM_MAT_ISSUE_STG
           SET   status = 'SUCCESS',
                 message = 'File has been extracted and moved to'||l_file_dir,
                 MAT_ISSUE_FILE_NAME = l_file_name1,
                 MAT_ISSUE_INTF_DATE = sysdate
           WHERE transaction_id = c1_rec.transaction_id;

         END LOOP;


          fnd_file.put_line (fnd_file.LOG, 'The total records inserted into the Extract file is:' || lv_count
                        );

            UTL_FILE.fflush (l_file_handle);
            UTL_FILE.fclose (l_file_handle);
            UTL_FILE.FRENAME(l_file_dir, l_file_name, l_file_dir, l_file_name1, TRUE);
            xxom_consgn_comm_ftp_pkg.add_new_file(l_file_name1); -- Provide actual file name as parameter.

            COMMIT;

   END LOOP; -- Division

   --xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends actual data file to surgisoft using sFTP.
   xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
   --xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.

   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode Parameter');
        dbms_output.put_line('Invalid Mode Parameter');
      WHEN UTL_FILE.invalid_path
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Location');
         dbms_output.put_line('Invalid File Location');
      WHEN UTL_FILE.invalid_filehandle
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Filehandle');
         dbms_output.put_line('Invalid Filehandle');
      WHEN UTL_FILE.invalid_operation
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Operation');
         dbms_output.put_line('Invalid Operation');
      WHEN UTL_FILE.read_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error');
         dbms_output.put_line('Read Error');
      WHEN UTL_FILE.internal_error
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Internal Error');
         dbms_output.put_line('Internal Error');
      WHEN UTL_FILE.charsetmismatch
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Opened With FOPEN_NCHAR But Later I/O Inconsistent');
         dbms_output.put_line(
                 'Opened With FOPEN_NCHAR But Later I/O Inconsistent'
                );
      WHEN UTL_FILE.file_open
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Already Opened');
         dbms_output.put_line('File Already Opened');
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Line Size Exceeds 32K');
         dbms_output.put_line('Line Size Exceeds 32K');
      WHEN UTL_FILE.invalid_filename
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Name');
         dbms_output.put_line('Invalid File Name');
      WHEN UTL_FILE.access_denied
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Access Denied By');
        dbms_output.put_line('File Access Denied By');
      WHEN UTL_FILE.invalid_offset
      THEN
         fnd_file.put_line (fnd_file.LOG, 'FSEEK Param Less Than 0');
        dbms_output.put_line('FSEEK Param Less Than 0');
      WHEN OTHERS
      THEN
        fnd_file.put_line (fnd_file.LOG, 'Unknown UTL_FILE Error');
         dbms_output.put_line('Unknown UTL_FILE Error');
       --  retcode:= 2;
       --  errbuf:= TO_CHAR(sqlcode)||'-'||SUBSTR (SQLERRM, 1, 255);
   END INTG_INV_ISSUE_EXP_PRC ;
END XXOM_MAT_ISS_PKG;
/
