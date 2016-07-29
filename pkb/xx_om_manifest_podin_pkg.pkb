DROP PACKAGE BODY APPS.XX_OM_MANIFEST_PODIN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_MANIFEST_PODIN_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 25-May-2012
 File Name     : XX_OM_MANIFEST_PODIN_INT.pkb
 Description   : This script creates the specification of the package
                 xx_om_manifest_podin_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 20-Jun-2012 Prabhakar             Initial Version
 10-Oct-2012 Renjith               Changes as per new manifest design
 08-Nov-2013 Renjith               Changes as per wave1 changes
 30-Jan-2013 Renjith               Changes as per new file format
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;

   ----------------------------------------------------------------------

   FUNCTION next_field ( p_line_buffer     IN       VARCHAR2
                        ,p_delimiter       IN       VARCHAR2
                        ,x_last_position   IN OUT   NUMBER)
   RETURN VARCHAR2
   IS
      x_new_position     NUMBER(6)       := NULL;
      x_out_field        VARCHAR2(20000) := NULL;
      x_delimiter        VARCHAR2(200)   := p_delimiter;
      x_delimiter_size   NUMBER(2)       := 1;
   BEGIN
      x_new_position := INSTR (p_line_buffer, x_delimiter, x_last_position);

      --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_new_position->'||x_new_position);

      IF x_new_position = 0 THEN
         x_new_position := LENGTH (p_line_buffer) + 1;
      END IF;

      x_out_field := SUBSTR (p_line_buffer, x_last_position, x_new_position - x_last_position);

      x_out_field := LTRIM (RTRIM (x_out_field));

      --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_out_field->'||x_out_field);

      IF x_new_position = LENGTH (p_line_buffer) + 1 THEN
         x_last_position := 0;
      ELSE
         x_last_position := x_new_position + x_delimiter_size;
      END IF;

      RETURN x_out_field;
   EXCEPTION
       WHEN OTHERS THEN
          x_last_position := -1;
          RETURN ' Error :'||SQLERRM;
   END next_field;

   ----------------------------------------------------------------------

   FUNCTION get_emf_email_id ( p_process_name   IN       VARCHAR2,
                               x_email_id       OUT      VARCHAR2)
   RETURN NUMBER
   IS
      x_error_code   NUMBER          := xx_emf_cn_pkg.cn_success;
   BEGIN
      SELECT notification_group
        INTO x_email_id
        FROM xx_emf_process_setup
       WHERE process_name = p_process_name;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,x_email_id);
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,'Error In getting Email Id' || ' ' || SQLERRM);
         RETURN 2;
   END get_emf_email_id;

   ----------------------------------------------------------------------

   FUNCTION move_file_archive
   RETURN NUMBER
   IS
      x_error_code        NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_msg         VARCHAR2 (2000);
      x_email_id          VARCHAR2 (200);
      CURSOR c_name
      IS
      SELECT  DISTINCT file_name name
        FROM  xx_om_manifest_pod_tmp
       WHERE  request_id = x_request_id;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Moving File ->'||FND_GLOBAL.CONC_REQUEST_ID);
      BEGIN
        FOR r_name IN c_name LOOP
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'File ->'||r_name.name);
           BEGIN
              UTL_FILE.frename ( G_DATA_DIR
                                ,r_name.name
                                ,G_ARCH_DIR
                                ,r_name.name
                                ,FALSE
                               );
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Successfully Move File :'||r_name.name);

           EXCEPTION
             WHEN OTHERS THEN
                 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'move_file_archive ' || SQLERRM);
                 x_error_msg := 'Moving File :' || r_name.name || ' Error:' || SQLERRM;
                 x_error_code_temp := get_emf_email_id (xx_emf_pkg.g_process_name, x_email_id);
                -- x_error_code := find_max (x_error_code, x_error_code_temp);
                 IF x_email_id IS NOT NULL THEN
                    xx_intg_mail_util_pkg.mail ( sender     => 'POD Manifest Interface'
                                                ,recipients => x_email_id
                                                ,subject    => 'Moving File Error - SQLERRM'
                                                ,message    => x_error_msg
                                               );
                 END IF;
                 x_error_code_temp:= xx_emf_cn_pkg.CN_REC_WARN;
           END;
        END LOOP;
        RETURN x_error_code;
   EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error in move_file_archive ' || SQLERRM);
            x_error_msg := 'move_file_archive Error:' || SQLERRM;
            x_error_code_temp := get_emf_email_id (xx_emf_pkg.g_process_name, x_email_id);
            --x_error_code := find_max (x_error_code, x_error_code_temp);

            IF x_email_id IS NOT NULL THEN
                    xx_intg_mail_util_pkg.mail ( sender     => 'POD Manifest Interface'
                                                ,recipients => x_email_id
                                                ,subject    => 'Moving File Error - SQLERRM'
                                                ,message    => x_error_msg
                                               );
            END IF;
            x_error_code_temp:= xx_emf_cn_pkg.CN_REC_WARN;
        END;
        --x_error_code := find_max (x_error_code, x_error_code_temp);
        RETURN x_error_code;
   END move_file_archive;


   ----------------------------------------------------------------------
   PROCEDURE utl_read_insert_stg( x_error_code    OUT   NUMBER
                                 ,x_error_msg     OUT   VARCHAR2)
   IS
       CURSOR  c_data_dir(p_dir VARCHAR2)
       IS
       SELECT  directory_path
         FROM  all_directories
        WHERE  directory_name= p_dir;

       CURSOR  c_file_list
       IS
       SELECT  name
         FROM  xxdirlist;


       x_file_type                 UTL_FILE.FILE_TYPE;
       x_line                      VARCHAR2(3000);

       x_pos                       NUMBER := 1;
       x_record_number             NUMBER := 0;
       x_insert_count              NUMBER := 0;
       x_rec_cntr                  NUMBER := 0;
       x_cntr                      NUMBER := 0;
       x_file_line                 VARCHAR2(30000);
       x_filename                  VARCHAR2(100);
       x_delimeter                 VARCHAR2(10) := '|';

       x_data_path                 VARCHAR2(300);

       x_data_rec                  G_XX_OM_POD_TAB_TYPE;
       x_file_list                 c_file_list%ROWTYPE;

       x_file                      VARCHAR2(50);
       x_file_yn_flag              VARCHAR2(1) := 'N';
       x_exists                    BOOLEAN;
       x_file_length               NUMBER;
       x_size                      NUMBER;
   BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside utl_read_insert_stg');
       DELETE FROM xx_om_manifest_pod_tmp;
       COMMIT;

       OPEN  c_data_dir(G_DATA_DIR);
       FETCH c_data_dir INTO x_data_path;
       IF c_data_dir%NOTFOUND THEN
         x_data_path := NULL;
       END IF;
       CLOSE c_data_dir;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_data_path ->'||x_data_path);

       xxlist_directory (x_data_path);

       OPEN  c_file_list;
       FETCH c_file_list INTO x_file_list;
       IF c_file_list%NOTFOUND THEN
         null;
       END IF;
       CLOSE c_file_list;

       IF g_data_dir IS NOT NULL THEN
          dbms_output.put_line('Data Dir ->'||G_DATA_DIR);
          FOR r_file_list IN c_file_list LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'File ->'||r_file_list.name);
              x_file_yn_flag := 'N';
              BEGIN
                x_file_type := UTL_FILE.FOPEN(G_DATA_DIR, r_file_list.name, 'R');
              EXCEPTION
                  WHEN UTL_FILE.invalid_path THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'Invalid Path for File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_filehandle THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  :=  'File handle is invalid for File :' || r_file_list.name;
                  WHEN UTL_FILE.read_error THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'Unable to read the File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_operation THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'File could not be opened :' || r_file_list.name;
                     UTL_FILE.fgetattr ( G_DATA_DIR
                                        ,r_file_list.name
                                        ,x_exists
                                        ,x_file_length
                                        ,x_size);

                     IF x_exists THEN
                        x_error_msg := 'File '||r_file_list.name || 'exists ';
                     ELSE
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'File '||r_file_list.name || ' File Does not exits ';
                        x_file_yn_flag := 'Y';
                     END IF;
                  WHEN UTL_FILE.file_open THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'Unable to Open File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_maxlinesize THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'File ' || r_file_list.name;
                  WHEN UTL_FILE.access_denied THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'Access denied for File :' || r_file_list.name;
                  WHEN OTHERS THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := r_file_list.name || SQLERRM;
              END; -- End of File open exception
              --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Code->'||x_error_code||'Exits Flag-> '||x_file_yn_flag);

              IF NVL(x_error_code,0) = 0 AND NVL(x_file_yn_flag,'N') <> 'Y' THEN
                 LOOP
                    BEGIN
                       BEGIN
                         UTL_FILE.GET_LINE(x_file_type, x_line);
                       EXCEPTION WHEN NO_DATA_FOUND THEN
                         EXIT;
                       END;
                       --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_rec_cntr->'||x_rec_cntr);
                       --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Line      ->'||x_line);
                       x_rec_cntr := x_rec_cntr + 1;
                       x_pos := 1;

                       IF x_rec_cntr >= 14 THEN
                          --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside');
                          x_cntr := x_cntr + 1;
                          x_data_rec (x_cntr).record_id           := xx_om_manifest_tmp_s.nextval;
                          x_data_rec (x_cntr).consignee           := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).shipper             := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).sender_address      := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).sender_city         := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).sender_state        := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).sender_country      := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).service_type        := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).carrier             := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).modef               := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).zonef               := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).billing_option      := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).shipped             := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).delivery_date       := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).delivery_time       := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).trackingno          := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).status              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).fedex_office        := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).refused             := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).signed_by           := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref1                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref2                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref4                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref5                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref6                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref7                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref8                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref9                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).ref10               := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).weight              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).file_name           := r_file_list.name;
                       END IF;
                    EXCEPTION
                        WHEN UTL_FILE.invalid_filehandle THEN
                             x_error_code := xx_emf_cn_pkg.cn_prc_err;
                             x_error_msg  :=  'File handle is invalid for File :' || r_file_list.name;
                        WHEN OTHERS THEN
                             x_error_msg := x_error_msg || SQLERRM;
                             x_error_code := xx_emf_cn_pkg.cn_rec_err;
                             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_HIGH,'Error While Reading Line ' || x_rec_cntr||SQLERRM);
                             EXIT;
                    END;
                 END LOOP;
              END IF; -- flag and error code
              UTL_FILE.fclose (x_file_type);
          END LOOP; -- file loop
       END IF; -- dir check

       --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Rec Count ->'||x_data_rec.COUNT);

       --FOR i IN 15 .. x_data_rec.COUNT
       FOR i IN 1 .. x_data_rec.COUNT
       LOOP
          --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_data_rec (i).record_id );

          BEGIN
             INSERT INTO XX_OM_MANIFEST_POD_TMP
             ( record_id
              ,file_name
              ,consignee
              ,shipper
              --,sender_address
              --,sender_city
              --,sender_state
              --,sender_country
              --,service_type
              ,carrier
              ,modef
              ,zonef
              ,billing_option
              ,shipped
              ,delivery_date
              ,delivery_time
              ,trackingno
              ,status
              ,fedex_office
              ,refused
              ,signed_by
              ,ref1
              ,ref2
              ,ref3
              ,ref4
              ,ref5
              ,ref6
              ,ref7
              ,ref8
              ,ref9
              ,ref10
              ,weight
              ,created_by
              ,creation_date
              ,last_update_date
              ,last_updated_by
              ,last_update_login
              ,request_id
              )
             VALUES
             ( x_data_rec (i).record_id
              ,x_data_rec (i).file_name
              ,x_data_rec (i).consignee
              ,x_data_rec (i).shipper
              --,x_data_rec (i).sender_address
              --,x_data_rec (i).sender_city
              --,x_data_rec (i).sender_state
              --,x_data_rec (i).sender_country
              --,x_data_rec (i).service_type
              ,x_data_rec (i).carrier
              ,x_data_rec (i).modef
              ,x_data_rec (i).zonef
              ,x_data_rec (i).billing_option
              ,x_data_rec (i).shipped
              ,x_data_rec (i).delivery_date
              ,x_data_rec (i).delivery_time
              ,x_data_rec (i).trackingno
              ,x_data_rec (i).status
              ,x_data_rec (i).fedex_office
              ,x_data_rec (i).refused
              ,x_data_rec (i).signed_by
              ,x_data_rec (i).ref1
              ,x_data_rec (i).ref2
              ,x_data_rec (i).ref3
              ,x_data_rec (i).ref4
              ,x_data_rec (i).ref5
              ,x_data_rec (i).ref6
              ,x_data_rec (i).ref7
              ,x_data_rec (i).ref8
              ,x_data_rec (i).ref9
              ,x_data_rec (i).ref10
              ,x_data_rec (i).weight
              ,FND_GLOBAL.USER_ID
              ,SYSDATE
              ,SYSDATE
              ,FND_GLOBAL.USER_ID
              ,x_login_id
              ,x_request_id
              );
          EXCEPTION WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting to tmp table' ||SQLERRM);
             xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
             x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
             x_error_msg := 'Error while inserting to tmp table ' ||SQLERRM;
          END;
       END LOOP;
       COMMIT;

       FOR i IN 1 .. x_data_rec.COUNT
       LOOP
          IF x_data_rec (i).trackingno IS NOT NULL THEN
             BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'---------------------------------------------');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'file_name->'||x_data_rec (i).file_name);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'tracking_no->'||x_data_rec (i).trackingno);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'revrec_comments->'||TO_CHAR(SYSDATE)||' '||x_request_id||' '||'POD File');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'revrec_reference_document->'||x_data_rec (i).file_name);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'revrec_signature->'||x_data_rec (i).signed_by);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'revrec_signature_date->'||to_date(x_data_rec (i).delivery_date,'MM/DD/YYYY'));
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'pod_received_date->'||SYSDATE);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_request_id->'||x_request_id);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'attribute20->'||x_data_rec (i).record_id);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'---------------------------------------------');

                INSERT INTO XX_OM_MANIFEST_POD_INT
                  ( file_name
                   ,tracking_no
                   ,revrec_comments
                   ,revrec_reference_document
                   ,revrec_signature
                   ,revrec_signature_date
                   ,pod_received_date
                   ,request_id
                   ,attribute20
                  )
                VALUES
                 ( x_data_rec (i).file_name
                  ,x_data_rec (i).trackingno
                  ,TO_CHAR(SYSDATE)||' '||x_request_id||' '||'POD File'
                  ,x_data_rec (i).file_name
                  ,x_data_rec (i).signed_by
                  ,to_date(x_data_rec (i).delivery_date,'MM/DD/YYYY')
                  ,SYSDATE
                  ,x_request_id
                  ,x_data_rec (i).record_id
                 );
             EXCEPTION WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting to Int table ID ->' ||x_data_rec (i).record_id||'-'||SQLERRM);
             END;
          END IF;
       END LOOP;
       COMMIT;
   EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while reading File: ' ||SQLERRM);
          xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          x_error_msg := 'Error while reading File: ' ||SQLERRM;
   END utl_read_insert_stg;

   ----------------------------------------------------------------------

   PROCEDURE line_modifer( p_header_id       IN     NUMBER
                          ,p_line_id         IN     NUMBER
                          ,p_flag            IN     VARCHAR2
                          ,x_return_status   OUT    VARCHAR2
                          ,x_error_msg       OUT    VARCHAR2)

   IS
       CURSOR c_pod_update
          IS
       SELECT  xosm.revrec_comments
              ,xosm.revrec_signature
              ,xosm.revrec_reference_document
              ,xosm.revrec_signature_date
         FROM  xx_om_manifest_pod_int xosm
        WHERE  xosm.line_id  = p_line_id
          AND  xosm.header_id  = p_header_id
          AND  xosm.process_flag IS NULL;

       x_user_error                   EXCEPTION;
       x_api_version_number           NUMBER  := 1.0;
       x_msg_count                    NUMBER;
       x_msg_data                     VARCHAR2 (2000);
       x_error                        EXCEPTION;

       -- IN Variables --
       x_header_rec                   oe_order_pub.header_rec_type;
       x_line_tbl                     oe_order_pub.line_tbl_type;
       x_action_request_tbl           oe_order_pub.request_tbl_type;
       x_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
       x_request_rec                  oe_order_pub.request_rec_type ;

       -- OUT Variables --
       x_header_rec_out               oe_order_pub.header_rec_type;
       x_header_val_rec_out           oe_order_pub.header_val_rec_type;
       x_header_adj_tbl_out           oe_order_pub.header_adj_tbl_type;
       x_header_adj_val_tbl_out       oe_order_pub.header_adj_val_tbl_type;
       x_header_price_att_tbl_out     oe_order_pub.header_price_att_tbl_type;
       x_header_adj_att_tbl_out       oe_order_pub.header_adj_att_tbl_type;
       x_header_adj_assoc_tbl_out     oe_order_pub.header_adj_assoc_tbl_type;
       x_header_scredit_tbl_out       oe_order_pub.header_scredit_tbl_type;
       x_header_scredit_val_tbl_out   oe_order_pub.header_scredit_val_tbl_type;
       x_line_tbl_out                 oe_order_pub.line_tbl_type;
       x_line_val_tbl_out             oe_order_pub.line_val_tbl_type;
       x_line_adj_tbl_out             oe_order_pub.line_adj_tbl_type;
       x_line_adj_val_tbl_out         oe_order_pub.line_adj_val_tbl_type;
       x_line_price_att_tbl_out       oe_order_pub.line_price_att_tbl_type;
       x_line_adj_att_tbl_out         oe_order_pub.line_adj_att_tbl_type;
       x_line_adj_assoc_tbl_out       oe_order_pub.line_adj_assoc_tbl_type;
       x_line_scredit_tbl_out         oe_order_pub.line_scredit_tbl_type;
       x_line_scredit_val_tbl_out     oe_order_pub.line_scredit_val_tbl_type;
       x_lot_serial_tbl_out           oe_order_pub.lot_serial_tbl_type;
       x_lot_serial_val_tbl_out       oe_order_pub.lot_serial_val_tbl_type;
       x_action_request_tbl_out       oe_order_pub.request_tbl_type;

       x_comments        VARCHAR2(2000) := NULL;
       x_signature       VARCHAR2(240)  := NULL;
       x_document        VARCHAR2(240)  := NULL;
       x_date            DATE := NULL;

   BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'Inside line_modifer');

      IF NVL(p_flag,'X') = 'M' THEN
         OPEN c_pod_update;
         FETCH c_pod_update INTO x_comments,x_signature,x_document,x_date;
         IF c_pod_update%NOTFOUND THEN
            RAISE x_error;
         END IF;
         CLOSE c_pod_update;
      ELSE
         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMMANIFESTPODPROCESS'
                                                    ,p_param_name      => 'COMMENTS'
                                                    ,x_param_value     =>  x_comments);

         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMMANIFESTPODPROCESS'
                                                    ,p_param_name      => 'SIGNATURE'
                                                    ,x_param_value     =>  x_signature);

         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMMANIFESTPODPROCESS'
                                                    ,p_param_name      => 'DOCUMENT'
                                                    ,x_param_value     =>  x_document);

         x_date := SYSDATE;
      END IF;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'COMMENTS  ->'||x_comments);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'SIGNATURE ->'||x_signature);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'DOCUMENT  ->'||x_document);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'DATE      ->'||x_date);

      mo_global.init('ONT');
      fnd_global.apps_initialize( user_id      => x_user_id,
                                  resp_id      => x_resp_id,
                                  resp_appl_id => x_resp_appl_id);

      --Header Record
      x_header_rec.header_id     := p_header_id;

      -- Line Record --
      x_line_tbl (1)             := oe_order_pub.g_miss_line_rec;
      x_line_tbl (1).operation   := oe_globals.g_opr_update;
      x_line_tbl (1).header_id   := p_header_id;
      x_line_tbl (1).line_id     := p_line_id;

      x_request_rec.entity_code  := OE_GLOBALS.G_ENTITY_LINE;
      x_request_rec.request_type := OE_GLOBALS.G_ACCEPT_FULFILLMENT;
      x_request_rec.entity_id    := p_line_id;

      x_request_rec .param1      := x_comments;
      x_request_rec .param2      := x_signature;
      x_request_rec .param3      := x_document;
      x_request_rec. date_param2 := x_date;

      x_action_request_tbl (1)   := x_request_rec;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium, 'Starting of API  ');

      OE_ORDER_PUB.PROCESS_ORDER (
           p_api_version_number          => x_api_version_number
          ,p_header_rec                  => x_header_rec
          ,p_line_tbl                    => x_line_tbl
          ,p_action_request_tbl          => x_action_request_tbl
          ,p_line_adj_tbl                => x_line_adj_tbl
          -- OUT variables
          ,x_header_rec                  => x_header_rec_out
          ,x_header_val_rec              => x_header_val_rec_out
          ,x_header_adj_tbl              => x_header_adj_tbl_out
          ,x_header_adj_val_tbl          => x_header_adj_val_tbl_out
          ,x_header_price_att_tbl        => x_header_price_att_tbl_out
          ,x_header_adj_att_tbl          => x_header_adj_att_tbl_out
          ,x_header_adj_assoc_tbl        => x_header_adj_assoc_tbl_out
          ,x_header_scredit_tbl          => x_header_scredit_tbl_out
          ,x_header_scredit_val_tbl      => x_header_scredit_val_tbl_out
          ,x_line_tbl                    => x_line_tbl_out
          ,x_line_val_tbl                => x_line_val_tbl_out
          ,x_line_adj_tbl                => x_line_adj_tbl_out
          ,x_line_adj_val_tbl            => x_line_adj_val_tbl_out
          ,x_line_price_att_tbl          => x_line_price_att_tbl_out
          ,x_line_adj_att_tbl            => x_line_adj_att_tbl_out
          ,x_line_adj_assoc_tbl          => x_line_adj_assoc_tbl_out
          ,x_line_scredit_tbl            => x_line_scredit_tbl_out
          ,x_line_scredit_val_tbl        => x_line_scredit_val_tbl_out
          ,x_lot_serial_tbl              => x_lot_serial_tbl_out
          ,x_lot_serial_val_tbl          => x_lot_serial_val_tbl_out
          ,x_action_request_tbl          => x_action_request_tbl_out
          ,x_return_status               => x_return_status
          ,x_msg_count                   => x_msg_count
          ,x_msg_data                    => x_msg_data
         );

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium, 'Completion of API  ');

      IF x_return_status = fnd_api.g_ret_sts_success THEN
         COMMIT;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium, 'Line Updation to Existing Order Success ');
         DBMS_OUTPUT.put_line ('Line Updation to Existing Order Success ');
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium, 'Line Updation to Existing Order failed:');
         DBMS_OUTPUT.put_line ('Line Updation to Existing Order failed:');

         ROLLBACK;
         FOR i IN 1 .. x_msg_count
         LOOP
           x_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
           fnd_file.put_line (fnd_file.LOG, i|| ') '|| x_msg_data);
           x_error_msg := x_error_msg ||'-'||x_msg_data;
         END LOOP;
      END IF;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'Outside line_modifer');
   EXCEPTION
      WHEN x_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure line_modifer -> Unexpected Error'||SQLERRM;
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure line_modifer -> Unexpected Error'||SQLERRM;
   END line_modifer;

   ----------------------------------------------------------------------

   PROCEDURE table_dupli_update( p_tracking_no                 IN     VARCHAR2
                                ,x_return_status               OUT    VARCHAR2
                                ,x_error_msg                   OUT    VARCHAR2)


   IS
       PRAGMA AUTONOMOUS_TRANSACTION;
       x_del_error  EXCEPTION;
   BEGIN
       UPDATE  xx_om_manifest_pod_int
          SET  process_flag         = 'D'
              ,created_by           = x_user_id
              ,creation_date        = SYSDATE
              ,last_update_date     = SYSDATE
              ,last_updated_by      = x_user_id
              ,last_update_login    = x_login_id
        WHERE  tracking_no          = p_tracking_no
          AND  process_flag IS NULL
          AND  record_id <> (SELECT MAX(record_id)
                               FROM xx_om_manifest_pod_int
                              WHERE delivery_id  = p_tracking_no);
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure Table_update -> Unexpected Error'||SQLERRM;
   END table_dupli_update;

   ----------------------------------------------------------------------

   PROCEDURE line_auto( p_org_id          IN     NUMBER
                       ,p_header_id       IN     NUMBER
                       ,p_domestic        IN     NUMBER
                       ,p_inter           IN     NUMBER
                       ,x_return_status   OUT    VARCHAR2
                       ,x_error_msg       OUT    VARCHAR2)
   IS
     CURSOR c_auto_inter
     IS
     SELECT  oel.header_id
            ,oel.line_id
            ,oel.actual_shipment_date
            ,ROUND(SYSDATE - oel.actual_shipment_date,2) aging
            ,oel.line_number
            ,oel.shipment_number
            ,oeh.order_number
      FROM   oe_order_lines_all oel
            ,oe_order_headers_all oeh
     WHERE   oeh.header_id = oel.header_id
       AND   oel.flow_status_code = 'POST-BILLING_ACCEPTANCE'
       AND   oel.org_id = p_org_id
       AND   ROUND(SYSDATE - oel.actual_shipment_date,2) >= p_inter
       AND   oel.shipment_priority_code IN
             ( SELECT  lookup_code
                 FROM  fnd_lookup_values_vl
                WHERE  lookup_type = 'XXINTG_SHIP_PRIORITY_POD'
                  AND  NVL(enabled_flag,'X')='Y'
                  AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE));

     CURSOR c_auto_domestic
     IS
     SELECT  oel.header_id
            ,oel.line_id
            ,oel.actual_shipment_date
            ,ROUND(sysdate - oel.actual_shipment_date,2) aging
            ,oel.line_number
            ,oel.shipment_number
            ,oeh.order_number
      FROM   oe_order_lines_all oel
            ,oe_order_headers_all oeh
     WHERE   oeh.header_id = oel.header_id
       AND   oel.flow_status_code = 'POST-BILLING_ACCEPTANCE'
       AND   oel.org_id = p_org_id
       AND   ROUND(SYSDATE - oel.actual_shipment_date,2) >= p_domestic
       AND   oel.shipment_priority_code NOT IN
             ( SELECT  lookup_code
                 FROM  fnd_lookup_values_vl
                WHERE  lookup_type = 'XXINTG_SHIP_PRIORITY_POD'
                  AND  NVL(enabled_flag,'X')='Y'
                  AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE));

     CURSOR c_auto_select
     IS
     SELECT  oel.header_id
            ,oel.line_id
            ,oel.line_number
            ,oel.shipment_number
            ,oeh.order_number
      FROM   oe_order_lines_all oel
            ,oe_order_headers_all oeh
     WHERE   oeh.header_id = oel.header_id
       AND   oel.header_id = p_header_id
       AND   oel.flow_status_code = 'POST-BILLING_ACCEPTANCE';

   BEGIN
      IF p_header_id IS NULL THEN

         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'International Orders ');
         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'-------------------- ');
         FOR inter_rec IN c_auto_inter LOOP
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Order Number ->'||inter_rec.order_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Line Number  ->'||inter_rec.line_number||'.'||inter_rec.shipment_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
             line_modifer ( p_header_id       =>  inter_rec.header_id
                           ,p_line_id         =>  inter_rec.line_id
                           ,p_flag            =>  'A'
                           ,x_return_status   =>  x_return_status
                           ,x_error_msg       =>  x_error_msg);
         END LOOP;

         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Domestic Orders ');
         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'-------------------- ');
         FOR dom_rec IN c_auto_domestic LOOP
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Domestic Orders ');
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Order Number ->'||dom_rec.order_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Line Number  ->'||dom_rec.line_number||'.'||dom_rec.shipment_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
             line_modifer ( p_header_id       =>  dom_rec.header_id
                           ,p_line_id         =>  dom_rec.line_id
                           ,p_flag            =>  'A'
                           ,x_return_status   =>  x_return_status
                           ,x_error_msg       =>  x_error_msg);
         END LOOP;
      ELSE
         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Manual Orders ');
         FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'-------------------- ');
         FOR sel_rec IN c_auto_select LOOP
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Order Number ->'||sel_rec.order_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Line Number  ->'||sel_rec.line_number||'.'||sel_rec.shipment_number);
             FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
             line_modifer ( p_header_id       =>  sel_rec.header_id
                           ,p_line_id         =>  sel_rec.line_id
                           ,p_flag            =>  'A'
                           ,x_return_status   =>  x_return_status
                           ,x_error_msg       =>  x_error_msg);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure line_auto -> Unexpected Error'||SQLERRM;
   END line_auto;
   --------------------------------------------------------------------- --

   PROCEDURE manifest_podin_update( p_org_id                      IN     NUMBER
                                   --,p_header_id                   IN     NUMBER
                                   ,p_tracking_no                 IN     VARCHAR2
                                   ,p_accepted_quantity           IN     NUMBER
                                   ,p_revrec_comments             IN     VARCHAR2
                                   ,p_revrec_reference_document   IN     VARCHAR2
                                   ,p_revrec_signature            IN     VARCHAR2
                                   ,p_revrec_signature_date       IN     DATE
                                   ,p_pod_received_date           IN     DATE
                                   ,x_return_status               OUT    VARCHAR2
                                   ,x_error_msg                   OUT    VARCHAR2)
   IS
       x_ret_status            VARCHAR2(1);
       x_error_message         VARCHAR(3000);
       x_order_no              NUMBER;
       x_line_no               NUMBER;
       x_ship_no               NUMBER;

       CURSOR c_pod_update
       IS
       SELECT  wdd.source_header_id
              ,wdd.source_line_id
              ,oeh.org_id
         FROM  wsh_new_deliveries wnd
              ,wsh_delivery_assignments wds
              ,wsh_delivery_details wdd
              ,oe_order_headers_all oeh
        WHERE  wnd.delivery_id        = wds.delivery_id
          AND  wds.delivery_detail_id = wdd.delivery_detail_id
          AND  oeh.header_id = wdd.source_header_id
          AND  oeh.org_id    = NVL(p_org_id,oeh.org_id)
          AND  NVL(wnd.waybill,'X') = NVL(p_tracking_no,NVL(wnd.waybill,'X'));
          --AND  oeh.header_id = NVL(p_header_id,oeh.header_id)
   BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'Inside manifest_podin_update');
       FOR pod_rec IN c_pod_update LOOP
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'header_id ->'||pod_rec.source_header_id);
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'header_id ->'||pod_rec.source_line_id);

           BEGIN
                SELECT  ool.line_number
                       ,ool.shipment_number
                       ,ooh.order_number
                  INTO  x_line_no
                       ,x_ship_no
                       ,x_order_no
                  FROM  oe_order_headers_all ooh
                       ,oe_order_lines_all ool
                 WHERE  ooh.header_id = ool.header_id
                   AND  ooh.header_id = pod_rec.source_header_id
                   AND  ool.line_id   = pod_rec.source_line_id;
           EXCEPTION WHEN OTHERS THEN
              x_order_no  := NULL;
              x_line_no   := NULL;
              x_ship_no   := NULL;
           END;

           UPDATE  xx_om_manifest_pod_int
              SET  header_id            = pod_rec.source_header_id
                  ,line_id              = pod_rec.source_line_id
                  ,org_id               = pod_rec.org_id
              WHERE  NVL(tracking_no,'X') = NVL(p_tracking_no,NVL(tracking_no,'X'))
                AND  process_flag IS NULL;
           COMMIT;

           line_modifer ( p_header_id       =>  pod_rec.source_header_id
                         ,p_line_id         =>  pod_rec.source_line_id
                         ,p_flag            =>  'M'
                         ,x_return_status   =>  x_ret_status
                         ,x_error_msg       =>  x_error_msg);

           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'Status    ->'||x_ret_status);

           IF NVL(x_ret_status,'X') = 'E' THEN
              x_error_message := x_error_message ||x_error_msg;
              x_return_status := 'E';
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Error On');
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Order Number ->'||x_order_no);
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Line Number  ->'||x_line_no||'.'||x_ship_no);
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
              UPDATE  xx_om_manifest_pod_int
                 SET  process_flag = 'E'
                     ,error_message = x_error_message
                     ,created_by           = x_user_id
                     ,creation_date        = SYSDATE
                     ,last_update_date     = SYSDATE
                     ,last_updated_by      = x_user_id
                     ,last_update_login    = x_login_id
              WHERE  NVL(tracking_no,'X') = NVL(p_tracking_no,NVL(tracking_no,'X'))
                AND  process_flag IS NULL;
           ELSE
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Processed For');
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Order Number ->'||x_order_no);
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'Line Number  ->'||x_line_no||'.'||x_ship_no);
              FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
              UPDATE  xx_om_manifest_pod_int
                 SET  process_flag = 'Y'
                     ,created_by           = x_user_id
                     ,creation_date        = SYSDATE
                     ,last_update_date     = SYSDATE
                     ,last_updated_by      = x_user_id
                     ,last_update_login    = x_login_id
              WHERE  NVL(tracking_no,'X') = NVL(p_tracking_no,NVL(tracking_no,'X'))
                AND  process_flag IS NULL;
           END IF;
       END LOOP;
       COMMIT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'Out manifest_podin_update');
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure manifest_podin_update -> Unexpected Error'||SQLERRM;
   END manifest_podin_update;
