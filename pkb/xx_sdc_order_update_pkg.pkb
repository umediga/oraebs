DROP PACKAGE BODY APPS.XX_SDC_ORDER_UPDATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_ORDER_UPDATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Renjith
 Creation Date : 19-FEBR-2014
 File Name     : XX_SDC_ORDER_UPDATE_PKG.pkb
 Description   : This script creates the specification of the package
		 xx_ont_so_acknowledge_pkg
 Change History:
 Date        Version Name          Remarks
 ----------- ------- ------------- -----------------------------------
 19-FEB-2014 1.0     Renjith       Initial Development
 26-May-2014 1.1     Renjith       filter inactive customer
 22-Sep-2014 1.2     Bedabrata     Commented out Logic for US customers for wave2
*/
----------------------------------------------------------------------
x_user_id          NUMBER       := FND_GLOBAL.USER_ID;
x_resp_id          NUMBER       := FND_GLOBAL.RESP_ID;
x_resp_appl_id     NUMBER       := FND_GLOBAL.RESP_APPL_ID;
x_login_id         NUMBER       := FND_GLOBAL.LOGIN_ID;
x_request_id       NUMBER       := FND_GLOBAL.CONC_REQUEST_ID;

x_publish_system   VARCHAR2(80) := 'EBS';
x_target_system    VARCHAR2(280):= 'SFDC';
x_status_flag      VARCHAR(10)  := 'NEW';
x_batch_size       NUMBER := 50;
x_batch_size_lmt   NUMBER := 200;

----------------------------------------------------------------------

PROCEDURE xx_raise_publish_event ( p_request_id NUMBER
                                  ,p_batch_id   NUMBER
                                  ,p_event_data IN CLOB)
IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   x_event_parameter_list   wf_parameter_list_t;
   x_event_name             VARCHAR2 (100)      := 'xxintg.oracle.apps.sfdc.orderrma.publish';
   x_event_key              VARCHAR2 (100)      := NULL;
BEGIN
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start xx_raise_publish_event Req Id ->'||p_request_id);
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start xx_raise_publish_event Batch Id ->'||p_batch_id);
   x_event_parameter_list := wf_parameter_list_t ( WF_PARAMETER_T ('REQUEST_ID', p_request_id));


   wf_event.raise ( p_event_name   => x_event_name
                   ,p_event_key    => x_event_key
                   ,p_event_data   => p_event_data
                   ,p_parameters   => x_event_parameter_list);
   COMMIT;

   INSERT INTO xx_sdc_order_out_log (send_date,request_id,msg)
   VALUES (sysdate,p_request_id,p_event_data);

   COMMIT;

   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End xx_raise_publish_event');
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'xx_raise_publish_event -> Exception while raising BE'||SQLERRM);
END xx_raise_publish_event;

----------------------------------------------------------------------

PROCEDURE  process_param_value
IS
BEGIN
  xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXSFDCOUTBOUNDINTF'
                                             ,p_param_name      => 'ORDER_BATCH_SIZE'
                                             ,x_param_value     =>  x_batch_size);

  xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXSFDCOUTBOUNDINTF'
                                             ,p_param_name      => 'CUSTOMER_BATCH_SIZE'
                                             ,x_param_value     =>  x_batch_size_lmt);

END process_param_value;
----------------------------------------------------------------------

PROCEDURE  send_batch (p_type       VARCHAR2
                      ,p_request_id NUMBER
                      ,p_batch_id   NUMBER )
IS
 CURSOR c_hdr_batch_new
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_head_control_tbl
   WHERE request_id = p_request_id
     AND publish_batch_id = p_batch_id;

 CURSOR c_line_batch_new
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_line_control_tbl
   WHERE request_id = p_request_id
     AND master_batch_id = p_batch_id;

 CURSOR c_del_batch_new
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_del_control_tbl
   WHERE request_id = p_request_id
     AND master_batch_id = p_batch_id;

 /*CURSOR c_hdr_batch_re
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_head_control_tbl
   WHERE status_flag = 'NEW';

 CURSOR c_line_batch_re
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_line_control_tbl
   WHERE status_flag = 'NEW';

 CURSOR c_del_batch_re
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_del_control_tbl
   WHERE status_flag = 'NEW';*/

  x_parameter_list   wf_parameter_list_t;
  x_event_data       CLOB;
  x_text             VARCHAR2(3000);

BEGIN
   --IF p_type IN ('New','Initial') THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start send batch Req Id ->'||p_request_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start send batch Batch Id ->'||p_batch_id);
      DBMS_LOB.CREATETEMPORARY( x_event_data
                            ,FALSE
                            ,dbms_lob.CALL);

      x_text := '<ns1:process xmlns:ns1="http://xmlns.oracle.com/SyncSalesOrderListEbizSFDCController/SyncSalesOrderListEbizSFDCController">';
      DBMS_LOB.WRITEAPPEND( x_event_data
                        ,length(x_text)
                        ,x_text);

      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderHeader>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_hdr_batch IN c_hdr_batch_new LOOP
                  x_text := NULL;
                  x_text := '<ns1:header_publish_batch_id>';
                  x_text := x_text ||rec_hdr_batch.publish_batch_id;
                  x_text := x_text || '</ns1:header_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderHeader>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderLine>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_line_batch IN c_line_batch_new LOOP
                  x_text := NULL;
                  x_text := '<ns1:line_publish_batch_id>';
                  x_text := x_text ||rec_line_batch.publish_batch_id;
                  x_text := x_text || '</ns1:line_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderLine>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderDelivery>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_del_batch IN c_del_batch_new LOOP
                  x_text := NULL;
                  x_text := '<ns1:delivery_publish_batch_id>';
                  x_text := x_text ||rec_del_batch.publish_batch_id;
                  x_text := x_text || '</ns1:delivery_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderDelivery>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:process>';

      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);

      xx_raise_publish_event(p_request_id,p_batch_id,x_event_data);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End send batch');
   /*ELSE
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start send batch ->'||p_request_id);
      DBMS_LOB.CREATETEMPORARY( x_event_data
                            ,FALSE
                            ,dbms_lob.CALL);

      x_text := '<ns1:process xmlns:ns1="http://xmlns.oracle.com/SyncSalesOrderListEbizSFDCController/SyncSalesOrderListEbizSFDCController">';
      DBMS_LOB.WRITEAPPEND( x_event_data
                        ,length(x_text)
                        ,x_text);

      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderHeader>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_hdr_batch IN c_hdr_batch_re LOOP
                  x_text := NULL;
                  x_text := '<ns1:header_publish_batch_id>';
                  x_text := x_text ||rec_hdr_batch.publish_batch_id;
                  x_text := x_text || '</ns1:header_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderHeader>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderLine>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_line_batch IN c_line_batch_re LOOP
                  x_text := NULL;
                  x_text := '<ns1:line_publish_batch_id>';
                  x_text := x_text ||rec_line_batch.publish_batch_id;
                  x_text := x_text || '</ns1:line_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderLine>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '<ns1:SalesOrderDelivery>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
              -- -------------------------------------------------------
              FOR rec_del_batch IN c_del_batch_re LOOP
                  x_text := NULL;
                  x_text := '<ns1:delivery_publish_batch_id>';
                  x_text := x_text ||rec_del_batch.publish_batch_id;
                  x_text := x_text || '</ns1:delivery_publish_batch_id>';
                  DBMS_LOB.WRITEAPPEND( x_event_data
                                       ,length(x_text)
                                       ,x_text);
              END LOOP;
              -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:SalesOrderDelivery>';
      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);
      -- -------------------------------------------------------
      x_text := NULL;
      x_text := '</ns1:process>';

      DBMS_LOB.WRITEAPPEND( x_event_data
                           ,length(x_text)
                           ,x_text);

      xx_raise_publish_event(p_request_id,x_event_data);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End send batch');

   END IF;*/
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'send_batch -> Exception while sending batch details'||SQLERRM);
END send_batch;

