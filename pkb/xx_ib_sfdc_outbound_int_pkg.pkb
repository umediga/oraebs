DROP PACKAGE BODY APPS.XX_IB_SFDC_OUTBOUND_INT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IB_SFDC_OUTBOUND_INT_PKG" 
IS
  ----------------------------------------------------------------------
  /*
  Created By : Vishal
  Creation Date : 28-Feb-2014
  File Name : XX_IB_SFDC_OUTBOUND_INT_PKG.pkb
  Description : This script creates the specification of the package
  Change History:
  Date          Name           Remarks
  -----------   ----           ---------------------------------------
  28-Feb-2014   Vishal        Initial development.
  8-Jul-2014    Vishal        Changes to exclude SO which are not interfaced
                              to SFDC
  23-Sep-2014   Bedabrata     Change for Wave2. Added Lot Number and empty batch
  */
  ----------------------------------------------------------------------
  x_user_id      NUMBER        := fnd_global.user_id;
  x_resp_id      NUMBER        := fnd_global.resp_id;
  x_resp_appl_id NUMBER        := fnd_global.resp_appl_id;
  x_login_id     NUMBER        := fnd_global.login_id;
  x_request_id   NUMBER        := fnd_global.conc_request_id;
  g_object_name  VARCHAR2 (30) := 'XXSFDCINSTBASE';
  ----------------------------------------------------------------------
PROCEDURE get_instbase_details(
    p_publish_batch_id IN NUMBER ,
    p_instance_id      IN NUMBER,
    x_ib_output_instance OUT nocopy xx_ib_sfdc_outbound_typ ,
    x_return_status OUT nocopy  VARCHAR2 ,
    x_return_message OUT nocopy VARCHAR2 )
IS
  CURSOR c_instance_info_batch_dtl (cp_publish_batch_id NUMBER)
  IS
    SELECT ib_instance_id ,
      record_id,
      publish_batch_id
    FROM xx_ib_sfdc_control_tbl
    WHERE publish_batch_id = cp_publish_batch_id;
  CURSOR c_instance_info (cp_instance_id NUMBER)
  IS
    SELECT xoohw.*
    FROM xx_ib_sfdc_detail_v xoohw
    WHERE ib_instance_id    = cp_instance_id;
  x_error_code       VARCHAR2(1) := xx_emf_cn_pkg.cn_success;
  x_publish_batch_id NUMBER      := NULL;
  x_rec_id           NUMBER      := NULL;
  x_rec_count        NUMBER      := 1;
  x_source_system    VARCHAR2 (80);
  x_target_system    VARCHAR2 (80);
  x_error_step       NUMBER := 0;
  x_ib_publish_tbl xx_ib_sfdc_staging_tbl%rowtype;
  x_publish_tabtyp xx_ib_sfdc_publish_typ_tab;
