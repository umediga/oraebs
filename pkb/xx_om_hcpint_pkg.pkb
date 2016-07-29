DROP PACKAGE BODY APPS.XX_OM_HCPINT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_HCPINT_PKG" 
AS
  ----------------------------------------------------------------------
  /*
  Created By    : IBM
  Creation Date : 04-FEB-2014
  File Name     : XX_OM_HCPINT_PKG.pkb
  Description   : This script creates the body of the package
  xx_om_hcpint_pkg
  Change History:
  Date        Name                Remarks
  ----------- -------------       -----------------------------------
  04-FEB-2014 Renjith             Initial Development
  */
  ----------------------------------------------------------------------
  x_user_id      NUMBER := fnd_global.user_id;
  x_resp_id      NUMBER := fnd_global.resp_id;
  x_resp_appl_id NUMBER := fnd_global.resp_appl_id;
  x_login_id     NUMBER := fnd_global.login_id;
  x_request_id   NUMBER := fnd_global.conc_request_id;
  x_line_count   NUMBER := 50;
  ----------------------------------------------------------------------
  FUNCTION display_line( p_tot_char NUMBER)
  RETURN VARCHAR2
  IS
  BEGIN
      RETURN rpad('-',p_tot_char,'-');
  END;
  ----------------------------------------------------------------------
PROCEDURE create_report(
    p_request_id  IN NUMBER,
    p_report_type IN VARCHAR2 )
IS
  -- To get the header records
  CURSOR c_error_headers
  IS
    SELECT total_recs_cnt,
      success_recs_cnt,
      error_recs_cnt,
      header_id,
      process_id,
      warning_recs_cnt
    FROM xx_emf_error_headers
    WHERE request_id = p_request_id;
  -- To get the batch_name records
  CURSOR c_batch_info (cp_request_id NUMBER)
  IS
    SELECT batch_id,
      request_id,
      total_cnt,
      error_cnt,
      warn_cnt,
      success_cnt
    FROM xx_emf_batch_id_rec_cnt
    WHERE request_id = cp_request_id;
  -- To Get the Identifier's parameters'value
  CURSOR c_paramters_value (cp_process_id IN NUMBER)
  IS
    SELECT parameter_value,
      parameter_name
    FROM xx_emf_process_parameters
    WHERE process_id = cp_process_id
    AND upper (parameter_name) LIKE 'IDENTI%'
    ORDER BY parameter_name;
  -- To fetch detail records
  CURSOR c_error_details (cp_header_id IN NUMBER,cp_report_type IN VARCHAR2)
  IS
    SELECT err_id record_id,
      SUBSTR (err_text, 1, 200) error_message,
      SUBSTR (err_type, 1, 11) error_code,
      SUBSTR (record_identifier_1, 1, 23) identifier1,
      --SUBSTR (record_identifier_2, 1, 23) identifier2,
      --SUBSTR (record_identifier_3, 1, 23) identifier3,
      SUBSTR (record_identifier_4, 1, 23) identifier4,
      SUBSTR (record_identifier_5, 1, 23) identifier5
    FROM xx_emf_error_details
    WHERE header_id = cp_header_id
    AND err_type    = DECODE(cp_report_type,'All',err_type, 'WARNING')
    ORDER BY error_code DESC,
      err_id;
  -- To fetch summary records
  CURSOR c_error_summary (cp_header_id IN NUMBER)
  IS
    SELECT SUBSTR (err_type, 1, 11) error_code,
      SUBSTR (err_text, 1, 200) error_message,
      COUNT (1) failure_count
    FROM xx_emf_error_details
    WHERE header_id = cp_header_id
    GROUP BY err_type,
      err_text;
  -- Local Variables
  x_conc_prog_name fnd_concurrent_programs_vl.user_concurrent_program_name%type;
  x_msg             VARCHAR2 (100);
  x_instance_name   VARCHAR2 (100);
  x_length          NUMBER;
  x_display_name    NUMBER;
  x_display_buff    NUMBER;
  x_identifier1     VARCHAR2 (100);
  x_identifier2     VARCHAR2 (100);
  x_identifier3     VARCHAR2 (100);
  x_identifer_count NUMBER := 1;
  x_resp_id         NUMBER := fnd_global.resp_id;
  x_resp_appl_id    NUMBER := fnd_global.resp_appl_id;
  -- Commented by IBM on 02-AUG-2012
  /*x_conc_label_req_id   CONSTANT VARCHAR2 (30)
  := 'Concurrent Request ID :';*/
  -- Added by IBM on 02-AUG-2012
  x_label_sysdate CONSTANT VARCHAR2 (30) := 'Date';
  -- Added by IBM on 02-AUG-2012
  x_conc_label_req_id CONSTANT VARCHAR2 (30) := 'Concurrent Request ID';
  -- Added by IBM on 02-AUG-2012
  x_conc_label_prog_name CONSTANT VARCHAR2 (30) := 'Concurrent Program Name';
  x_report_width         CONSTANT NUMBER        := 263;
  x_dis_buffer           VARCHAR2 (3000);
  x_dis1                 INTEGER;
  x_dis2                 INTEGER;
  x_display_sysdate      VARCHAR2 (30);
  x_param_count          NUMBER := 0;
  x_i                    INTEGER;