----------------------------------------------------------------------
PROCEDURE  generate_batch (p_type VARCHAR2, p_request_id NUMBER)
IS
 CURSOR c_hdr_batch_new
  IS
  SELECT record_id,header_id
    FROM xx_om_sfdc_head_control_tbl
   WHERE request_id = p_request_id
     AND status_flag = 'NEW'
   ORDER BY header_id;

 CURSOR c_line_batch_new(p_header_id NUMBER)
  IS
  SELECT record_id
    FROM xx_om_sfdc_line_control_tbl
   WHERE request_id = p_request_id
     AND header_id = p_header_id
     AND status_flag = 'NEW'
   ORDER BY header_id, line_id;

 CURSOR c_dlvr_batch_new(p_header_id NUMBER)
  IS
  SELECT record_id
    FROM xx_om_sfdc_del_control_tbl
   WHERE request_id = p_request_id
     AND header_id = p_header_id
     AND status_flag = 'NEW'
   ORDER BY header_id, line_id, delivery_detail_id;

 CURSOR c_line_batch_err
  IS
  SELECT lne.record_id
    FROM xx_om_sfdc_line_control_tbl lne
   WHERE lne.request_id = p_request_id
     AND lne.status_flag = 'NEW'
     --AND publish_batch_id IS NULL
     AND NOT EXISTS ( SELECT hdr.header_id
                        FROM xx_om_sfdc_head_control_tbl hdr
                       WHERE hdr.header_id = lne.header_id
                         AND hdr.request_id = p_request_id )
   ORDER BY header_id, line_id;

 CURSOR c_dlvr_batch_err
  IS
  SELECT dlr.record_id
    FROM xx_om_sfdc_del_control_tbl dlr
   WHERE dlr.request_id = p_request_id
     AND dlr.status_flag = 'NEW'
     --AND publish_batch_id IS NULL
     AND NOT EXISTS ( SELECT hdr.header_id
                        FROM xx_om_sfdc_head_control_tbl hdr
                       WHERE hdr.header_id = dlr.header_id
                         AND hdr.request_id = p_request_id )
   ORDER BY header_id, line_id, delivery_detail_id;

 CURSOR c_hdr_batch_send
  IS
  SELECT DISTINCT publish_batch_id batch_id
    FROM xx_om_sfdc_head_control_tbl
   WHERE request_id = p_request_id
     AND status_flag = 'NEW'
   ORDER BY publish_batch_id;

 --Header already processed
 CURSOR c_line_batch_send
  IS
  SELECT DISTINCT lne.master_batch_id batch_id
    FROM xx_om_sfdc_line_control_tbl lne
   WHERE lne.request_id = p_request_id
     AND lne.status_flag = 'NEW'
     AND NOT EXISTS ( SELECT hdr.publish_batch_id
                        FROM xx_om_sfdc_head_control_tbl hdr
                       WHERE hdr.publish_batch_id = lne.master_batch_id
                         AND hdr.request_id = p_request_id )
   ORDER BY master_batch_id;

 --Header already processed
 CURSOR c_dlvr_batch_send
  IS
  SELECT DISTINCT dlr.master_batch_id batch_id
    FROM xx_om_sfdc_del_control_tbl dlr
   WHERE dlr.request_id = p_request_id
     AND dlr.status_flag = 'NEW'
     AND NOT EXISTS ( SELECT hdr.publish_batch_id
                        FROM xx_om_sfdc_head_control_tbl hdr
                       WHERE hdr.publish_batch_id = dlr.master_batch_id
                         AND hdr.request_id = p_request_id )
   ORDER BY master_batch_id;


  x_counter          NUMBER := 0;
  x_lcnt             NUMBER := 0;
  x_dcnt             NUMBER := 0;
  x_batch_id         NUMBER := 0;
  x_batch_id_ln      NUMBER := 0;
  x_batch_id_dn      NUMBER := 0;
  x_rec_hcnt      NUMBER := 0;
  x_rec_lcnt      NUMBER := 0;
  x_rec_dcnt      NUMBER := 0;
  xx_head_control_tab    xx_head_control_tab_type;
  xx_line_control_tab    xx_line_control_tab_type;
  xx_delv_control_tab    xx_delv_control_tab_type;

