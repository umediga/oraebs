DROP PACKAGE BODY APPS.XX_SFDC_ITEM_OUT_CP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SFDC_ITEM_OUT_CP_PKG" AS
--------------------------------------------------------------------------------
 /*
 Created By     : IBM
 Creation Date  : 06-MAR-2014
 Filename       : XXSFDCITEMOUTCP.pkb
 Description    : Item Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 06-MAR-2014   1.0       ibm                 Initial development.
 */
--------------------------------------------------------------------------------
 x_user_id          NUMBER       := FND_GLOBAL.USER_ID;
 x_resp_id          NUMBER       := FND_GLOBAL.RESP_ID;
 x_login_id         NUMBER       := FND_GLOBAL.LOGIN_ID;
 x_request_id       NUMBER       := FND_GLOBAL.CONC_REQUEST_ID;

 x_publish_system   VARCHAR2(80) := 'EBS';
 x_target_system    VARCHAR2(280):= 'SFDC';
 x_status_flag      VARCHAR(10)  := 'NEW';
 x_batch_size       NUMBER := 50;
----------------------------------------------------------------------
FUNCTION raise_publish_event ( p_subscription_guid   IN              RAW
                              ,p_event               IN OUT NOCOPY   wf_event_t) RETURN VARCHAR2
IS
BEGIN
  IF p_event.geteventname () = 'xxintg.oracle.apps.sfdc.item.publish' THEN
     INSERT INTO xx_sfdc_item_out_log ( send_date
                                       ,request_id
                                       ,batch_id)
     VALUES ( SYSDATE
             ,p_event.getvalueforparameter ('REQUEST_ID')
             ,p_event.getvalueforparameter ('BATCH_ID'));
     COMMIT;
  END IF;
  RETURN 'SUCCESS';
EXCEPTION
   WHEN OTHERS THEN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'raise_publish_event -> Exception from BE'||SQLERRM);
    RETURN 'ERROR';
END;
----------------------------------------------------------------------
 PROCEDURE  process_param_value
 IS
 BEGIN
   xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXSFDCOUTBOUNDINTF'
                                              ,p_param_name      => 'ITEM_BATCH_SIZE'
                                              ,x_param_value     =>  x_batch_size);
 END process_param_value;
----------------------------------------------------------------------
PROCEDURE  call_be (p_request_id NUMBER, p_batch_id NUMBER)
IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   x_event_parameter_list   wf_parameter_list_t;
   x_event_name             VARCHAR2 (100)      := 'xxintg.oracle.apps.sfdc.item.publish';
   x_event_key              VARCHAR2 (100)      := SYS_GUID();
 BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Batch sending');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Request Id ->'||p_request_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Batch Id ->'||p_batch_id);
    x_event_parameter_list := wf_parameter_list_t ( WF_PARAMETER_T ('REQUEST_ID', p_request_id),
                                                    WF_PARAMETER_T ('BATCH_ID', p_batch_id));
    wf_event.raise ( p_event_name   => x_event_name
                    ,p_event_key    => x_event_key
                    ,p_parameters   => x_event_parameter_list);
    COMMIT;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Out Batch sending');
 EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'send_batch -> Exception while sending batch details'||SQLERRM);
 END call_be;

----------------------------------------------------------------------

PROCEDURE  send_batch (p_type VARCHAR2, p_request_id NUMBER)
IS
  CURSOR c_batch_new
  IS
  SELECT DISTINCT batch_id
    FROM xx_sfdc_item_out_ctl
   WHERE request_id = p_request_id;

  CURSOR c_batch_re
  IS
  SELECT DISTINCT batch_id
    FROM xx_sfdc_item_out_ctl
   WHERE status = 'NEW';

 BEGIN
    IF p_type = 'New' THEN
       FOR rec_new IN c_batch_new LOOP
           call_be(p_request_id,rec_new.batch_id);
       END LOOP;
    ELSE
       FOR rec_re IN c_batch_re LOOP
           call_be(p_request_id,rec_re.batch_id);
       END LOOP;
    END IF;
 EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'send_batch -> Exception while sending batch details'||SQLERRM);
 END send_batch;
