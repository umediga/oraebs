DROP PACKAGE BODY APPS.XX_INV_CROSS_REF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_CROSS_REF_PKG" AS
 /* $Header: XXINTGBOMCNV.pkb 1.0.0 2012/10/18 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 18-OCT-2012
  -- Filename       : XXINVCROSSREF.pkb
  -- Description    : Package body for Item cross reference conversion

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 18-OCT-2012   1.0       Partha S Mohanty    Initial development.
--====================================================================================
   g_request_id NUMBER := fnd_profile.VALUE('CONC_REQUEST_ID');

   g_user_id NUMBER := fnd_global.user_id; --fnd_profile.VALUE('USER_ID');

   g_resp_id NUMBER := fnd_profile.VALUE('RESP_ID');

   x_batch_id       VARCHAR2(50) := NULL;
   --- mark_records_for_processing
   PROCEDURE mark_records_for_processing
        IS
        PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
        x_batch_id := TO_CHAR(SYSDATE,'DDMONRRRR_HHMISS');

        fnd_file.put_line(fnd_file.log,'Batch Id' ||x_batch_id);

        UPDATE xx_inv_cross_ref_stg -- BOM Header Staging
                      SET request_id = g_request_id,
                        error_flag = 'N',
                    record_status = G_REC_NEW,
                    record_number = XXINVCROSSREF_S.NEXTVAL,
                    error_message = NULL,
                    batch_id = x_batch_id,
                    last_update_date = sysdate,
                    last_updated_by = g_user_id,
                    creation_date = sysdate,
                    created_by = g_user_id,
                    last_update_login = g_user_id
                   WHERE batch_id is NULL;
       COMMIT;
   END mark_records_for_processing;
  -- Print error message

   PROCEDURE print_error_message
    IS

    x_total_cnt NUMBER :=0;
    x_proc_cnt  NUMBER :=0;
    x_error_cnt NUMBER :=0;

    CURSOR crossref_error
      IS
      SELECT * from xx_inv_cross_ref_stg
      WHERE batch_id = x_batch_id
        AND error_flag = 'Y';

     CURSOR crossref_total_cnt
      IS
      SELECT count(1) from xx_inv_cross_ref_stg
      WHERE batch_id = x_batch_id;


     CURSOR crossref_proc_cnt
      IS
      SELECT count(1) from xx_inv_cross_ref_stg
      WHERE batch_id = x_batch_id
        AND RECORD_STATUS = 'PROCESSED';

     CURSOR crossref_err_cnt
      IS
      SELECT count(1) from xx_inv_cross_ref_stg
      WHERE batch_id = x_batch_id
        AND error_flag = 'Y';

    BEGIN

     OPEN crossref_total_cnt;
		 FETCH crossref_total_cnt INTO x_total_cnt;
		 CLOSE crossref_total_cnt;

     OPEN crossref_proc_cnt;
		 FETCH crossref_proc_cnt INTO x_proc_cnt;
		 CLOSE crossref_proc_cnt;

     OPEN crossref_err_cnt;
		 FETCH crossref_err_cnt INTO x_error_cnt;
		 CLOSE crossref_err_cnt;

     fnd_file.put_line(fnd_file.OUTPUT,'                                   ITEM CROSS REFERENCE ERROR LOG');
     fnd_file.put_line(fnd_file.OUTPUT,'' );
     fnd_file.put_line(fnd_file.OUTPUT,'BATCH ID:'|| x_batch_id );
     fnd_file.put_line(fnd_file.OUTPUT,'' );
     fnd_file.put_line(fnd_file.OUTPUT,'Total Record           : '|| x_total_cnt );
     fnd_file.put_line(fnd_file.OUTPUT,'Total Record processed : '|| x_proc_cnt );
     fnd_file.put_line(fnd_file.OUTPUT,'Total Error  Record    : '|| x_error_cnt );
     fnd_file.put_line(fnd_file.OUTPUT,'' );
     fnd_file.put_line(fnd_file.OUTPUT,'' );
     fnd_file.put_line(fnd_file.OUTPUT,'====================================================================================================' );
     fnd_file.put_line(fnd_file.OUTPUT,'PART_NUMBER                    REC_NUM     RECORD_STATUS  ERROR_MESSAGE');
     fnd_file.put_line(fnd_file.OUTPUT,'====================================================================================================' );
     fnd_file.put_line(fnd_file.OUTPUT,'' );
     FOR crossref_error_rec in crossref_error
      LOOP
       fnd_file.put_line(fnd_file.OUTPUT,  RPAD(crossref_error_rec.part_number,31)||
                                           RPAD(crossref_error_rec.RECORD_NUMBER,12)||
                                           RPAD(crossref_error_rec.RECORD_STATUS,15)||
                                           crossref_error_rec.ERROR_MESSAGE);
       END LOOP;
    END print_error_message;
   -- main
   PROCEDURE main( errbuf            OUT VARCHAR2
                   ,retcode          OUT VARCHAR2
                   ,p_cross_ref_type IN VARCHAR2
                ) IS
   /*-------------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
   Purpose          :   This is the main procedure which subsequently calls all other procedure.
   -------------------------------------------------------------------------------------------------------------------------*/
     x_ctr                  NUMBER :=  0;
     x_cross_reference_id   NUMBER;
     x_cross_reference      VARCHAR2(255);
     x_cross_reference_type VARCHAR2(25);
     x_org_independent_flag VARCHAR2(1);
     x_organziation_id      NUMBER;
     x_inventory_item_id    NUMBER;
     x_err_flag             VARCHAR2(1) := 'N';
     x_rec_status           VARCHAR2(10);
     x_processed            NUMBER(15) := 0;
     x_ctr_xref             NUMBER(15) := NULL;
     x_error_message        VARCHAR2(4000);
     x_err_msg              VARCHAR2(4000);
     x_trans_type           VARCHAR2(50);
     x_XRef_Tbl             MTL_CROSS_REFERENCES_PUB.XRef_Tbl_Type;
     x_ret_status           VARCHAR2(100);
     x_msg_count            NUMBER;
     x_msg_list             Error_Handler.Error_Tbl_Type;
     l_cnt                  NUMBER := 0;

     e_crossref_id          EXCEPTION;
     -- cross reference cursor
     CURSOR c_xx_crossref_cur
           IS
         SELECT *
           FROM xx_inv_cross_ref_stg
         WHERE batch_id = x_batch_id;

      CURSOR c_crossref_val_cur
           IS
         SELECT *
           FROM xx_inv_cross_ref_stg
         WHERE batch_id = x_batch_id
               AND error_flag = 'N';
   BEGIN
    fnd_file.put_line(fnd_file.log,'Start Processing');

    mark_records_for_processing;
    t_crossref_rec.DELETE;
    FOR crossref_rec IN c_xx_crossref_cur
     LOOP
        x_ctr := x_ctr + 1;
        x_err_flag := 'N';
        x_inventory_item_id := NULL;
        x_rec_status := 'VALID';
        x_processed := x_processed + 1;
        x_cross_reference_id   :=NULL;
        x_cross_reference      :=NULL;
        x_cross_reference_type :=NULL;
        x_org_independent_flag :=NULL;
        x_trans_type           :=NULL;

        -- Validate Inventory Item Id
        BEGIN
          SELECT msi.inventory_item_id
             INTO x_inventory_item_id
           FROM mtl_system_items_b msi
           WHERE msi.segment1 = crossref_rec.part_number
             AND rownum=1;
        EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Inventory_item_id not found');
              x_err_flag := 'Y';
              x_err_msg := 'Inventory_item_id not found';
        END;
        fnd_file.put_line(fnd_file.log,'Inventory_item_id for item_number : '||crossref_rec.part_number||'='||x_inventory_item_id);
        -- Derive different mandatory columns

       IF crossref_rec.external_part_num IS NULL THEN

         BEGIN
            SELECT cross_reference,cross_reference_id,cross_reference_type,org_independent_flag
              INTO x_cross_reference,x_cross_reference_id,x_cross_reference_type,x_org_independent_flag
              FROM mtl_cross_references_v mcr
              WHERE mcr.inventory_item_id = x_inventory_item_id
                AND mcr.cross_reference_type = p_cross_ref_type;
              fnd_file.put_line(fnd_file.log,'For part_num: '||crossref_rec.part_number||' '||
                                             'cross_reference: '|| x_cross_reference||' '||
                                             'cross_reference_id: '||x_cross_reference_id||' '||
                                             'cross_reference_type: '||x_cross_reference_type||' '||
                                             'org_independent_flag: '||x_org_independent_flag);
              x_trans_type := 'UPDATE';
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Mandatory column values not found');
              x_cross_reference_id   := NULL;
              x_cross_reference      := NULL;
              x_cross_reference_type := NULL;
              x_org_independent_flag := NULL;
              x_trans_type := NULL;
              x_err_flag := 'Y';
              x_err_msg := 'Mandatory column values not found';
          END;
       ELSIF crossref_rec.external_part_num IS NOT NULL THEN
          BEGIN
            SELECT cross_reference,cross_reference_id,cross_reference_type,org_independent_flag
              INTO x_cross_reference,x_cross_reference_id,x_cross_reference_type,x_org_independent_flag
              FROM mtl_cross_references_v mcr
              WHERE mcr.inventory_item_id = x_inventory_item_id
                AND mcr.cross_reference_type = p_cross_ref_type
                AND mcr.cross_reference = crossref_rec.external_part_num;
              fnd_file.put_line(fnd_file.log,'For part_num (where external_part_num IS NOT NULL): '||crossref_rec.part_number||' '||
                                             'cross_reference: '|| x_cross_reference||' '||
                                             'cross_reference_id: '||x_cross_reference_id||' '||
                                             'cross_reference_type: '||x_cross_reference_type||' '||
                                             'org_independent_flag: '||x_org_independent_flag);
              x_trans_type := 'UPDATE';
          EXCEPTION
            WHEN OTHERS THEN
              x_trans_type := 'CREATE';
              x_cross_reference_id   := NULL;
              x_cross_reference      := crossref_rec.external_part_num;
              x_cross_reference_type := p_cross_ref_type;
              x_org_independent_flag := 'Y';
              fnd_file.put_line(fnd_file.log,'New cross_refrence CREATED for  part_num : '||crossref_rec.part_number);
          END;
       END IF;

       IF x_err_flag = 'Y' THEN
          x_rec_status := 'VAL_ERROR';
       END IF;

       t_crossref_rec(x_ctr).batch_id := crossref_rec.batch_id;
       t_crossref_rec(x_ctr).record_number := crossref_rec.record_number;
       t_crossref_rec(x_ctr).record_status := x_rec_status;
       t_crossref_rec(x_ctr).error_flag := x_err_flag;
       t_crossref_rec(x_ctr).error_message := x_err_msg;
       t_crossref_rec(x_ctr).part_number := crossref_rec.part_number;
       --t_crossref_rec(x_ctr).organization_id := x_organziation_id;
       t_crossref_rec(x_ctr).cross_reference_id := x_cross_reference_id;
       t_crossref_rec(x_ctr).inventory_item_id := x_inventory_item_id;
       t_crossref_rec(x_ctr).cross_reference_type := x_cross_reference_type;
       t_crossref_rec(x_ctr).cross_reference := x_cross_reference;
       t_crossref_rec(x_ctr).org_independent_flag := x_org_independent_flag;
       t_crossref_rec(x_ctr).transaction_type := x_trans_type;
       -- Update staging table
       IF x_processed > G_BATCH_SIZE THEN
         FORALL i IN t_crossref_rec.FIRST .. t_crossref_rec.LAST
               UPDATE xx_inv_cross_ref_stg
                  SET record_status = t_crossref_rec(i).record_status,
                      organization_id = t_crossref_rec(i).organization_id,
                      cross_reference_id = t_crossref_rec(i).cross_reference_id,
                      inventory_item_id = t_crossref_rec(i).inventory_item_id,
                      error_flag = t_crossref_rec(i).error_flag,
                      error_message = t_crossref_rec(i).error_message,
                      cross_reference_type = t_crossref_rec(i).cross_reference_type,
                      cross_reference = t_crossref_rec(i).cross_reference,
                      org_independent_flag = t_crossref_rec(i).org_independent_flag,
                      transaction_type =  t_crossref_rec(i).transaction_type
                   WHERE batch_id = t_crossref_rec(i).batch_id
                         AND record_number = t_crossref_rec(i).record_number
                         AND part_number =  t_crossref_rec(i).part_number;

        t_crossref_rec.DELETE;
        x_ctr :=0;
        x_processed :=0;
       END IF;
   END LOOP;

      -- Update staging table for more than 10000 records

        FORALL i IN t_crossref_rec.FIRST .. t_crossref_rec.LAST
               UPDATE xx_inv_cross_ref_stg
                  SET record_status = t_crossref_rec(i).record_status,
                      organization_id = t_crossref_rec(i).organization_id,
                      cross_reference_id = t_crossref_rec(i).cross_reference_id,
                      inventory_item_id = t_crossref_rec(i).inventory_item_id,
                      error_flag = t_crossref_rec(i).error_flag,
                      error_message = t_crossref_rec(i).error_message,
                      cross_reference_type = t_crossref_rec(i).cross_reference_type,
                      cross_reference = t_crossref_rec(i).cross_reference,
                      org_independent_flag = t_crossref_rec(i).org_independent_flag,
                      transaction_type =  t_crossref_rec(i).transaction_type
                   WHERE batch_id = t_crossref_rec(i).batch_id
                         AND record_number = t_crossref_rec(i).record_number
                         AND part_number =  t_crossref_rec(i).part_number;

      COMMIT;
      t_crossref_rec.DELETE;


     -- Start processing for API
     x_ctr := 1;
     FOR crossref_val_rec IN c_crossref_val_cur
     LOOP
     BEGIN
       x_ctr_xref := 1;
       x_XRef_Tbl(x_ctr_xref).transaction_type := crossref_val_rec.transaction_type;
       x_XRef_Tbl(x_ctr_xref).cross_reference := crossref_val_rec.cross_reference;
       x_XRef_Tbl(x_ctr_xref).cross_reference_id := crossref_val_rec.cross_reference_id;
       x_XRef_Tbl(x_ctr_xref).cross_reference_type := crossref_val_rec.cross_reference_type;
       x_XRef_Tbl(x_ctr_xref).inventory_item_id := crossref_val_rec.inventory_item_id;
       x_XRef_Tbl(x_ctr_xref).description := crossref_val_rec.description;
       x_XRef_Tbl(x_ctr_xref).organization_id := NULL ;
       x_XRef_Tbl(x_ctr_xref).org_independent_flag := crossref_val_rec.org_independent_flag;
       x_XRef_Tbl(x_ctr_xref).attribute_category := crossref_val_rec.attribute_category;
       x_XRef_Tbl(x_ctr_xref).attribute1 := crossref_val_rec.substrate_item_number;
       x_XRef_Tbl(x_ctr_xref).attribute2 := crossref_val_rec.orcl_label_format;
       x_XRef_Tbl(x_ctr_xref).attribute3 := crossref_val_rec.lft_template;
       x_XRef_Tbl(x_ctr_xref).attribute4 := crossref_val_rec.artwork_id;
       x_XRef_Tbl(x_ctr_xref).attribute5 := crossref_val_rec.hibc_uom;
       x_XRef_Tbl(x_ctr_xref).attribute6 := crossref_val_rec.hibc_format;
       x_XRef_Tbl(x_ctr_xref).attribute7 := crossref_val_rec.hibc_qty;
       x_XRef_Tbl(x_ctr_xref).attribute8 := crossref_val_rec.hibc_co_code;
       x_XRef_Tbl(x_ctr_xref).attribute9 := crossref_val_rec.label_rev;
       x_XRef_Tbl(x_ctr_xref).attribute10 := crossref_val_rec.marking;
       x_XRef_Tbl(x_ctr_xref).attribute11 := crossref_val_rec.finish;
       x_XRef_Tbl(x_ctr_xref).attribute12 := crossref_val_rec.pkg;
       x_XRef_Tbl(x_ctr_xref).attribute13 := crossref_val_rec.ifu;
       x_XRef_Tbl(x_ctr_xref).attribute14 := crossref_val_rec.hibc_exp_flag;
       x_XRef_Tbl(x_ctr_xref).attribute15 := crossref_val_rec.attribute15;

       -- call API mtl_cross_references_pub


       mtl_cross_references_pub.process_xref
                  (p_api_version => 1.0,
                   p_init_msg_list => fnd_api.g_true,
                   p_commit => fnd_api.g_false,
                   p_xref_tbl => x_XRef_Tbl,
                   x_return_status => x_ret_status,
                   x_msg_count => x_msg_count,
                   x_message_list => x_msg_list
                 );

      IF (x_ret_status = fnd_api.g_ret_sts_success)
            THEN
           t_crossref_rec(x_ctr).batch_id := crossref_val_rec.batch_id;
           t_crossref_rec(x_ctr).record_number := crossref_val_rec.record_number;
           t_crossref_rec(x_ctr).record_status := 'PROCESSED';
           t_crossref_rec(x_ctr).error_flag := 'N';
           x_ctr := x_ctr + 1;
           COMMIT;
       ELSE
         --Error_Handler.GET_MESSAGE_LIST(x_message_list=>x_msg_list);
         FOR i IN 1 .. x_msg_list.COUNT
           LOOP
            fnd_file.put_line(fnd_file.log,x_msg_list(i).MESSAGE_TEXT);
            x_error_message := SUBSTR(x_msg_list(i).MESSAGE_TEXT,1,4000);
            t_crossref_rec(x_ctr).batch_id := crossref_val_rec.batch_id;
            t_crossref_rec(x_ctr).record_number := crossref_val_rec.record_number;
            t_crossref_rec(x_ctr).record_status := 'API_ERROR';
            t_crossref_rec(x_ctr).error_flag := 'Y';
            t_crossref_rec(x_ctr).error_message := x_error_message;
            x_ctr := x_ctr + 1;
          END LOOP;
     END IF;

     x_XRef_Tbl.DELETE;
     EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log,'Inside API call Error : '||SQLERRM);
         x_XRef_Tbl.DELETE;
     END;
     END LOOP;
          -- Update staging table for error message

       FORALL i IN t_crossref_rec.FIRST .. t_crossref_rec.LAST
               UPDATE xx_inv_cross_ref_stg
                  SET record_status = t_crossref_rec(i).record_status,
                      error_message = t_crossref_rec(i).error_message,
                      error_flag = t_crossref_rec(i).error_flag
                   WHERE batch_id = t_crossref_rec(i).batch_id
                         AND record_number = t_crossref_rec(i).record_number;
      COMMIT;
      t_crossref_rec.DELETE;

      print_error_message;
   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.log,'Major error please check :'||SQLERRM);
           retcode := '1';

 END main;

END xx_inv_cross_ref_pkg;
/