BEGIN
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start generate batch ->'||p_request_id);
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Batch generation: Main Loop');
   --Header loop
   FOR r_hdr_batch_new IN c_hdr_batch_new
   LOOP
      x_rec_hcnt := x_rec_hcnt + 1;
      IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Header Batch Id: '||x_batch_id||' Counter: '||x_counter);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Line Batch Id: '||x_batch_id_ln||' Counter: '||x_lcnt);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Delivery Batch Id: '||x_batch_id_dn||' Counter: '||x_dcnt);
         x_lcnt := 0;
         x_dcnt := 0;
         x_batch_id      := xx_sdc_order_head_batch_s.nextval;
         x_counter       := 1;
      ELSE
         x_counter := x_counter + 1;
      END IF;

      xx_head_control_tab(x_rec_hcnt).publish_batch_id := x_batch_id;
      xx_head_control_tab(x_rec_hcnt).record_id := r_hdr_batch_new.record_id;

      --Line Batch Control
      FOR r_line_batch_new IN c_line_batch_new(r_hdr_batch_new.header_id)
      LOOP
         x_rec_lcnt := x_rec_lcnt + 1;
         IF (NVL(x_lcnt,0) = x_batch_size_lmt) OR (x_lcnt = 0) THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Line Batch Id: '||x_batch_id_ln||' Counter: '||x_lcnt);
	    x_batch_id_ln := xx_sdc_order_line_batch_s.nextval;
	    x_lcnt       := 1;
	 ELSE
	    x_lcnt := x_lcnt + 1;
         END IF;

          xx_line_control_tab(x_rec_lcnt).publish_batch_id := x_batch_id_ln;
          xx_line_control_tab(x_rec_lcnt).record_id := r_line_batch_new.record_id;
          xx_line_control_tab(x_rec_lcnt).master_batch_id := x_batch_id;
          xx_line_control_tab(x_rec_lcnt).status_flag := 'NEW';
       END LOOP;

      --Delivery batch control
      FOR r_dlvr_batch_new IN c_dlvr_batch_new(r_hdr_batch_new.header_id)
      LOOP
         x_rec_dcnt := x_rec_dcnt + 1;
         IF (NVL(x_dcnt,0) = x_batch_size_lmt) OR (x_dcnt = 0) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Delivery Batch Id: '||x_batch_id_dn||' Counter: '||x_dcnt);
	    x_batch_id_dn := xx_sdc_order_del_batch_s.nextval;
	    x_dcnt       := 1;
	 ELSE
	    x_dcnt := x_dcnt + 1;
         END IF;

          xx_delv_control_tab(x_rec_dcnt).publish_batch_id := x_batch_id_dn;
          xx_delv_control_tab(x_rec_dcnt).record_id := r_dlvr_batch_new.record_id;
          xx_delv_control_tab(x_rec_dcnt).master_batch_id := x_batch_id;
          xx_delv_control_tab(x_rec_dcnt).status_flag := 'NEW';
       END LOOP;
   END LOOP;
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update batch data to control tables');
   --Update control tables
   BEGIN
     --Update header control table
      IF xx_head_control_tab.COUNT > 0 THEN
         FORALL i_hdr IN 1 .. xx_head_control_tab.COUNT
            UPDATE xx_om_sfdc_head_control_tbl
               SET publish_batch_id = xx_head_control_tab(i_hdr).publish_batch_id
             WHERE record_id = xx_head_control_tab(i_hdr).record_id;
         xx_head_control_tab.DELETE;
      END IF;
      --Update line control table
      IF xx_line_control_tab.COUNT > 0 THEN
         FORALL i_lne IN 1 .. xx_line_control_tab.COUNT
            UPDATE xx_om_sfdc_line_control_tbl
               SET publish_batch_id = xx_line_control_tab(i_lne).publish_batch_id
                  ,master_batch_id = xx_line_control_tab(i_lne).master_batch_id
             WHERE record_id = xx_line_control_tab(i_lne).record_id
               AND status_flag = xx_line_control_tab(i_lne).status_flag;
         xx_line_control_tab.DELETE;
      END IF;
      --Update delivery control table
      IF xx_delv_control_tab.COUNT > 0 THEN
         FORALL i_dlv IN 1 .. xx_delv_control_tab.COUNT
            UPDATE xx_om_sfdc_del_control_tbl
               SET publish_batch_id = xx_delv_control_tab(i_dlv).publish_batch_id
                  ,master_batch_id = xx_delv_control_tab(i_dlv).master_batch_id
             WHERE record_id = xx_delv_control_tab(i_dlv).record_id
               AND status_flag = xx_delv_control_tab(i_dlv).status_flag;
         xx_delv_control_tab.DELETE;
      END IF;
      COMMIT;
      --send_batch (p_type, p_request_id, x_batch_id);
   END;

   --To process only lines and deliveries for those header is already success
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Batch Generation: To process only lines and deliveries for those header is already success');
   BEGIN
      x_lcnt := 0;
      x_dcnt := 0;
      x_batch_id := 0;
      x_batch_id_ln := 0;
      x_batch_id_dn := 0;
      x_rec_lcnt := 0;
      x_rec_dcnt := 0;
      x_counter := 0;
      --Line Batch Control
      FOR r_line_batch_err IN c_line_batch_err
      LOOP
         x_rec_lcnt := x_rec_lcnt + 1;
         IF (x_batch_id = 0) OR (NVL(x_counter,0) = x_batch_size) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Header Batch Id: '||x_batch_id||' Counter: '||x_counter);
            x_batch_id      := xx_sdc_order_head_batch_s.nextval;
            x_counter := 0;
         END IF;
         IF (NVL(x_lcnt,0) = x_batch_size_lmt) OR (x_lcnt = 0) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Line Batch Id: '||x_batch_id_ln||' Counter: '||x_lcnt);
	    x_batch_id_ln := xx_sdc_order_line_batch_s.nextval;
	    x_lcnt       := 1;
	    x_counter := x_counter + 1;
	 ELSE
	    x_lcnt := x_lcnt + 1;
         END IF;

          xx_line_control_tab(x_rec_lcnt).publish_batch_id := x_batch_id_ln;
          xx_line_control_tab(x_rec_lcnt).record_id := r_line_batch_err.record_id;
          xx_line_control_tab(x_rec_lcnt).master_batch_id := x_batch_id;
          xx_line_control_tab(x_rec_lcnt).status_flag := 'NEW';
       END LOOP;

      x_counter := 0;
      x_batch_id := 0;
      --Delivery batch control
      FOR r_dlvr_batch_err IN c_dlvr_batch_err
      LOOP
         x_rec_dcnt := x_rec_dcnt + 1;
         IF (x_batch_id = 0) OR (NVL(x_counter,0) = x_batch_size) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Header Batch Id: '||x_batch_id||' Counter: '||x_counter);
            x_batch_id      := xx_sdc_order_head_batch_s.nextval;
            x_counter := 0;
         END IF;
         IF (NVL(x_dcnt,0) = x_batch_size_lmt) OR (x_dcnt = 0) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Delivery Batch Id: '||x_batch_id_dn||' Counter: '||x_dcnt);
	    x_batch_id_dn := xx_sdc_order_del_batch_s.nextval;
	    x_dcnt       := 1;
	    x_counter := x_counter + 1;
	 ELSE
	    x_dcnt := x_dcnt + 1;
         END IF;

          xx_delv_control_tab(x_rec_dcnt).publish_batch_id := x_batch_id_dn;
          xx_delv_control_tab(x_rec_dcnt).record_id := r_dlvr_batch_err.record_id;
          xx_delv_control_tab(x_rec_dcnt).master_batch_id := x_batch_id;
          xx_delv_control_tab(x_rec_dcnt).status_flag := 'NEW';
       END LOOP;
       IF (x_lcnt <> 0) OR (x_dcnt <> 0)THEN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Line and Delivery batch data to control table');
          --Update line control table
          IF xx_line_control_tab.COUNT > 0 THEN
             FORALL i_lne IN 1 .. xx_line_control_tab.COUNT
                UPDATE xx_om_sfdc_line_control_tbl
                   SET publish_batch_id = xx_line_control_tab(i_lne).publish_batch_id
                      ,master_batch_id = xx_line_control_tab(i_lne).master_batch_id
                 WHERE record_id = xx_line_control_tab(i_lne).record_id
                   AND status_flag = xx_line_control_tab(i_lne).status_flag;
             xx_line_control_tab.DELETE;
          END IF;
          --Update delivery control table
          IF xx_delv_control_tab.COUNT > 0 THEN
             FORALL i_dlv IN 1 .. xx_delv_control_tab.COUNT
                UPDATE xx_om_sfdc_del_control_tbl
                   SET publish_batch_id = xx_delv_control_tab(i_dlv).publish_batch_id
                      ,master_batch_id = xx_delv_control_tab(i_dlv).master_batch_id
                 WHERE record_id = xx_delv_control_tab(i_dlv).record_id
                   AND status_flag = xx_delv_control_tab(i_dlv).status_flag;
             xx_delv_control_tab.DELETE;
          END IF;
          COMMIT;
          --send_batch (p_type, p_request_id, x_batch_id);
       END IF;
   END;
   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Send Batch to trigger BE');
   --Call send batch
   BEGIN
      FOR r_hdr_batch_send IN c_hdr_batch_send
      LOOP
         send_batch (p_type, p_request_id, r_hdr_batch_send.batch_id);
      END LOOP;
      FOR r_line_batch_send IN c_line_batch_send
      LOOP
         send_batch (p_type, p_request_id, r_line_batch_send.batch_id);
      END LOOP;
      FOR r_dlvr_batch_send IN c_dlvr_batch_send
      LOOP
         send_batch (p_type, p_request_id, r_dlvr_batch_send.batch_id);
      END LOOP;
   END;

   xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End generate batch');
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'generate_batch -> Exception while generating batch details'||SQLERRM);
END generate_batch;

--------------------------------------------------------------------------------------------------------
PROCEDURE get_header ( p_type             IN   VARCHAR2
                      ,p_so_from          IN   NUMBER
                      ,p_so_to            IN   NUMBER
                      ,p_date_from        IN   VARCHAR2
                      ,p_date_to          IN   VARCHAR2)