type param_type
IS
  record
  (
    parameter_name xx_emf_process_parameters.parameter_name%type,
    parameter_value xx_emf_process_parameters.parameter_value%type,
    parameter_width NUMBER );
type param_type_tab
IS
  TABLE OF param_type INDEX BY binary_integer;
  x_param_tab param_type_tab;
BEGIN
  SELECT TO_CHAR (sysdate, 'DD-MON-YYYY HH24:MI:SS')
  INTO x_display_sysdate
  FROM dual;
  fnd_file.put_line (fnd_file.log, 'Request id : ' || p_request_id);
  -- getting the user concurrent program name
  BEGIN
    SELECT fcp.user_concurrent_program_name
    INTO x_conc_prog_name
    FROM fnd_concurrent_programs_vl fcp,
      fnd_concurrent_requests fcr
    WHERE fcr.request_id          = p_request_id
    AND fcp.application_id        = fcr.program_application_id
    AND fcp.concurrent_program_id = fcr.concurrent_program_id;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.log, 'Request id not passed properly' || SQLCODE || sqlerrm );
  END;
  fnd_global.apps_initialize (user_id => fnd_profile.value ('USER_ID'), resp_id => x_resp_id, resp_appl_id => x_resp_appl_id );
  x_instance_name := fnd_profile.value ('XX_EMF_REPORT_HEADING');
  fnd_file.put_line (fnd_file.log, 'The profile value is ' || x_instance_name );
  x_length       := LENGTH (x_instance_name);
  x_display_name := (263            - (x_length)) / 2;
  x_dis1         := (x_report_width / 2) - (LENGTH (x_conc_label_req_id) + LENGTH (x_request_id)) - (LENGTH (x_conc_prog_name) / 2);
  x_dis2         := (x_report_width / 2) - (LENGTH (x_conc_prog_name) / 2) - (LENGTH (x_display_sysdate));
  x_dis_buffer   := NULL;
  x_dis_buffer   := x_label_sysdate || chr (9) || x_display_sysdate || chr (10) || x_conc_label_req_id || chr (9) || x_request_id || chr (10) || x_conc_label_prog_name || chr (9) || x_conc_prog_name;
  fnd_file.put_line (fnd_file.output, x_dis_buffer);
  x_length          := LENGTH (x_conc_prog_name);
  x_display_buff    := (x_length)       / 2;
  x_display_name    := ((x_report_width - (x_length)) / 2) - x_display_buff;
  x_dis_buffer      := NULL;
  FOR rec_error_hdr IN c_error_headers
  LOOP
    x_dis_buffer := NULL;
    x_dis_buffer := 'Processed records' || chr (9) || rec_error_hdr.total_recs_cnt || chr (10) || 'Success records' || chr (9) || rec_error_hdr.success_recs_cnt || chr (10) || 'Warning records' || chr (9) || rec_error_hdr.warning_recs_cnt || chr (10) || 'Failed records' || chr (9) || rec_error_hdr.error_recs_cnt || chr (10) || chr (10);
    fnd_file.put_line (fnd_file.output, x_dis_buffer);
    x_length       := LENGTH (x_conc_prog_name);
    x_display_buff := (x_length)       / 2;
    x_display_name := ((x_report_width - (x_length)) / 2) - x_display_buff;
    fnd_file.put_line (fnd_file.output, chr (9) || 'SUMMARY SECTION' );
    fnd_file.put_line (fnd_file.output, chr (9) || display_line(20 ));
    x_dis_buffer := NULL;
    x_dis_buffer := chr (9) || rpad('Distinct Error Code',25) || chr (9) || rpad('Distinct Message',25) || chr (9) || 'Record Count';
    fnd_file.put_line (fnd_file.output, x_dis_buffer);
    fnd_file.put_line (fnd_file.output, chr (9) || display_line(80 ));
    -- Added by IBM on 02-AUG-2012
    FOR rec_error_sumry IN c_error_summary (rec_error_hdr.header_id)
    LOOP
      x_dis_buffer := NULL;
      x_dis_buffer := chr (9) || rpad(rec_error_sumry.error_code,25) || chr (9) || rpad(SUBSTR(rec_error_sumry.error_message,1,25),25) || chr (9) || rec_error_sumry.failure_count;
      fnd_file.put_line (fnd_file.output, x_dis_buffer);
    END LOOP;
    -- Added by IBM on 02-AUG-2012
    fnd_file.put_line (fnd_file.output, chr (10));
    fnd_file.put_line (fnd_file.output, chr (9) || 'DETAIL SECTION' );
    fnd_file.put_line (fnd_file.output, chr (9) || display_line(20 ));
    -- To get the parameter's value
    x_param_count            := 0;
    FOR rec_parameters_value IN c_paramters_value (rec_error_hdr.process_id)
    LOOP
      x_param_tab (x_param_count   + 1).parameter_name  := rec_parameters_value.parameter_name;
      x_param_tab (x_param_count   + 1).parameter_value := rec_parameters_value.parameter_value;
      IF (x_param_count            + 1)                 <= 3 THEN
        x_param_tab (x_param_count + 1).parameter_width := 15;
      ELSE
        x_param_tab (x_param_count + 1).parameter_width := 15;
      END IF;
      x_param_count := x_param_count + 1;
    END LOOP;
    --- Parameters are required to display identifier's in output report
    IF x_param_count = 0 THEN
      fnd_file.put_line (fnd_file.log, 'Setup is missing for record identifier' || '''' || 's' );
    END IF;
    -- End of parameter's value
    -- To display 8th line(Error details)
    x_dis_buffer    := NULL;
    IF x_param_count > 0 THEN
      FOR x_i       IN 1 .. x_param_count
      LOOP
        x_dis_buffer := x_dis_buffer || chr (9) || rpad(x_param_tab (x_i).parameter_value,25);
      END LOOP;
    END IF;
    x_dis_buffer := x_dis_buffer || chr (9) || chr (9) || rpad('Error Message',25) || chr (9) || 'Error Code';
    fnd_file.put_line (fnd_file.output, x_dis_buffer);
    fnd_file.put_line (fnd_file.output, chr (9) || display_line(200 ));
    -- Error details record loop started
    FOR rec_error_dtl IN c_error_details (rec_error_hdr.header_id,p_report_type)
    LOOP
      x_dis_buffer    := '';
      IF x_param_count > 0 THEN
        FOR x_i       IN 1 .. x_param_count
        LOOP
          CASE x_i
          WHEN 1 THEN
            x_dis_buffer := x_dis_buffer || chr (9) || rpad(rec_error_dtl.identifier1,25);
          --WHEN 2 THEN
            --x_dis_buffer := x_dis_buffer || chr (9) || rpad(rec_error_dtl.identifier2,25);
          --WHEN 3 THEN
            --x_dis_buffer := x_dis_buffer || chr (9) || rpad(rec_error_dtl.identifier3,25);
          WHEN 4 THEN
            x_dis_buffer := x_dis_buffer || chr (9) || rpad(rec_error_dtl.identifier4,25);
          WHEN 5 THEN
            x_dis_buffer := x_dis_buffer || chr (9) || rpad(rec_error_dtl.identifier5,25);
          END CASE;
        END LOOP;
        x_dis_buffer := x_dis_buffer || chr (9) || chr (9) || rpad(rec_error_dtl.error_message,25) || chr (9) || rec_error_dtl.error_code;
      END IF;
      fnd_file.put_line (fnd_file.output, x_dis_buffer);
    END LOOP;
  END LOOP;
END create_report;
----------------------------------------------------------------------
PROCEDURE write_emf_log_high(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
----------------------------------------------------------------------
PROCEDURE write_emf_log_low(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
----------------------------------------------------------------------
PROCEDURE write_emf_error_warning(
    p_debug_text  IN VARCHAR2,
    p_category    IN VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_warning ,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_low, p_category, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
----------------------------------------------------------------------
PROCEDURE write_emf_error_success(
    p_debug_text  IN VARCHAR2,
    p_category    IN VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_normal ,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  --XX_EMF_PKG.WRITE_LOG ( XX_EMF_CN_PKG.CN_HIGH, P_DEBUG_TEXT,P_ATTRIBUTE1,P_ATTRIBUTE2,P_ATTRIBUTE3,P_ATTRIBUTE4,P_ATTRIBUTE5,P_ATTRIBUTE6,P_ATTRIBUTE7,P_ATTRIBUTE8,P_ATTRIBUTE9,P_ATTRIBUTE10);
  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_low, p_category, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
----------------------------------------------------------------------
PROCEDURE main(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT NUMBER ,
    p_update   IN VARCHAR2 ,
    p_inactive IN VARCHAR2 ,
    p_insert   IN VARCHAR2 ,
    p_report   IN VARCHAR2)
IS
  CURSOR cur_hcp_iexpense_data_dw
  IS
    SELECT *  FROM itgr_hcp_iexpense_data_dw;

  CURSOR cur_xxintg_hcp_iexpense_main (p_npi VARCHAR2)
  IS
    --SELECT * FROM xxintg_hcp_iexpense_main WHERE npi = p_npi FOR UPDATE;
    SELECT * FROM XXINTG_HCP_INT_MAIN WHERE npi = p_npi FOR UPDATE;

  CURSOR cur_xxintg_hcp_data_dw IS
  select * from itgr_hcp_iexpense_data_dw where nvl(orgname,'x') <> '\N' order by npi, hms_piid desc;

  CURSOR cur_xxintg_hcp_ins (p_npi varchar2) IS
  --select * from xxintg_hcp_iexpense_main where nvl(npi,hms_piid) = p_npi;
  select * from XXINTG_HCP_INT_MAIN where nvl(npi,hms_piid) = p_npi;

  --x_xxintg_hcp_ins xxintg_hcp_iexpense_main%rowtype;
  x_xxintg_hcp_ins XXINTG_HCP_INT_MAIN%rowtype;

  CURSOR cur_xxintg_hcp_inact IS
  --select * from xxintg_hcp_iexpense_main ma where active_flag = 'Y'
  select * from XXINTG_HCP_INT_MAIN ma where active_flag = 'Y' and hms_piid is not null
    and not exists(select 'x' from itgr_hcp_iexpense_data_dw  where nvl(npi,hms_piid) = nvl(ma.npi,ma.hms_piid)) FOR UPDATE;

  --x_xxintg_hcp_inact xxintg_hcp_iexpense_main%rowtype;
  x_xxintg_hcp_inact XXINTG_HCP_INT_MAIN%rowtype;

  CURSOR cur_xxintg_hcp_upd_npi IS
  --select * from XXINTG_HCP_IEXPENSE_MAIN ma
  select * from XXINTG_HCP_INT_MAIN ma
   where npi is not null
     and not exists (select 'x' from ITGR_HCP_IEXPENSE_DATA_DW where npi = ma.npi and nvl(doctors_first_name,'x') = nvl(ma.doctors_first_name,'x')
                        and nvl(doctors_last_name,'x') = nvl(ma.doctors_last_name,'x') and nvl(doctors_middle_name,'x') = nvl(ma.doctors_middle_name,'x'))
     and exists (select 'x' from ITGR_HCP_IEXPENSE_DATA_DW where npi = ma.npi and (nvl(doctors_first_name,'x') <> nvl(ma.doctors_first_name,'x')
                    OR nvl(doctors_last_name,'x') <> nvl(ma.doctors_last_name,'x') OR nvl(doctors_middle_name,'x') = nvl(ma.doctors_middle_name,'x'))) FOR UPDATE ;

  CURSOR cur_xxintg_hcp_upd_hms_piid IS
  --select * from XXINTG_HCP_IEXPENSE_MAIN ma
  select * from XXINTG_HCP_INT_MAIN ma
   where npi is null
     and not exists (select 'x' from ITGR_HCP_IEXPENSE_DATA_DW where hms_piid = ma.hms_piid and npi is null
                     and nvl(doctors_first_name,'x') = nvl(ma.doctors_first_name,'x') and nvl(doctors_last_name,'x') = nvl(ma.doctors_last_name,'x') and nvl(doctors_middle_name,'x') = nvl(ma.doctors_middle_name,'x'))
     and exists (select 'x' from ITGR_HCP_IEXPENSE_DATA_DW where hms_piid = ma.hms_piid and (nvl(doctors_first_name,'x') <> nvl(ma.doctors_first_name,'x')
                 OR nvl(doctors_last_name,'x') <> nvl(ma.doctors_last_name,'x') OR nvl(doctors_middle_name,'x') = nvl(ma.doctors_middle_name,'x')
                 OR nvl(npi,'x')<> nvl(ma.npi,'x') )) FOR UPDATE;

  --x_xxintg_hcp_upd xxintg_hcp_iexpense_main%rowtype;
  x_xxintg_hcp_upd XXINTG_HCP_INT_MAIN%rowtype;

  x_ret_status    VARCHAR2(1);
  x_error_message VARCHAR(3000);
  x_error_code    VARCHAR2(1) := xx_emf_cn_pkg.cn_success;
  --x_xxintg_hcp_iexpense_main xxintg_hcp_iexpense_main%rowtype;
  x_xxintg_hcp_iexpense_main XXINTG_HCP_INT_MAIN%rowtype;
BEGIN
  p_retcode := xx_emf_cn_pkg.cn_success;
  -- Emf Env initialization
  x_error_code := xx_emf_pkg.set_env;
  write_emf_log_high(p_debug_text => '------------------------------------------');
  write_emf_log_high(p_debug_text => 'Update Flag         -> '||p_update);
  write_emf_log_high(p_debug_text => 'Insert  Flag        -> '||p_insert);
  write_emf_log_high(p_debug_text => 'Inactive Flag       -> '||p_inactive);
  write_emf_log_high(p_debug_text => 'Report  Flag        -> '||p_report);
  write_emf_log_high(p_debug_text => '------------------------------------------');
  -- Update
  IF p_update = 'Y' THEN
    write_emf_log_high(p_debug_text => '------------------------------------------');
    write_emf_log_high(p_debug_text => '----------- Update Log-----------');

    OPEN cur_xxintg_hcp_upd_npi;
      LOOP
      FETCH cur_xxintg_hcp_upd_npi INTO x_xxintg_hcp_upd;
      EXIT WHEN cur_xxintg_hcp_upd_npi%notfound;
        BEGIN
          --UPDATE XXINTG_HCP_IEXPENSE_MAIN
          UPDATE XXINTG_HCP_INT_MAIN
          SET (doctors_last_name, doctors_first_name, doctors_middle_name, hms_piid,request_id,last_update_date,last_updated_by,last_update_login) =
              (select doctors_last_name, doctors_first_name, doctors_middle_name, hms_piid, x_request_id, sysdate, x_user_id, x_login_id
                 from ITGR_HCP_IEXPENSE_DATA_DW where npi = x_xxintg_hcp_upd.npi and rownum =1 )
          WHERE CURRENT OF cur_xxintg_hcp_upd_npi;
          write_emf_error_success(p_debug_text => ' Updated(npi) success' , p_attribute1 => x_xxintg_hcp_upd.npi , p_attribute2 => x_xxintg_hcp_upd.hms_piid );
        EXCEPTION
        WHEN OTHERS THEN
          p_retcode := xx_emf_cn_pkg.cn_rec_warn;
          write_emf_error_warning(p_debug_text => ' Error ' || sqlerrm , p_attribute1 => x_xxintg_hcp_upd.npi , p_attribute2 => x_xxintg_hcp_upd.hms_piid );
        END;
    END LOOP;
    CLOSE cur_xxintg_hcp_upd_npi;

    OPEN cur_xxintg_hcp_upd_hms_piid;
      LOOP
      FETCH cur_xxintg_hcp_upd_hms_piid INTO x_xxintg_hcp_upd;
      EXIT WHEN cur_xxintg_hcp_upd_hms_piid%notfound;
        BEGIN
          --UPDATE XXINTG_HCP_IEXPENSE_MAIN
          UPDATE XXINTG_HCP_INT_MAIN
          SET (doctors_last_name, doctors_first_name, doctors_middle_name, hms_piid,request_id,last_update_date,last_updated_by,last_update_login) =
              (select doctors_last_name, doctors_first_name, doctors_middle_name, hms_piid, x_request_id, sysdate, x_user_id, x_login_id
                 from ITGR_HCP_IEXPENSE_DATA_DW where npi = x_xxintg_hcp_upd.npi and rownum =1 )
          WHERE CURRENT OF cur_xxintg_hcp_upd_hms_piid;
          write_emf_error_success(p_debug_text => ' Updated(hms) success' , p_attribute1 => x_xxintg_hcp_upd.npi , p_attribute2 => x_xxintg_hcp_upd.hms_piid );
        EXCEPTION
        WHEN OTHERS THEN
          p_retcode := xx_emf_cn_pkg.cn_rec_warn;
          write_emf_error_warning(p_debug_text => ' Error ' || sqlerrm , p_attribute1 => x_xxintg_hcp_upd.npi , p_attribute2 => x_xxintg_hcp_upd.hms_piid );
        END;
    END LOOP;
    CLOSE cur_xxintg_hcp_upd_hms_piid;

    write_emf_log_high(p_debug_text => '----------- End Update Log-----------');
    write_emf_log_high(p_debug_text => '------------------------------------------');
  END IF;
  -- Inactive
  IF p_inactive = 'Y' THEN
    write_emf_log_high(p_debug_text => '------------------------------------------');
    write_emf_log_high(p_debug_text => '----------- Inactive Log-----------');
    --FOR rec_xxintg_hcp_inact IN cur_xxintg_hcp_inact
    OPEN cur_xxintg_hcp_inact;
    LOOP
      FETCH cur_xxintg_hcp_inact INTO x_xxintg_hcp_inact;
      EXIT WHEN cur_xxintg_hcp_inact%notfound;
        BEGIN
          --UPDATE xxintg_hcp_iexpense_main
          UPDATE XXINTG_HCP_INT_MAIN
          SET active_flag     = 'N',
            end_date          = sysdate ,
            request_id        =x_request_id ,
            last_update_date  = sysdate ,
            last_updated_by   = x_user_id ,
            last_update_login = x_login_id
          WHERE CURRENT OF cur_xxintg_hcp_inact;
          write_emf_error_success(p_debug_text => ' Update Success' , p_attribute1 => x_xxintg_hcp_inact.npi , p_attribute2 => x_xxintg_hcp_inact.hms_piid );
        EXCEPTION
        WHEN OTHERS THEN
          p_retcode := xx_emf_cn_pkg.cn_rec_warn;
          write_emf_error_warning(p_debug_text => ' Error' || sqlerrm , p_attribute1 => x_xxintg_hcp_inact.npi , p_attribute2 => x_xxintg_hcp_inact.hms_piid );
        END;
    END LOOP;
    CLOSE cur_xxintg_hcp_inact;
    write_emf_log_high(p_debug_text => '----------- End Inactive Log-----------');
    write_emf_log_high(p_debug_text => '------------------------------------------');
  END IF;
  -- Insert
  IF p_insert = 'Y' THEN
    write_emf_log_high(p_debug_text => '------------------------------------------');
    write_emf_log_high(p_debug_text => '----------- Insert Log-----------');
    FOR rec_hcp_data_dw IN cur_xxintg_hcp_data_dw
    LOOP
      OPEN cur_xxintg_hcp_ins(nvl(rec_hcp_data_dw.npi,rec_hcp_data_dw.hms_piid));
      FETCH cur_xxintg_hcp_ins INTO x_xxintg_hcp_ins;
      IF cur_xxintg_hcp_ins%notfound THEN
        INSERT
        --INTO xxintg_hcp_iexpense_main
        INTO XXINTG_HCP_INT_MAIN
          (
            rec_id ,
            npi ,
            doctors_last_name ,
            doctors_first_name ,
            doctors_middle_name ,
            hms_piid ,
            active_flag ,
            start_date ,
            end_date ,
            skin_certified ,
            request_id ,
            creation_date ,
            created_by ,
            last_update_date ,
            last_updated_by ,
            last_update_login
          )
          VALUES
          (
            xxom_hcp_iexpense_s.nextval --rec_id
            ,rec_hcp_data_dw.npi --npi
            ,rec_hcp_data_dw.doctors_last_name --doctors_last_name
            ,rec_hcp_data_dw.doctors_first_name --doctors_first_name
            ,rec_hcp_data_dw.doctors_middle_name --doctors_middle_name
            ,rec_hcp_data_dw.hms_piid --hms_piid
            ,'Y' --active_flag
            ,sysdate --start_date
            ,NULL --end_date
            ,'N'--NULL --skin_certified
            ,x_request_id --request_id
            ,sysdate --creation_date
            ,x_user_id --created_by
            ,sysdate --last_update_date
            ,x_user_id --last_updated_by
            ,x_login_id --last_update_login
          );
        write_emf_error_success(p_debug_text => ' Inserted ', p_attribute1 => rec_hcp_data_dw.npi , p_attribute2 => rec_hcp_data_dw.hms_piid );
      ELSE
        write_emf_error_warning(p_debug_text => ' Exists ', p_attribute1 => rec_hcp_data_dw.npi , p_attribute2 => rec_hcp_data_dw.hms_piid );
      END IF;
      CLOSE cur_xxintg_hcp_ins;
    END LOOP;
    write_emf_log_high(p_debug_text => '----------- End Insert Log-----------');
    write_emf_log_high(p_debug_text => '------------------------------------------');
  END IF;
  create_report(x_request_id,p_report);
EXCEPTION
WHEN OTHERS THEN
  write_emf_log_high(p_debug_text => 'Exception' || SUBSTR (sqlerrm, 1, 2000));
  p_retcode := xx_emf_cn_pkg.cn_rec_warn;
END main;
END xx_om_hcpint_pkg;
/