BEGIN
  x_error_step       := 1;
  x_publish_batch_id := p_publish_batch_id;
  x_return_status    := xx_emf_cn_pkg.cn_success;
  -- Emf Env initialization
  x_error_step := 2;
  x_rec_count  := 1;
  UPDATE xx_ib_sfdc_control_tbl
  SET proc_inst_id       = p_instance_id,
    last_update_date     = sysdate,
    last_update_login    = x_login_id,
    last_updated_by      = x_user_id
  WHERE publish_batch_id = x_publish_batch_id;
  SELECT DISTINCT source_system,
    target_system
  INTO x_source_system,
    x_target_system
  FROM xx_ib_sfdc_control_tbl
  WHERE publish_batch_id       = x_publish_batch_id;
  x_error_step                := 6;
  FOR instance_info_batch_rec IN c_instance_info_batch_dtl ( x_publish_batch_id )
  LOOP
    x_error_step       := 7;
    FOR r_instance_rec IN c_instance_info ( instance_info_batch_rec.ib_instance_id )
    LOOP
      x_ib_publish_tbl.record_id             := xx_ib_sfdc_staging_tbl_recid_s.nextval;
      x_ib_publish_tbl.control_record_id     := instance_info_batch_rec.record_id;
      x_ib_publish_tbl.publish_batch_id      := instance_info_batch_rec.publish_batch_id;
      x_ib_publish_tbl.ib_instance_id        := r_instance_rec.ib_instance_id;
      x_ib_publish_tbl.item                  := r_instance_rec.item;
      x_ib_publish_tbl.item_desc             := r_instance_rec.item_desc ;
      x_ib_publish_tbl.serial_number         := r_instance_rec.serial_number ;
	  x_ib_publish_tbl.lot_number            := r_instance_rec.lot_number ; -- added for wave2
      x_ib_publish_tbl.site_number           := r_instance_rec.site_number ;
      x_ib_publish_tbl.shipped_date          := r_instance_rec.shipped_date ;
      x_ib_publish_tbl.quantity              := r_instance_rec.quantity ;
      x_ib_publish_tbl.sales_order_number    := r_instance_rec.sales_order_number ;
      x_ib_publish_tbl.purchase_order_number := r_instance_rec.purchase_order_number ;
      x_ib_publish_tbl.warranty_name         := r_instance_rec.warranty_name ;
      x_ib_publish_tbl.contract_number       := r_instance_rec.contract_number ;
      x_ib_publish_tbl.warranty_status       := r_instance_rec.warranty_status ;
      x_ib_publish_tbl.warranty_start_date   := r_instance_rec.warranty_start_date ;
      x_ib_publish_tbl.warranty_end_date     := r_instance_rec.warranty_end_date ;
      x_ib_publish_tbl.creation_date         := sysdate;
      x_ib_publish_tbl.created_by            := x_user_id;
      x_ib_publish_tbl.last_update_date      := sysdate;
      x_ib_publish_tbl.last_updated_by       := x_user_id;
      x_ib_publish_tbl.last_update_login     := x_login_id;
      INSERT INTO xx_ib_sfdc_staging_tbl VALUES x_ib_publish_tbl;
    END LOOP;
  END LOOP;
  x_error_step         := 8;
  x_ib_output_instance := xx_ib_sfdc_outbound_typ(NULL,NULL,NULL,NULL);
  x_error_step         := 9;
  SELECT CAST (multiset
    (SELECT control_record_id,
      item ,
      item_desc ,
      serial_number ,
	  lot_number, -- Added for Wave2
      site_number ,
      shipped_date ,
      quantity ,
      sales_order_number ,
      purchase_order_number ,
      warranty_name ,
      contract_number ,
      warranty_status ,
      warranty_start_date ,
      warranty_end_date,
      ownership_type ,
      status ,
      manufacturer,
      ib_instance_id
    FROM xx_ib_sfdc_publish_v
    WHERE publish_batch_id = x_publish_batch_id
    ) AS xx_ib_sfdc_publish_typ_tab )
  INTO x_ib_output_instance.instance_tbl
  FROM dual;
  x_error_step                          := 10;
  x_ib_output_instance.publish_batch_id :=x_publish_batch_id;
  x_ib_output_instance.source_system    := x_source_system;
  x_ib_output_instance.target_system    := x_target_system;
  x_return_status                       := 'S';
  x_return_message                      := NULL;
  x_error_step                          := 10;
  --commit;
EXCEPTION
WHEN OTHERS THEN
  x_return_status  := 'E';
  x_return_message := sqlerrm || x_error_step;
END get_instbase_details;
-- --------------------------------------------------------------------- --
PROCEDURE update_batch(
    p_ib_input_instance IN xx_ib_sfdc_instid_in_typ_tab ,
    x_out_batch_id OUT nocopy NUMBER )
IS
  x_no NUMBER;