IS

  CURSOR c_header_int( p_type        VARCHAR2
                      ,p_date_from   DATE
                      ,p_date_to     DATE
                      ,p_so_from   NUMBER
                      ,p_so_to     NUMBER)
  IS
  SELECT DISTINCT header_id
    FROM
  (SELECT   ooh.header_id
           ,GREATEST( ooh.last_update_date
                    ,NVL(invoice_psite.last_update_date,'01-JAN-1000')
                    ,NVL(rep.last_update_date,'01-JAN-1000')
                    ,NVL(qp.last_update_date,'01-JAN-1000')
                    ,NVL(ship_acc.last_update_date,'01-JAN-1000')
                    ,NVL(ship_psite.last_update_date,'01-JAN-1000')
                  ) last_update_date
    FROM   oe_order_headers_all ooh
          ,oe_transaction_types_tl oht
          -- Bill to
          ,hz_cust_site_uses_all invoice_use
          ,hz_cust_acct_sites_all invoice_site
          ,hz_party_sites invoice_psite
          ,hz_locations invoice_loc
          ,hz_cust_accounts invoice_acc
          -- Ship to
          ,hz_cust_acct_sites_all ship_site
          ,hz_cust_site_uses_all ship_use
          ,hz_party_sites ship_psite
          ,hz_locations ship_loc
          ,hz_cust_accounts ship_acc
          ,hz_parties hp
          ,jtf_rs_salesreps rep
          ,qp_list_headers qp
   WHERE   oht.transaction_type_id = ooh.order_type_id
     AND   oht.language = USERENV ('LANG')
     AND   ooh.salesrep_id = rep.salesrep_id(+)
     AND   ooh.price_list_id = qp.list_header_id(+)
--     AND   NVL(invoice_loc.country,'XXXX') = 'US'  -- Commented out for Wave2
     AND   invoice_use.status = 'A'
     AND   ooh.invoice_to_org_id =  invoice_use.site_use_id
     AND   invoice_use.cust_acct_site_id = invoice_site.cust_acct_site_id(+)
     AND   invoice_site.party_site_id = invoice_psite.party_site_id(+)
     AND   invoice_psite.location_id = invoice_loc.location_id(+)
     AND   invoice_site.cust_account_id = invoice_acc.cust_account_id(+)
      -- Ship to
     AND   NVL(ship_acc.customer_class_code,'XXXX') NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
     AND   ship_use.status = 'A'
     AND   ooh.ship_to_org_id =  ship_use.site_use_id
     AND   ship_use.cust_acct_site_id = ship_site.cust_acct_site_id(+)
     AND   ship_site.party_site_id = ship_psite.party_site_id(+)
     AND   ship_psite.location_id = ship_loc.location_id(+)
     AND   ship_site.cust_account_id = ship_acc.cust_account_id(+)
     AND   hp.party_id = ship_acc.party_id
     AND   ship_acc.customer_type = 'R'
     AND   ship_psite.status = 'A'
     AND   hp.status = 'A'
     AND   ship_site.status = 'A'
     AND   ship_acc.status = 'A'
     AND   NVL(ooh.booked_flag,'X') = 'Y'
     AND   EXISTS (SELECT lookup_code
                     FROM fnd_lookup_values_vl
                    WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                      AND NVL(enabled_flag,'X')='Y'
                      AND lookup_code = ooh.org_id
                      AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
     AND (GREATEST( ooh.last_update_date
                    ,NVL(invoice_psite.last_update_date,'01-JAN-1000')
                    ,NVL(rep.last_update_date,'01-JAN-1000')
                    ,NVL(qp.last_update_date,'01-JAN-1000')
                    ,NVL(ship_acc.last_update_date,'01-JAN-1000')
                    ,NVL(ship_psite.last_update_date,'01-JAN-1000')
                  ) BETWEEN p_date_from AND p_date_to AND p_type IN ('INITIAL')
      OR (ooh.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
     )
     ORDER BY header_id;

   CURSOR c_header_new( p_type        VARCHAR2
                       ,p_date_from   DATE
                       ,p_date_to     DATE
                       ,p_so_from   NUMBER
                       ,p_so_to     NUMBER)
   IS
   SELECT DISTINCT header_id
     FROM
   (SELECT   ooh.header_id
            ,GREATEST( ooh.last_update_date
                     ,NVL(invoice_psite.last_update_date,'01-JAN-1000')
                     ,NVL(rep.last_update_date,'01-JAN-1000')
                     ,NVL(qp.last_update_date,'01-JAN-1000')
                     ,NVL(ship_acc.last_update_date,'01-JAN-1000')
                     ,NVL(ship_psite.last_update_date,'01-JAN-1000')
                   ) last_update_date
     FROM   oe_order_headers_all ooh
           ,oe_transaction_types_tl oht
           -- Bill to
           ,hz_cust_site_uses_all invoice_use
           ,hz_cust_acct_sites_all invoice_site
           ,hz_party_sites invoice_psite
           ,hz_locations invoice_loc
           ,hz_cust_accounts invoice_acc
           -- Ship to
           ,hz_cust_acct_sites_all ship_site
           ,hz_cust_site_uses_all ship_use
           ,hz_party_sites ship_psite
           ,hz_locations ship_loc
           ,hz_cust_accounts ship_acc
           ,hz_parties hp
           ,jtf_rs_salesreps rep
           ,qp_list_headers qp
    WHERE   oht.transaction_type_id = ooh.order_type_id
      AND   oht.language = USERENV ('LANG')
      AND   ooh.salesrep_id = rep.salesrep_id(+)
      AND   ooh.price_list_id = qp.list_header_id(+)
--      AND   NVL(invoice_loc.country,'XXXX') = 'US' -- Commented out for Wave2
      AND   ooh.invoice_to_org_id =  invoice_use.site_use_id
      AND   invoice_use.cust_acct_site_id = invoice_site.cust_acct_site_id(+)
      AND   invoice_site.party_site_id = invoice_psite.party_site_id(+)
      AND   invoice_psite.location_id = invoice_loc.location_id(+)
      AND   invoice_site.cust_account_id = invoice_acc.cust_account_id(+)
       -- Ship to
      AND   NVL(ship_acc.customer_class_code,'XXXX') NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
      AND   ooh.ship_to_org_id =  ship_use.site_use_id
      AND   ship_use.cust_acct_site_id = ship_site.cust_acct_site_id(+)
      AND   ship_site.party_site_id = ship_psite.party_site_id(+)
      AND   ship_psite.location_id = ship_loc.location_id(+)
      AND   ship_site.cust_account_id = ship_acc.cust_account_id(+)
      AND   hp.party_id = ship_acc.party_id
      AND   ship_acc.customer_type = 'R'
      --AND   ship_psite.status = 'A'
      --AND   hp.status = 'A'
      --AND   ship_site.status = 'A'
      --AND   ship_acc.status = 'A'
      AND   NVL(ooh.booked_flag,'X') = 'Y'
      AND   EXISTS (SELECT lookup_code
                      FROM fnd_lookup_values_vl
                     WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                       AND NVL(enabled_flag,'X')='Y'
                       AND lookup_code = ooh.org_id
                       AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
      AND (GREATEST( ooh.last_update_date
                     ,NVL(invoice_psite.last_update_date,'01-JAN-1000')
                     ,NVL(rep.last_update_date,'01-JAN-1000')
                     ,NVL(qp.last_update_date,'01-JAN-1000')
                     ,NVL(ship_acc.last_update_date,'01-JAN-1000')
                     ,NVL(ship_psite.last_update_date,'01-JAN-1000')
                   ) BETWEEN p_date_from AND p_date_to AND p_type IN ('NEW')
       OR (ooh.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
      )
     ORDER BY header_id;

  TYPE xx_sdc_order_header_tab IS TABLE OF xx_om_sfdc_head_control_tbl%ROWTYPE
  INDEX BY BINARY_INTEGER;

  xx_sdc_order_header_tab_typ   xx_sdc_order_header_tab;

  CURSOR c_republish ( p_type VARCHAR2, p_date_from DATE, p_date_to DATE )
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_head_control_tbl
   WHERE TRUNC(creation_date) BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to)
     AND p_type IN ('Reprocess')
     --AND header_id = 15411
     AND nvl(status_flag,'NEW' )  <> 'SUCCESS'; -- Select All Records which are not SUCCESS

  x_record_id      NUMBER;
  x_batch_id       NUMBER;
  x_flag           VARCHAR2(1):='N';
  x_counter        NUMBER :=0;
  x_cnt            NUMBER :=0;

  x_new_type       VARCHAR2 (20);
  x_date_from      DATE;
  x_date_to        DATE;
BEGIN
    IF p_type = 'New' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_HEADER_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'NEW';
       END IF;
       FOR r_header IN c_header_new(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_head_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_header_tab_typ(x_cnt).record_id        := xx_sdc_order_head_s.nextval;
          xx_sdc_order_header_tab_typ(x_cnt).header_id        := r_header.header_id;
          xx_sdc_order_header_tab_typ(x_cnt).publish_batch_id := NULL;--x_batch_id;
          xx_sdc_order_header_tab_typ(x_cnt).instance_id      := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).publish_time     := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).publish_system   := x_publish_system;
          xx_sdc_order_header_tab_typ(x_cnt).target_system    := x_target_system;
          xx_sdc_order_header_tab_typ(x_cnt).status_flag      := x_status_flag;
          xx_sdc_order_header_tab_typ(x_cnt).sfdc_id          := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).response_message := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).request_id       := x_request_id;
          xx_sdc_order_header_tab_typ(x_cnt).created_by       := x_user_id;
          xx_sdc_order_header_tab_typ(x_cnt).creation_date    := SYSDATE;
          xx_sdc_order_header_tab_typ(x_cnt).last_update_date := SYSDATE;
          xx_sdc_order_header_tab_typ(x_cnt).last_updated_by  := x_user_id;
          xx_sdc_order_header_tab_typ(x_cnt).last_update_login:= x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Header Record Count -> '||xx_sdc_order_header_tab_typ.COUNT);

       IF xx_sdc_order_header_tab_typ.COUNT > 0 THEN
          FORALL i IN 1 .. xx_sdc_order_header_tab_typ.COUNT
          INSERT INTO xx_om_sfdc_head_control_tbl
              VALUES xx_sdc_order_header_tab_typ (i);
       END IF;

       IF x_new_type = 'NEW' THEN
          --Update program last run date to EMF
          UPDATE xx_emf_process_parameters
             SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
           WHERE parameter_name = 'ORDER_HEADER_RUN'
             AND process_id = ( SELECT PROCESS_ID
                                  FROM xx_emf_process_setup
                                 WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Initial' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_HEADER_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'INITIAL';
       END IF;
       FOR r_header IN c_header_int(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_head_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_header_tab_typ(x_cnt).record_id        := xx_sdc_order_head_s.nextval;
          xx_sdc_order_header_tab_typ(x_cnt).header_id        := r_header.header_id;
          xx_sdc_order_header_tab_typ(x_cnt).publish_batch_id := NULL;--x_batch_id;
          xx_sdc_order_header_tab_typ(x_cnt).instance_id      := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).publish_time     := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).publish_system   := x_publish_system;
          xx_sdc_order_header_tab_typ(x_cnt).target_system    := x_target_system;
          xx_sdc_order_header_tab_typ(x_cnt).status_flag      := x_status_flag;
          xx_sdc_order_header_tab_typ(x_cnt).sfdc_id          := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).response_message := NULL;
          xx_sdc_order_header_tab_typ(x_cnt).request_id       := x_request_id;
          xx_sdc_order_header_tab_typ(x_cnt).created_by       := x_user_id;
          xx_sdc_order_header_tab_typ(x_cnt).creation_date    := SYSDATE;
          xx_sdc_order_header_tab_typ(x_cnt).last_update_date := SYSDATE;
          xx_sdc_order_header_tab_typ(x_cnt).last_updated_by  := x_user_id;
          xx_sdc_order_header_tab_typ(x_cnt).last_update_login:= x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Header Record Count -> '||xx_sdc_order_header_tab_typ.COUNT);

       IF xx_sdc_order_header_tab_typ.COUNT > 0 THEN
          FORALL i IN 1 .. xx_sdc_order_header_tab_typ.COUNT
          INSERT INTO xx_om_sfdc_head_control_tbl
              VALUES xx_sdc_order_header_tab_typ (i);
       END IF;

       IF x_new_type = 'INITIAL' THEN
          --Update program last run date to EMF
          UPDATE xx_emf_process_parameters
             SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
           WHERE parameter_name = 'ORDER_HEADER_RUN'
             AND process_id = ( SELECT PROCESS_ID
                                  FROM xx_emf_process_setup
                                 WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Reprocess' THEN
       x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_from IS NULL THEN
          SELECT MIN(creation_date)
            INTO x_date_from
            FROM xx_om_sfdc_head_control_tbl;
       END IF;
       x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_to IS NULL THEN
          SELECT MAX(creation_date)
            INTO x_date_to
            FROM xx_om_sfdc_head_control_tbl;
       END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date From ->'||x_date_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date To   ->'||x_date_to);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

       FOR republish_rec IN c_republish (p_type, x_date_from, x_date_to )
       LOOP
         --x_batch_id      := xx_sdc_order_head_batch_s.nextval;

         UPDATE xx_om_sfdc_head_control_tbl
            SET status_flag          = 'NEW',
                response_message     = NULL,
                instance_id          = NULL,
                last_update_date     = SYSDATE,
                last_update_login    = x_login_id,
                last_updated_by      = x_user_id,
                request_id           = x_request_id, -- Assign New Request ID
                publish_batch_id     = NULL  --x_batch_id    -- Assign New Batch
          WHERE publish_batch_id = republish_rec.publish_batch_id
            AND nvl(status_flag, 'NEW')   <> 'SUCCESS'; -- Select Only not SUCCESS records
       END LOOP;
    END IF;
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'get_header -> Exception while getting header records'||SQLERRM);
END get_header;