----------------------------------------------------------------------

   PROCEDURE manifest_podinreprocess( p_errbuf            OUT   VARCHAR2
                                     ,p_retcode           OUT   VARCHAR2
                                     ,p_org_id            IN    NUMBER
                                     ,p_header_id         IN    NUMBER
                                     ,p_domestic          IN    NUMBER
                                     ,p_inter             IN    NUMBER
                                     )
   IS
     CURSOR c_dupli
     IS
     SELECT  DISTINCT tracking_no
      FROM   xx_om_manifest_pod_int
     WHERE   process_flag IS NULL
     ORDER BY tracking_no;

     CURSOR c_rec
     IS
     SELECT  xosm.*
       FROM  xx_om_manifest_pod_int xosm
      WHERE  xosm.process_flag IS NULL;

       x_ret_status               VARCHAR2(1);
       x_error_message            VARCHAR(3000);
       x_error_code               VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
       x_error_msg_temp           VARCHAR2(3000);
       x_error_code_temp          NUMBER        := xx_emf_cn_pkg.cn_success;

       x_delivery_id  NUMBER;
       x_header_id    NUMBER;
       x_line_id      NUMBER;
       x_org_id       NUMBER;
       x_trac_number  VARCHAR2(30);
   BEGIN
      p_retcode := xx_emf_cn_pkg.cn_success;

      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'------------------------------------------');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'p_org_id        -> '||p_org_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'p_header_id     -> '||p_header_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'p_domestic      -> '||p_domestic);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'p_inter         -> '||p_inter);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'------------------------------------------');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'----------------------------------------');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'               POD Orders');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'----------------------------------------');

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMMANIFESTPODPROCESS'
                                                 ,p_param_name      => 'DATA_DIR'
                                                 ,x_param_value     =>  g_data_dir);

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMMANIFESTPODPROCESS'
                                                 ,p_param_name      => 'ARCH_DIR'
                                                 ,x_param_value     =>  g_arch_dir);

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling utl_read_insert_stg..');

      -- File read
      utl_read_insert_stg( x_error_code_temp ,x_error_msg_temp);

      -- Archiving the files
      x_error_code_temp :=move_file_archive;


      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,'DATA_DIR         ->'||g_data_dir);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,'ARCH_DIR         ->'||g_arch_dir);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,'------------------------------------------');

      FOR dupli_rec IN c_dupli LOOP
         table_dupli_update( p_tracking_no    =>  dupli_rec.tracking_no
                            ,x_return_status  =>  x_ret_status
                            ,x_error_msg      =>  x_error_message);
      END LOOP;

      FOR r_rec IN c_rec LOOP
           manifest_podin_update( p_org_id                    =>  p_org_id
                                 --,p_header_id                 =>  p_header_id
                                 ,p_tracking_no               =>  r_rec.tracking_no
                                 ,p_accepted_quantity         =>  r_rec.accepted_quantity
                                 ,p_revrec_comments           =>  r_rec.revrec_comments
                                 ,p_revrec_reference_document =>  r_rec.revrec_reference_document
                                 ,p_revrec_signature          =>  r_rec.revrec_signature
                                 ,p_revrec_signature_date     =>  r_rec.revrec_signature_date
                                 ,p_pod_received_date         =>  r_rec.pod_received_date
                                 ,x_return_status             =>  x_ret_status
                                 ,x_error_msg                 =>  x_error_message);

      END LOOP;

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'----------------------------------------');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'       Auto Acceptance POD Orders');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'----------------------------------------');

      line_auto( p_org_id          => p_org_id
                ,p_header_id       => p_header_id
                ,p_domestic        => p_domestic
                ,p_inter           => p_inter
                ,x_return_status   => x_ret_status
                ,x_error_msg       => x_error_message);

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'          End of the Report');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'----------------------------------------');

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG,'manifest_podinreprocess -> Erro in Processing '||SQLERRM);
         p_retcode := 2;
   END manifest_podinreprocess;
-- --------------------------------------------------------------------- --

END xx_om_manifest_podin_pkg;
/