----------------------------------------------------------------------
 PROCEDURE sfdc_publish_item_cp    (  p_errbuf      OUT  VARCHAR2
                                     ,p_retcode     OUT  NUMBER
                                     ,p_type        IN   VARCHAR2
                                     ,p_hidden1     IN   VARCHAR2
                                     ,p_hidden2     IN   VARCHAR2
                                     ,p_item_from   IN   NUMBER
                                     ,p_item_to     IN   NUMBER
                                     ,p_date_from   IN   VARCHAR2
                                     ,p_date_to     IN   VARCHAR2)
 IS

     CURSOR c_item( p_type        VARCHAR2
                   ,p_date_from   DATE
                   ,p_date_to     DATE
                   ,p_item_from   NUMBER
                   ,p_item_to     NUMBER)
     IS
     SELECT  msib.inventory_item_id
       FROM  xx_sfdc_item_out_v msib
       WHERE (msib.last_update_date BETWEEN p_date_from AND p_date_to AND p_type IN ('NEW'))
          OR (msib.inventory_item_id BETWEEN p_item_from AND p_item_to AND p_type IN ('RESEND'))
          AND  NOT EXISTS  ( SELECT 1
                               FROM xx_sfdc_item_out_ctl xsic
                              WHERE xsic.inventory_item_id= msib.inventory_item_id
                                AND status = 'NEW');

    TYPE xx_sfdc_item_tab IS TABLE OF XX_SFDC_ITEM_OUT_CTL%ROWTYPE
    INDEX BY BINARY_INTEGER;

    xx_sfdc_item_tab_typ   xx_sfdc_item_tab;


    CURSOR c_republish ( p_type VARCHAR2, p_date_from DATE, p_date_to DATE )
    IS
    SELECT DISTINCT batch_id
      FROM xx_sfdc_item_out_ctl
     WHERE TRUNC(creation_date) BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to)
       AND p_type IN ('Reprocess')
       AND nvl(status,'NEW' )  <> 'SUCCESS'; -- Select All Records which are not SUCCESS

    x_record_id      NUMBER;
    x_batch_id       NUMBER;
    x_counter        NUMBER :=0;
    x_cnt            NUMBER := 0;
    x_error_code     VARCHAR2(1):= xx_emf_cn_pkg.CN_SUCCESS;

    x_new_type       VARCHAR2 (20);
    x_date_from      DATE;
    x_date_to        DATE;
 BEGIN
    p_retcode     := xx_emf_cn_pkg.cn_success;
    x_error_code  := xx_emf_pkg.set_env;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Run Type         ->'||p_type);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Item From        ->'||p_item_from);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Item To          ->'||p_item_to);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Creation Date From ->'||p_date_from);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Creation Date To   ->'||p_date_to);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

    process_param_value;

    IF p_type = 'New' THEN
       IF p_item_from IS NOT NULL OR p_item_to IS NOT NULL THEN
          x_new_type := 'RESEND';
       ELSE
          x_date_to := sysdate;
          SELECT TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','ITEM_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS')
            INTO x_date_from
            FROM DUAL;
            x_new_type  := 'NEW';
       END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Starting Item Extraction');
       FOR r_item IN c_item(x_new_type, x_date_from, x_date_to,p_item_from,p_item_to)
       LOOP
          IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
              x_batch_id      := xxintg.xx_sfdc_item_batch_s.nextval;
              x_counter       := 1;
          ELSE
              x_counter := x_counter + 1;
          END IF;

          x_cnt := x_cnt + 1;
          xx_sfdc_item_tab_typ(x_cnt).record_id          := xxintg.xx_sfdc_item_out_ctl_s1.nextval;
          xx_sfdc_item_tab_typ(x_cnt).inventory_item_id  := r_item.inventory_item_id;
          xx_sfdc_item_tab_typ(x_cnt).batch_id           := x_batch_id;
          xx_sfdc_item_tab_typ(x_cnt).publish_time       := SYSDATE;
          xx_sfdc_item_tab_typ(x_cnt).publish_system     := x_publish_system;
          xx_sfdc_item_tab_typ(x_cnt).target_system      := x_target_system;
          xx_sfdc_item_tab_typ(x_cnt).status             := x_status_flag;
          xx_sfdc_item_tab_typ(x_cnt).request_id         := x_request_id;
          xx_sfdc_item_tab_typ(x_cnt).ack_time           := SYSDATE;
          xx_sfdc_item_tab_typ(x_cnt).created_by         := x_user_id;
          xx_sfdc_item_tab_typ(x_cnt).creation_date      := SYSDATE;
          xx_sfdc_item_tab_typ(x_cnt).last_update_date   := SYSDATE;
          xx_sfdc_item_tab_typ(x_cnt).last_updated_by    := x_user_id;
          xx_sfdc_item_tab_typ(x_cnt).last_update_login  := x_login_id;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Item Record Count -> '||xx_sfdc_item_tab_typ.COUNT);

       IF xx_sfdc_item_tab_typ.COUNT > 0 THEN
         FORALL i IN 1 .. xx_sfdc_item_tab_typ.COUNT
         INSERT INTO xx_sfdc_item_out_ctl
                VALUES xx_sfdc_item_tab_typ (i);
       END IF;

       IF x_new_type = 'NEW' THEN
          --Update program last run date to EMF
          UPDATE xx_emf_process_parameters
             SET parameter_value = TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
           WHERE parameter_name = 'ITEM_LAST_RUN'
             AND process_id = ( SELECT PROCESS_ID
                               FROM xx_emf_process_setup
                              WHERE process_name = 'XXSFDCOUTBOUNDINTF');
       END IF;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End Item Extraction');
       COMMIT;
       send_batch(p_type,x_request_id);
    ELSE
       IF x_date_from IS NULL THEN
          SELECT MIN(creation_date)
            INTO x_date_from
            FROM xx_sfdc_item_out_ctl;
       ELSE
          x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       END IF;

       IF x_date_to IS NULL THEN
          SELECT MAX(creation_date)
            INTO x_date_to
            FROM xx_sfdc_item_out_ctl;
       ELSE
          x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
       END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Creation Date From ->'||x_date_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Creation Date To   ->'||x_date_to);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'---------------------------------------------');

       FOR republish_rec IN c_republish (p_type, x_date_from, x_date_to )
       LOOP
         x_batch_id      := xxintg.xx_sfdc_item_batch_s.nextval;

         UPDATE xx_sfdc_item_out_ctl
            SET status               = 'NEW',
                response_message     = null,         -- Set Message as NULL
                last_update_date     = sysdate,
                last_update_login    = x_login_id,
                last_updated_by      = x_user_id,
                request_id           = x_request_id, -- Assign New Request ID
                batch_id             = x_batch_id    -- Assign New Batch
          WHERE batch_id = republish_rec.batch_id
            AND nvl(status, 'NEW')   <> 'SUCCESS';   -- Select Only not SUCCESS records
       END LOOP;
       send_batch(p_type,x_request_id);
    END IF;

 EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'sfdc_publish_item_cp -> Exception while getting item records'||SQLERRM);
 END sfdc_publish_item_cp;
END xx_sfdc_item_out_cp_pkg;
/