----------------------------------------------------------------------

PROCEDURE get_line( p_type             IN   VARCHAR2
                   ,p_so_from          IN   NUMBER
                   ,p_so_to            IN   NUMBER
                   ,p_date_from        IN   VARCHAR2
                   ,p_date_to          IN   VARCHAR2)
IS
   CURSOR c_line_int( p_type        VARCHAR2
                     ,p_date_from   DATE
                     ,p_date_to     DATE
                     ,p_so_from   NUMBER
                     ,p_so_to     NUMBER)
   IS
   SELECT DISTINCT header_id,line_id
     FROM
    (SELECT   ool.header_id
             ,ool.line_id
             ,GREATEST( ool.last_update_date
                       ,NVL(msb.last_update_date,'01-JAN-1000')
                       ,NVL(car.last_update_date,'01-JAN-1000')
                       ,NVL(rat.last_update_date,'01-JAN-1000')
                       ,(SELECT NVL(MAX(last_update_date),SYSDATE-100)
                          FROM  wsh_delivery_details
                         WHERE  source_line_id = ool.line_id
                           AND  source_header_id = ool.header_id)
                      ) last_update_date
       FROM   oe_order_lines_all ool
             ,wsh_carrier_services_v car
             ,ra_terms rat
             ,org_organization_definitions mtp
             ,mtl_system_items_b msb
      WHERE   ool.shipping_method_code = car.ship_method_code(+)
        AND   ool.payment_term_id = rat.term_id (+)
        AND   NVL(ool.ship_from_org_id,83) = mtp.organization_id (+)
        AND   msb.item_type IN ('FG','RPR','TLIN')
        AND   ool.inventory_item_id = msb.inventory_item_id
        AND   NVL(ool.ship_from_org_id,83)= msb.organization_id
        AND   EXISTS (SELECT  ooh.header_id
                        FROM  hz_cust_acct_sites_all ship_site
                             ,hz_cust_site_uses_all ship_use
                             ,hz_cust_accounts ship_acc
                             ,hz_parties hp
                             ,hz_party_sites ship_psite
                             ,oe_order_headers_all ooh
                       WHERE  ooh.ship_to_org_id =  ship_use.site_use_id
                         AND  ship_acc.customer_class_code NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
                         AND  ship_use.status = 'A'
                         AND  ship_use.cust_acct_site_id = ship_site.cust_acct_site_id
                         AND  ship_site.cust_account_id = ship_acc.cust_account_id
                         AND  ship_site.party_site_id = ship_psite.party_site_id
                         AND  ooh.header_id  = ool.header_id
                         AND  hp.party_id = ship_acc.party_id
			 AND  ship_acc.customer_type = 'R'
			 AND  ship_psite.status = 'A'
			 AND  hp.status = 'A'
			 AND  ship_site.status = 'A'
			 AND  ship_acc.status = 'A'
                         )
        /*AND   EXISTS (SELECT header_id
                        FROM oe_order_headers_all
                       WHERE NVL(booked_flag,'X') = 'Y'
                         AND header_id = ool.header_id)*/
        AND   EXISTS (SELECT ctl.header_id
                        FROM xx_om_sfdc_head_control_tbl ctl
                       WHERE ctl.header_id = ool.header_id)
        AND   EXISTS (SELECT lookup_code
                   FROM fnd_lookup_values_vl
                  WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                    AND NVL(enabled_flag,'X')='Y'
                    AND lookup_code = ool.org_id
                    AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
       AND (GREATEST( ool.last_update_date
                     ,NVL(msb.last_update_date,'01-JAN-1000')
                     ,NVL(car.last_update_date,'01-JAN-1000')
                     ,NVL(rat.last_update_date,'01-JAN-1000')
                     ,(SELECT NVL(MAX(last_update_date),SYSDATE-100)
		         FROM wsh_delivery_details
		        WHERE source_line_id = ool.line_id
                          AND source_header_id = ool.header_id)
                    )BETWEEN p_date_from AND p_date_to AND p_type IN ('INITIAL')
      OR (ool.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
      )
     ORDER BY header_id,line_id;

   CURSOR c_line_new( p_type        VARCHAR2
                     ,p_date_from   DATE
                     ,p_date_to     DATE
                     ,p_so_from   NUMBER
                     ,p_so_to     NUMBER)
   IS
   SELECT DISTINCT header_id,line_id
     FROM
    (SELECT   ool.header_id
             ,ool.line_id
             ,GREATEST( ool.last_update_date
                       ,NVL(msb.last_update_date,'01-JAN-1000')
                       ,NVL(car.last_update_date,'01-JAN-1000')
                       ,NVL(rat.last_update_date,'01-JAN-1000')
                       ,(SELECT NVL(MAX(last_update_date),SYSDATE-100)
                          FROM  wsh_delivery_details
                         WHERE  source_line_id = ool.line_id
                           AND  source_header_id = ool.header_id)
                      ) last_update_date
       FROM   oe_order_lines_all ool
             ,wsh_carrier_services_v car
             ,ra_terms rat
             ,org_organization_definitions mtp
             ,mtl_system_items_b msb
      WHERE   ool.shipping_method_code = car.ship_method_code(+)
        AND   ool.payment_term_id = rat.term_id (+)
        AND   NVL(ool.ship_from_org_id,83) = mtp.organization_id (+)
        AND   msb.item_type IN ('FG','RPR','TLIN')
        AND   ool.inventory_item_id = msb.inventory_item_id
        AND   NVL(ool.ship_from_org_id,83)= msb.organization_id
        AND   EXISTS (SELECT  ooh.header_id
                        FROM  hz_cust_acct_sites_all ship_site
                             ,hz_cust_site_uses_all ship_use
                             ,hz_cust_accounts ship_acc
                             ,hz_parties hp
                             ,hz_party_sites ship_psite
                             ,oe_order_headers_all ooh
                       WHERE  ooh.ship_to_org_id =  ship_use.site_use_id
                         AND  ship_acc.customer_class_code NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
                         AND  ship_use.cust_acct_site_id = ship_site.cust_acct_site_id
                         AND  ship_site.cust_account_id = ship_acc.cust_account_id
                         AND  ship_site.party_site_id = ship_psite.party_site_id
                         AND  ooh.header_id  = ool.header_id
                         AND  hp.party_id = ship_acc.party_id
			 AND  ship_acc.customer_type = 'R'
			 --AND  ship_psite.status = 'A'
			 --AND  hp.status = 'A'
			 --AND  ship_site.status = 'A'
			 --AND  ship_acc.status = 'A'
                         )
        /*AND   EXISTS (SELECT header_id
                        FROM oe_order_headers_all
                       WHERE NVL(booked_flag,'X') = 'Y'
                         AND header_id = ool.header_id)*/
        AND   EXISTS (SELECT ctl.header_id
                        FROM xx_om_sfdc_head_control_tbl ctl
                       WHERE ctl.header_id = ool.header_id)
        AND   EXISTS (SELECT lookup_code
                   FROM fnd_lookup_values_vl
                  WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                    AND NVL(enabled_flag,'X')='Y'
                    AND lookup_code = ool.org_id
                    AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
       AND (GREATEST( ool.last_update_date
                     ,NVL(msb.last_update_date,'01-JAN-1000')
                     ,NVL(car.last_update_date,'01-JAN-1000')
                     ,NVL(rat.last_update_date,'01-JAN-1000')
                     ,(SELECT NVL(MAX(last_update_date),SYSDATE-100)
		         FROM wsh_delivery_details
		        WHERE source_line_id = ool.line_id
                          AND source_header_id = ool.header_id)
                    )BETWEEN p_date_from AND p_date_to AND p_type IN ('NEW')
      OR (ool.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
      )
     ORDER BY header_id,line_id;

  TYPE xx_sdc_order_line_tab IS TABLE OF xx_om_sfdc_line_control_tbl%ROWTYPE
  INDEX BY BINARY_INTEGER;

  xx_sdc_order_line_tab_typ   xx_sdc_order_line_tab;

  CURSOR c_republish ( p_type VARCHAR2, p_date_from DATE, p_date_to DATE )
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_line_control_tbl
   WHERE TRUNC(creation_date) BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to)
     AND p_type IN ('Reprocess')
     --AND header_id = 15411
     AND nvl(status_flag,'NEW' )  <> 'SUCCESS'; -- Select All Records which are not SUCCESS

  x_record_id      NUMBER;
  x_batch_id       NUMBER;
  x_flag           VARCHAR2(1):='N';
  x_counter        NUMBER :=0;
  x_cnt            NUMBER :=0;

  x_new_type       VARCHAR2 (20);
  x_date_from      DATE;
  x_date_to        DATE;
BEGIN
    IF p_type = 'New' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_LINE_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'NEW';
       END IF;
       FOR r_line IN c_line_new(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_line_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_line_tab_typ(x_cnt).record_id        := xx_sdc_order_line_s.nextval;
          xx_sdc_order_line_tab_typ(x_cnt).header_id        := r_line.header_id;
          xx_sdc_order_line_tab_typ(x_cnt).line_id          := r_line.line_id;
          xx_sdc_order_line_tab_typ(x_cnt).publish_batch_id := NULL;--x_batch_id;
          xx_sdc_order_line_tab_typ(x_cnt).master_batch_id  := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).instance_id      := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).publish_time     := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).publish_system   := x_publish_system;
          xx_sdc_order_line_tab_typ(x_cnt).target_system    := x_target_system;
          xx_sdc_order_line_tab_typ(x_cnt).status_flag      := x_status_flag;
          xx_sdc_order_line_tab_typ(x_cnt).sfdc_id          := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).response_message := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).request_id       := x_request_id;
          xx_sdc_order_line_tab_typ(x_cnt).created_by       := x_user_id;
          xx_sdc_order_line_tab_typ(x_cnt).creation_date    := SYSDATE;
          xx_sdc_order_line_tab_typ(x_cnt).last_update_date := SYSDATE;
          xx_sdc_order_line_tab_typ(x_cnt).last_updated_by  := x_user_id;
          xx_sdc_order_line_tab_typ(x_cnt).last_update_login:= x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Line Record Count -> '||xx_sdc_order_line_tab_typ.COUNT);

       IF xx_sdc_order_line_tab_typ.COUNT > 0 THEN
          FORALL i IN 1 .. xx_sdc_order_line_tab_typ.COUNT
          INSERT INTO xx_om_sfdc_line_control_tbl
              VALUES xx_sdc_order_line_tab_typ (i);
       END IF;

       IF x_new_type = 'NEW' THEN
          --Update program last run date to EMF
         UPDATE xx_emf_process_parameters
            SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
          WHERE parameter_name = 'ORDER_LINE_RUN'
            AND process_id = ( SELECT PROCESS_ID
                                 FROM xx_emf_process_setup
                                WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Initial' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_LINE_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'INITIAL';
       END IF;
       FOR r_line IN c_line_int(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_line_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_line_tab_typ(x_cnt).record_id        := xx_sdc_order_line_s.nextval;
          xx_sdc_order_line_tab_typ(x_cnt).header_id        := r_line.header_id;
          xx_sdc_order_line_tab_typ(x_cnt).line_id          := r_line.line_id;
          xx_sdc_order_line_tab_typ(x_cnt).publish_batch_id := NULL;--x_batch_id;
          xx_sdc_order_line_tab_typ(x_cnt).master_batch_id  := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).instance_id      := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).publish_time     := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).publish_system   := x_publish_system;
          xx_sdc_order_line_tab_typ(x_cnt).target_system    := x_target_system;
          xx_sdc_order_line_tab_typ(x_cnt).status_flag      := x_status_flag;
          xx_sdc_order_line_tab_typ(x_cnt).sfdc_id          := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).response_message := NULL;
          xx_sdc_order_line_tab_typ(x_cnt).request_id       := x_request_id;
          xx_sdc_order_line_tab_typ(x_cnt).created_by       := x_user_id;
          xx_sdc_order_line_tab_typ(x_cnt).creation_date    := SYSDATE;
          xx_sdc_order_line_tab_typ(x_cnt).last_update_date := SYSDATE;
          xx_sdc_order_line_tab_typ(x_cnt).last_updated_by  := x_user_id;
          xx_sdc_order_line_tab_typ(x_cnt).last_update_login:= x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Line Record Count -> '||xx_sdc_order_line_tab_typ.COUNT);

       IF xx_sdc_order_line_tab_typ.COUNT > 0 THEN
          FORALL i IN 1 .. xx_sdc_order_line_tab_typ.COUNT
          INSERT INTO xx_om_sfdc_line_control_tbl
              VALUES xx_sdc_order_line_tab_typ (i);
       END IF;

       IF x_new_type = 'INITIAL' THEN
          --Update program last run date to EMF
         UPDATE xx_emf_process_parameters
            SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
          WHERE parameter_name = 'ORDER_LINE_RUN'
            AND process_id = ( SELECT PROCESS_ID
                                 FROM xx_emf_process_setup
                                WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Reprocess' THEN
        x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_from IS NULL THEN
          SELECT MIN(creation_date)
            INTO x_date_from
            FROM xx_om_sfdc_line_control_tbl;
       END IF;
        x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_to IS NULL THEN
          SELECT MAX(creation_date)
            INTO x_date_to
            FROM xx_om_sfdc_line_control_tbl;
       END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date From ->'||x_date_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date To   ->'||x_date_to);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

       FOR republish_rec IN c_republish (p_type, x_date_from, x_date_to )
       LOOP
         --x_batch_id      := xx_sdc_order_line_batch_s.nextval;

         UPDATE xx_om_sfdc_line_control_tbl
            SET status_flag          = 'NEW',
                response_message     = NULL,
                instance_id          = NULL,
                last_update_date     = SYSDATE,
                last_update_login    = x_login_id,
                last_updated_by      = x_user_id,
                request_id           = x_request_id, -- Assign New Request ID
                publish_batch_id     = NULL,  --x_batch_id    -- Assign New Batch
                master_batch_id      = NULL
           WHERE publish_batch_id = republish_rec.publish_batch_id
            AND nvl(status_flag, 'NEW')   <> 'SUCCESS'; -- Select Only not SUCCESS records
       END LOOP;
    END IF;
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'get_line -> Exception while getting line records'||SQLERRM);
END get_line;