BEGIN
  x_no           := xx_ib_sfdc_control_tbl_batid_s.nextval;
  x_out_batch_id := x_no;
  FOR curr_rec   IN p_ib_input_instance.first .. p_ib_input_instance.last
  LOOP
    UPDATE xx_ib_sfdc_control_tbl
    SET publish_batch_id = x_no,
      last_update_date   = sysdate,
      last_update_login  = x_login_id,
      last_updated_by    = x_user_id
    WHERE record_id      = p_ib_input_instance(curr_rec).record_id;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  x_out_batch_id := -1;
END update_batch;
PROCEDURE update_instance(
    p_instance_id  IN NUMBER ,
    p_out_batch_id IN NUMBER )
IS
BEGIN
  UPDATE xx_ib_sfdc_control_tbl
  SET proc_inst_id       = p_instance_id,
    status               = 'INPROGRESS',
    last_update_date     = sysdate,
    last_update_login    = x_login_id,
    last_updated_by      = x_user_id
  WHERE publish_batch_id = p_out_batch_id;
END update_instance;
PROCEDURE update_response(
    p_error_tab IN xx_ib_sfdc_err_mess_typ_tab )
IS
BEGIN
  FOR rec IN p_error_tab.first .. p_error_tab.last
  LOOP
    UPDATE xx_ib_sfdc_control_tbl
    SET status          = p_error_tab(rec).status,
      response_message  = p_error_tab(rec).error_message,
      sfdc_id           = p_error_tab(rec).sfdc_id,
      ack_time          = sysdate,
      last_update_date  = sysdate,
      last_update_login = x_login_id,
      last_updated_by   = x_user_id
    WHERE record_id     = p_error_tab(rec).record_id ;
  END LOOP;
END;
FUNCTION xx_catch_business_event(
    p_subscription_guid IN raw ,
    p_event             IN OUT nocopy wf_event_t )
  RETURN VARCHAR2
IS
  x_instance_id NUMBER;
BEGIN
  SELECT instance_id
  INTO x_instance_id
  FROM apps.csi_item_instances cii
  WHERE instance_number = p_event.getvalueforparameter ('CUSTOMER_PRODUCT_ID');
  INSERT
  INTO xx_ib_sfdc_control_tbl
    (
      record_id,
      status,
      ib_instance_id,
      source_system,
      target_system,
      creation_date ,
      created_by,
      last_update_date,
      last_updated_by,
      last_update_login
    )
    VALUES
    (
      xx_ib_sfdc_control_tbl_recid_s.nextval,
      'NEW',
      x_instance_id,
      NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'SOURCE_SYSTEM'), 'EBIZ'),
      NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'TARGET_SYSTEM'),'SFDC'),
      sysdate,
      x_user_id,
      sysdate,
      x_user_id,
      x_login_id
    );
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  RETURN 'Error';
END xx_catch_business_event;
PROCEDURE xx_republish_ib_instance
  (
    p_errbuf OUT nocopy  VARCHAR2,
    p_retcode OUT nocopy VARCHAR2,
    p_type             IN VARCHAR2,
    p_hidden           IN VARCHAR2,
    p_ib_instance_from IN csi_item_instances.instance_number%type DEFAULT NULL,
    p_ib_instance_to   IN csi_item_instances.instance_number%type DEFAULT NULL,
    p_date_from        IN DATE DEFAULT NULL,
    p_date_to          IN DATE DEFAULT NULL
  )