----------------------------------------------------------------------

PROCEDURE get_delivery( p_type             IN   VARCHAR2
                       ,p_so_from          IN   NUMBER
                       ,p_so_to            IN   NUMBER
                       ,p_date_from        IN   VARCHAR2
                       ,p_date_to          IN   VARCHAR2)
IS
   CURSOR c_del_int( p_type        VARCHAR2
                    ,p_date_from   DATE
                    ,p_date_to     DATE
                    ,p_so_from   NUMBER
                    ,p_so_to     NUMBER)
   IS
   SELECT DISTINCT header_id,line_id,delivery_detail_id
     FROM
   (SELECT   ool.header_id
            ,ool.line_id
            ,wdd.delivery_detail_id
            ,GREATEST( wdd.last_update_date
                      ,NVL(wnd.last_update_date,'01-JAN-1000')
                      ,NVL(car.last_update_date,'01-JAN-1000')
                     ) last_update_date
      FROM   oe_order_lines_all ool
            ,wsh_new_deliveries wnd
            ,wsh_delivery_assignments wds
            ,wsh_delivery_details wdd
            ,wsh_carriers car
     WHERE  wnd.delivery_id        = wds.delivery_id
       AND  wds.delivery_detail_id = wdd.delivery_detail_id
       AND  wdd.source_header_id = ool.header_id
       AND  wdd.source_line_id = ool.line_id
       AND  wnd.carrier_id = car.carrier_id
       AND   EXISTS (SELECT  ooh.header_id
                        FROM  hz_cust_acct_sites_all ship_site
                             ,hz_cust_site_uses_all ship_use
                             ,hz_cust_accounts ship_acc
                             ,hz_parties hp
                             ,hz_party_sites ship_psite
                             ,oe_order_headers_all ooh
                       WHERE  ooh.ship_to_org_id =  ship_use.site_use_id
                         AND  ship_acc.customer_class_code NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
                         AND  ship_use.status = 'A'
                         AND  ship_use.cust_acct_site_id = ship_site.cust_acct_site_id
                         AND  ship_site.cust_account_id = ship_acc.cust_account_id
                         AND  ship_site.party_site_id = ship_psite.party_site_id
                         AND  ooh.header_id  = ool.header_id
                         AND  hp.party_id = ship_acc.party_id
			 AND  ship_acc.customer_type = 'R'
			 AND  ship_psite.status = 'A'
			 AND  hp.status = 'A'
			 AND  ship_site.status = 'A'
			 AND  ship_acc.status = 'A'
                         )
       AND  EXISTS ( SELECT msib.inventory_item_id
                       FROM mtl_system_items_b msib
                      WHERE msib.item_type IN ('FG','RPR','TLIN')
                        AND msib.organization_id = NVL(ool.ship_from_org_id,83)
                        AND msib.inventory_item_id = ool.inventory_item_id )
       /*AND  EXISTS (SELECT header_id
                      FROM oe_order_headers_all
                     WHERE NVL(booked_flag,'X') = 'Y'
                       AND header_id = ool.header_id)*/
       AND   EXISTS (SELECT ctl.header_id
                       FROM xx_om_sfdc_head_control_tbl ctl
                      WHERE ctl.header_id = ool.header_id)
       AND  EXISTS (SELECT lookup_code
                      FROM fnd_lookup_values_vl
                     WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                       AND NVL(enabled_flag,'X')='Y'
                       AND lookup_code = ool.org_id
                       AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
       AND (GREATEST( wdd.last_update_date
                      ,NVL(wnd.last_update_date,'01-JAN-1000')
                      ,NVL(car.last_update_date,'01-JAN-1000')
                     ) BETWEEN p_date_from AND p_date_to AND p_type IN ('INITIAL')
      OR (ool.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
     )
     ORDER BY header_id,line_id,delivery_detail_id;

   CURSOR c_del_new( p_type        VARCHAR2
                    ,p_date_from   DATE
                    ,p_date_to     DATE
                    ,p_so_from   NUMBER
                    ,p_so_to     NUMBER)
   IS
   SELECT DISTINCT header_id,line_id,delivery_detail_id
     FROM
   (SELECT   ool.header_id
            ,ool.line_id
            ,wdd.delivery_detail_id
            ,GREATEST( wdd.last_update_date
                      ,NVL(wnd.last_update_date,'01-JAN-1000')
                      ,NVL(car.last_update_date,'01-JAN-1000')
                     ) last_update_date
      FROM   oe_order_lines_all ool
            ,wsh_new_deliveries wnd
            ,wsh_delivery_assignments wds
            ,wsh_delivery_details wdd
            ,wsh_carriers car
     WHERE  wnd.delivery_id        = wds.delivery_id
       AND  wds.delivery_detail_id = wdd.delivery_detail_id
       AND  wdd.source_header_id = ool.header_id
       AND  wdd.source_line_id = ool.line_id
       AND  wnd.carrier_id = car.carrier_id
       AND   EXISTS (SELECT  ooh.header_id
                        FROM  hz_cust_acct_sites_all ship_site
                             ,hz_cust_site_uses_all ship_use
                             ,hz_cust_accounts ship_acc
                             ,hz_parties hp
                             ,hz_party_sites ship_psite
                             ,oe_order_headers_all ooh
                       WHERE  ooh.ship_to_org_id =  ship_use.site_use_id
                         AND  ship_acc.customer_class_code NOT IN ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
                         AND  ship_use.cust_acct_site_id = ship_site.cust_acct_site_id
                         AND  ship_site.cust_account_id = ship_acc.cust_account_id
                         AND  ship_site.party_site_id = ship_psite.party_site_id
                         AND  ooh.header_id  = ool.header_id
                         AND  hp.party_id = ship_acc.party_id
			 AND  ship_acc.customer_type = 'R'
			 --AND  ship_psite.status = 'A'
			 --AND  hp.status = 'A'
			 --AND  ship_site.status = 'A'
			 --AND  ship_acc.status = 'A'
                         )
       AND  EXISTS ( SELECT msib.inventory_item_id
                       FROM mtl_system_items_b msib
                      WHERE msib.item_type IN ('FG','RPR','TLIN')
                        AND msib.organization_id = NVL(ool.ship_from_org_id,83)
                        AND msib.inventory_item_id = ool.inventory_item_id )
       /*AND  EXISTS (SELECT header_id
                      FROM oe_order_headers_all
                     WHERE NVL(booked_flag,'X') = 'Y'
                       AND header_id = ool.header_id)*/
       AND   EXISTS (SELECT ctl.header_id
                       FROM xx_om_sfdc_head_control_tbl ctl
                      WHERE ctl.header_id = ool.header_id)
       AND  EXISTS (SELECT lookup_code
                      FROM fnd_lookup_values_vl
                     WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                       AND NVL(enabled_flag,'X')='Y'
                       AND lookup_code = ool.org_id
                       AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
       AND (GREATEST( wdd.last_update_date
                      ,NVL(wnd.last_update_date,'01-JAN-1000')
                      ,NVL(car.last_update_date,'01-JAN-1000')
                     ) BETWEEN p_date_from AND p_date_to AND p_type IN ('NEW')
      OR (ool.header_id BETWEEN p_so_from AND p_so_to AND p_type IN ('RESEND')))
     )
     ORDER BY header_id,line_id,delivery_detail_id;


  TYPE xx_sdc_order_del_tab IS TABLE OF xx_om_sfdc_del_control_tbl%ROWTYPE
  INDEX BY BINARY_INTEGER;

  xx_sdc_order_del_tab_typ   xx_sdc_order_del_tab;

  CURSOR c_republish ( p_type VARCHAR2, p_date_from DATE, p_date_to DATE )
  IS
  SELECT DISTINCT publish_batch_id
    FROM xx_om_sfdc_del_control_tbl
   WHERE TRUNC(creation_date) BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to)
     AND p_type IN ('Reprocess')
     --AND header_id = 15411
     AND nvl(status_flag,'NEW' )  <> 'SUCCESS'; -- Select All Records which are not SUCCESS

  x_record_id      NUMBER;
  x_batch_id       NUMBER;
  x_flag           VARCHAR2(1):='N';
  x_counter        NUMBER :=0;
  x_cnt            NUMBER :=0;

  x_new_type       VARCHAR2 (20);
  x_date_from      DATE;
  x_date_to        DATE;
BEGIN
    IF p_type = 'New' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_DEL_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'NEW';
       END IF;
       FOR r_del IN c_del_new(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_del_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_del_tab_typ(x_cnt).record_id          := xx_sdc_order_del_s.nextval;
          xx_sdc_order_del_tab_typ(x_cnt).header_id          := r_del.header_id;
          xx_sdc_order_del_tab_typ(x_cnt).line_id            := r_del.line_id;
          xx_sdc_order_del_tab_typ(x_cnt).delivery_detail_id := r_del.delivery_detail_id;
          xx_sdc_order_del_tab_typ(x_cnt).publish_batch_id   := NULL;--x_batch_id;
          xx_sdc_order_del_tab_typ(x_cnt).master_batch_id    := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).instance_id        := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).publish_time       := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).publish_system     := x_publish_system;
          xx_sdc_order_del_tab_typ(x_cnt).target_system      := x_target_system;
          xx_sdc_order_del_tab_typ(x_cnt).status_flag        := x_status_flag;
          xx_sdc_order_del_tab_typ(x_cnt).sfdc_id            := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).response_message   := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).request_id         := x_request_id;
          xx_sdc_order_del_tab_typ(x_cnt).created_by         := x_user_id;
          xx_sdc_order_del_tab_typ(x_cnt).creation_date      := SYSDATE;
          xx_sdc_order_del_tab_typ(x_cnt).last_update_date   := SYSDATE;
          xx_sdc_order_del_tab_typ(x_cnt).last_updated_by    := x_user_id;
          xx_sdc_order_del_tab_typ(x_cnt).last_update_login  := x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Del Record Count -> '||xx_sdc_order_del_tab_typ.COUNT);

       IF xx_sdc_order_del_tab_typ.COUNT > 0 THEN
         FORALL i IN 1 .. xx_sdc_order_del_tab_typ.COUNT
         INSERT INTO xx_om_sfdc_del_control_tbl
                VALUES xx_sdc_order_del_tab_typ (i);
       END IF;

       IF x_new_type = 'NEW' THEN
          --Update program last run date to EMF
          UPDATE xx_emf_process_parameters
             SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
           WHERE parameter_name = 'ORDER_DEL_RUN'
             AND process_id = ( SELECT PROCESS_ID
                                  FROM xx_emf_process_setup
                                 WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Initial' THEN
       IF p_so_from IS NOT NULL OR p_so_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ORDER_DEL_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'INITIAL';
       END IF;
       FOR r_del IN c_del_int(x_new_type, x_date_from, x_date_to,p_so_from,p_so_to)
       LOOP
          /*IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xx_sdc_order_del_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;*/

          x_cnt := x_cnt + 1;
          xx_sdc_order_del_tab_typ(x_cnt).record_id          := xx_sdc_order_del_s.nextval;
          xx_sdc_order_del_tab_typ(x_cnt).header_id          := r_del.header_id;
          xx_sdc_order_del_tab_typ(x_cnt).line_id            := r_del.line_id;
          xx_sdc_order_del_tab_typ(x_cnt).delivery_detail_id := r_del.delivery_detail_id;
          xx_sdc_order_del_tab_typ(x_cnt).publish_batch_id   := NULL;--x_batch_id;
          xx_sdc_order_del_tab_typ(x_cnt).master_batch_id    := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).instance_id        := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).publish_time       := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).publish_system     := x_publish_system;
          xx_sdc_order_del_tab_typ(x_cnt).target_system      := x_target_system;
          xx_sdc_order_del_tab_typ(x_cnt).status_flag        := x_status_flag;
          xx_sdc_order_del_tab_typ(x_cnt).sfdc_id            := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).response_message   := NULL;
          xx_sdc_order_del_tab_typ(x_cnt).request_id         := x_request_id;
          xx_sdc_order_del_tab_typ(x_cnt).created_by         := x_user_id;
          xx_sdc_order_del_tab_typ(x_cnt).creation_date      := SYSDATE;
          xx_sdc_order_del_tab_typ(x_cnt).last_update_date   := SYSDATE;
          xx_sdc_order_del_tab_typ(x_cnt).last_updated_by    := x_user_id;
          xx_sdc_order_del_tab_typ(x_cnt).last_update_login  := x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Del Record Count -> '||xx_sdc_order_del_tab_typ.COUNT);

       IF xx_sdc_order_del_tab_typ.COUNT > 0 THEN
         FORALL i IN 1 .. xx_sdc_order_del_tab_typ.COUNT
         INSERT INTO xx_om_sfdc_del_control_tbl
                VALUES xx_sdc_order_del_tab_typ (i);
       END IF;

       IF x_new_type = 'INITIAL' THEN
          --Update program last run date to EMF
          UPDATE xx_emf_process_parameters
             SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
           WHERE parameter_name = 'ORDER_DEL_RUN'
             AND process_id = ( SELECT PROCESS_ID
                                  FROM xx_emf_process_setup
                                 WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       COMMIT;
    ELSIF p_type = 'Reprocess' THEN
        x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_from IS NULL THEN
          SELECT MIN(creation_date)
            INTO x_date_from
            FROM xx_om_sfdc_del_control_tbl;
       END IF;
       x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       IF x_date_to IS NULL THEN
          SELECT MAX(creation_date)
            INTO x_date_to
            FROM xx_om_sfdc_del_control_tbl;
       END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date From ->'||x_date_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date To   ->'||x_date_to);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

       FOR republish_rec IN c_republish (p_type, x_date_from, x_date_to )
       LOOP
         --x_batch_id      := xx_sdc_order_del_batch_s.nextval;

         UPDATE xx_om_sfdc_del_control_tbl
            SET status_flag          = 'NEW',
                response_message     = NULL,
                instance_id          = NULL,
                last_update_date     = sysdate,
                last_update_login    = x_login_id,
                last_updated_by      = x_user_id,
                request_id           = x_request_id, -- Assign New Request ID
                publish_batch_id     = NULL,   --x_batch_id    -- Assign New Batch
                master_batch_id      = NULL
          WHERE publish_batch_id = republish_rec.publish_batch_id
            AND nvl(status_flag, 'NEW')   <> 'SUCCESS'; -- Select Only not SUCCESS records
       END LOOP;
    END IF;
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'get_delivery -> Exception while getting delivery records'||SQLERRM);
END get_delivery;

----------------------------------------------------------------------

PROCEDURE get_order_details   (   p_errbuf           OUT  VARCHAR2
                                 ,p_retcode          OUT  NUMBER
                                 ,p_type             IN   VARCHAR2
                                 ,p_hidden1          IN   VARCHAR2
                                 ,p_hidden2          IN   VARCHAR2
                                 ,p_so_from          IN   NUMBER
                                 ,p_so_to            IN   NUMBER
                                 ,p_date_from        IN   VARCHAR2
                                 ,p_date_to          IN   VARCHAR2)
IS
  x_error_code             VARCHAR2(1):= xx_emf_cn_pkg.CN_SUCCESS;

BEGIN
  p_retcode := xx_emf_cn_pkg.cn_success;
  x_error_code    := xx_emf_pkg.set_env;

  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Run Type         ->'||p_type);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'SO From          ->'||p_so_from);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'SO To            ->'||p_so_to);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date From ->'||p_date_from);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update Date To   ->'||p_date_to);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start main process Order Extraction');
  process_param_value;
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Batch Size ->'||x_batch_size);

  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start Header Extraction');
  get_header(p_type ,p_so_from ,p_so_to ,p_date_from ,p_date_to);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End Header Extraction');

  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start Line Extraction');
  get_line(p_type ,p_so_from ,p_so_to ,p_date_from ,p_date_to);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End Line Extraction');

  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start Delivery Extraction');
  get_delivery(p_type ,p_so_from ,p_so_to ,p_date_from ,p_date_to);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End Delivery Extraction');

  --x_request_id := 6568537;
  --send_batch(p_type,x_request_id);
  generate_batch(p_type,x_request_id);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End of main process Order Extraction');
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'get_order_details -> Exception while getting order records'||SQLERRM);
      p_retcode := 2;
END get_order_details;

----------------------------------------------------------------------

END xx_sdc_order_update_pkg;
/