IS
  CURSOR c_new_ib_instance ( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE,cp_ib_instance_from csi_item_instances.instance_number%type,cp_ib_instance_to csi_item_instances.instance_number%type)
  IS
    SELECT instance_id
    from APPS.CSI_ITEM_INSTANCES
    WHERE exists  (select 1 from XX_IB_SFDC_DETAIL_V
    where IB_INSTANCE_ID = INSTANCE_ID)
    and (last_update_date BETWEEN cp_date_from AND cp_date_to
    AND cp_type IN ('NEW'))
	OR (instance_id in (select IB_INSTANCE_ID from XX_IB_SFDC_DETAIL_V -- added contract last update check for wave2
    where cntrct_last_upd_date BETWEEN cp_date_from AND cp_date_to
    AND cp_type IN ('NEW')))
    OR (instance_number BETWEEN cp_ib_instance_from AND cp_ib_instance_to
    AND cp_type IN ('RESEND')) ;
  CURSOR c_republish_ib_instance ( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE )
  IS
    SELECT DISTINCT publish_batch_id
    FROM apps.xx_ib_sfdc_control_tbl
    WHERE TRUNC(last_update_date) BETWEEN TRUNC(cp_date_from) AND TRUNC(cp_date_to)
    and CP_TYPE in ('Reprocess')
    AND status   != 'SUCCESS';
  x_type     VARCHAR2 (20);
  x_new_type VARCHAR2 (10);
  x_ib_instance_from csi_item_instances.instance_number%type;
  x_ib_instance_to csi_item_instances.instance_number%type;
  x_date_from DATE;
  x_date_to DATE;
  x_publish_batch_id NUMBER;
  x_record_id        NUMBER;
  x_ib_instance_id csi_item_instances.instance_id%type;
  x_date VARCHAR2(50);
  l_parameter_list wf_parameter_list_t;
  x_source_system VARCHAR2 (20);
  x_target_system VARCHAR2 (20);
  x_batch_count   NUMBER;
  x_record_count  NUMBER :=0;
BEGIN
  x_date             := fnd_date.date_to_canonical (sysdate);
  x_type             := p_type;
  x_ib_instance_from := p_ib_instance_from;
  x_ib_instance_to   := p_ib_instance_to;
  x_source_system    :=NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'SOURCE_SYSTEM'), 'EBIZ');
  x_target_system    := NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'TARGET_SYSTEM'),'SFDC');
  x_batch_count      := NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'BATCH_COUNT'),200);
  fnd_file.put_line (fnd_file.log, 'Parameters ');
  fnd_file.put_line (fnd_file.log, 'Type : ' || p_type);
  fnd_file.put_line (fnd_file.log, 'Install Base Instance From : ' || p_ib_instance_from);
  fnd_file.put_line (fnd_file.log, 'Install Base Instance To   : ' || p_ib_instance_to);
  fnd_file.put_line (fnd_file.log, 'Ordered Date From: ' || p_date_from);
  fnd_file.put_line (fnd_file.log, 'Ordered Date To: ' || p_date_to);
  IF p_type                = 'New' THEN
    IF x_ib_instance_from IS NOT NULL OR x_ib_instance_to IS NOT NULL THEN
      x_new_type          := 'RESEND';
    ELSE
      x_date_to := sysdate;
      SELECT to_date (parameter_value,'DD-MON-YYYY HH:MI')
      INTO x_date_from
      FROM xx_emf_process_parameters xepp,
        xx_emf_process_setup xeps
      WHERE xepp.process_id = xeps.process_id
      AND xeps.process_name = g_object_name
      AND parameter_name    = 'LAST_RUN_DATE';
      x_new_type           := 'NEW';
    END IF;
    BEGIN
      SELECT xx_ib_sfdc_control_tbl_batid_s.nextval
      INTO x_publish_batch_id
      FROM dual;
    EXCEPTION
    WHEN OTHERS THEN
      x_publish_batch_id := NULL;
    END;
    FOR new_ib_rec IN c_new_ib_instance (x_new_type, x_date_from, x_date_to,x_ib_instance_from,x_ib_instance_to )
    LOOP
      fnd_file.put_line (fnd_file.log, 'Instance ID: ' || new_ib_rec.instance_id);
      BEGIN
        INSERT
        INTO xx_ib_sfdc_control_tbl
          (
            publish_batch_id,
            record_id,
            status,
            ib_instance_id,
            source_system,
            target_system,
            creation_date ,
            created_by,
            last_update_date,
            last_updated_by,
            last_update_login
          )
          VALUES
          (
            x_publish_batch_id,
            xx_ib_sfdc_control_tbl_recid_s.nextval,
            'NEW',
            new_ib_rec.instance_id,
            x_source_system,
            x_target_system,
            sysdate,
            x_user_id,
            sysdate,
            x_user_id,
            x_login_id
          );
        x_record_count   := x_record_count + 1;
        IF x_record_count = x_batch_count THEN
          fnd_file.put_line (fnd_file.log, 'Raising business event ..xxintg.oracle.apps.sfdc.ib ');
          l_parameter_list := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', x_publish_batch_id) );
          wf_event.raise ( p_event_name => 'xxintg.oracle.apps.sfdc.ib', p_event_key => sys_guid (), p_parameters => l_parameter_list );
          fnd_file.put_line (fnd_file.log, 'After business event ..xxintg.oracle.apps.sfdc.ib ');
          x_record_count :=0;
          BEGIN
            SELECT xx_ib_sfdc_control_tbl_batid_s.nextval
            INTO x_publish_batch_id
            FROM dual;
          EXCEPTION
          WHEN OTHERS THEN
            x_publish_batch_id := NULL;
          END;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.log, 'Exception occurred while inserting data...' );
        fnd_file.put_line (fnd_file.log, SQLCODE || '-' || sqlerrm);
      END;
    END LOOP;
    IF x_new_type = 'NEW' THEN
      UPDATE xx_emf_process_parameters
      SET parameter_value  = TO_CHAR (x_date_to,'DD-MON-YYYY HH:MI')
      WHERE parameter_name = 'LAST_RUN_DATE'
      AND process_id       =
        (SELECT xeps.process_id
        FROM xx_emf_process_setup xeps
        WHERE xeps.process_name = g_object_name
        );
    END IF;
	-- added for wave2 not to trigger for empty batch
	IF x_record_count > 0 THEN
		fnd_file.put_line (fnd_file.log, 'Raising business event ..xxintg.oracle.apps.sfdc.ib ');
		l_parameter_list := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', x_publish_batch_id) );
		wf_event.raise ( p_event_name => 'xxintg.oracle.apps.sfdc.ib', p_event_key => sys_guid (), p_parameters => l_parameter_list );
		fnd_file.put_line (fnd_file.log, 'After business event ..xxintg.oracle.apps.sfdc.ib ');
	END IF;
  ELSE
    x_date_from          := to_date(p_date_from,'DD-MON-YY');
    x_date_to            := to_date(p_date_to,'DD-MON-YY');
    FOR republish_ib_rec IN c_republish_ib_instance (x_type, x_date_from, x_date_to )
    LOOP
      FND_FILE.PUT_LINE (FND_FILE.log, ' Republish Batch ID ...' || REPUBLISH_IB_REC.PUBLISH_BATCH_ID );
        BEGIN
            SELECT xx_ib_sfdc_control_tbl_batid_s.nextval
            INTO x_publish_batch_id
            FROM dual;
          EXCEPTION
          WHEN OTHERS THEN
            x_publish_batch_id := NULL;
          END;
      UPDATE xx_ib_sfdc_control_tbl
      SET status             = 'NEW',
        last_update_date     = sysdate,
        last_update_login    = x_login_id,
        LAST_UPDATED_BY      = X_USER_ID,
        PUBLISH_BATCH_ID = X_PUBLISH_BATCH_ID,
        RESPONSE_MESSAGE = NULL
      WHERE publish_batch_id = republish_ib_rec.publish_batch_id
      and STATUS            != 'SUCCESS';
       FND_FILE.PUT_LINE (FND_FILE.log, ' New Batch ID ...' || X_PUBLISH_BATCH_ID );
      l_parameter_list      := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', X_PUBLISH_BATCH_ID) );
      wf_event.raise ( p_event_name => 'xxintg.oracle.apps.sfdc.ib', p_event_key => sys_guid (), p_parameters => l_parameter_list );
    END LOOP;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log, 'Exception occurred while resubmitting...' );
  fnd_file.put_line (fnd_file.log, SQLCODE || '-' || sqlerrm);
  p_retcode := 2;
END xx_republish_ib_instance;
END xx_ib_sfdc_outbound_int_pkg;
/
