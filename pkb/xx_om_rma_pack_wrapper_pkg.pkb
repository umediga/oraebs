DROP PACKAGE BODY APPS.XX_OM_RMA_PACK_WRAPPER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_RMA_PACK_WRAPPER_PKG" 
AS
   ----------------------------------------------------------------------
   /*
    Created By    : Kunal Seal
    Creation Date : 05-Sep-2012
    File Name     : XXOMOEXOEACKWRAP.pkb
    Description   : This script submits the RMA Pack Slip Report
                    and submits Send Mail program
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    05-Sep-2012  Kunal Seal          Initial Development

   */
   -----------------------------------------------------------------------
   PROCEDURE main_proc (o_errbuf              OUT VARCHAR2,
                        o_retcode             OUT VARCHAR2,
                        --p_sob_id           IN     NUMBER,
                        --p_item_flex_code   IN     VARCHAR2,
                        p_print_description  IN     VARCHAR2,
                        --p_booked_status    IN     VARCHAR2,
                        p_order_type       IN     NUMBER, -- mandatory display
                        p_order_number     IN     NUMBER,
                        --p_order_category   IN     VARCHAR2,
                        --p_line_category     IN    VARCHAR2,
                        --p_open_orders       IN    VARCHAR2,
                        --p_show_hdr_atch     IN    VARCHAR2,
                        --p_show_bdy_atch     IN    VARCHAR2,
                        --p_show_ftr_atch     IN    VARCHAR2,
                        p_email            IN     VARCHAR2)
   IS
      CURSOR c_data_dir (p_dir VARCHAR2)
      IS
         SELECT directory_path
           FROM all_directories
          WHERE directory_name = p_dir;
      x_rep_req_id       NUMBER;
      x_file_mv_req_id   NUMBER;
      x_email            VARCHAR2 (140);
      x_l_phase          VARCHAR2 (240);
      x_l_status         VARCHAR2 (240);
      x_l_dev_phase      VARCHAR2 (240);
      x_l_dev_status     VARCHAR2 (240);
      x_l_message        VARCHAR2 (240);
      x_out_file         VARCHAR2(240);
      x_pdf_file_name    VARCHAR2(240);
      x_from_dir         VARCHAR2(240);
      x_to_dir         VARCHAR2(240);
      x_from_path      VARCHAR2(240);
      x_to_path         VARCHAR2(240);
      x_l_phase1        VARCHAR2(240);
      x_l_status1      VARCHAR2(240);
      x_l_dev_phase1   VARCHAR2(240);
      x_l_dev_status1  VARCHAR2(240);
      x_l_message1     VARCHAR2(240);
      x_mail_msg       VARCHAR2(2000);
      x_mail_subj      VARCHAR2(500);
      x_mail_from      VARCHAR2(240);
      x_wfr            BOOLEAN;
      x_add_layout     BOOLEAN;
   BEGIN

      fnd_file.put_line(fnd_file.log,'org id : '||MO_GLOBAL.GET_CURRENT_ORG_ID());
      fnd_file.put_line(fnd_file.log,'SOB : '||oe_sys_parameters.value ('SET_OF_BOOKS_ID'));
      fnd_file.put_line(fnd_file.log,'ITEM FLEX : '||fnd_profile.value('OE_ID_FLEX_CODE'));

       BEGIN                                      -- find out the Email Address
         IF (p_email IS NOT NULL)
         THEN
            x_email := p_email;
         ELSE
            BEGIN
               SELECT   attribute10
                 INTO   x_email
                 FROM   oe_order_headers_all
                WHERE   order_number = p_order_number
                   AND org_id = MO_GLOBAL.GET_CURRENT_ORG_ID()
                   AND order_type_id = nvl(p_order_type,order_type_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_email := NULL;
               WHEN OTHERS
               THEN
                  x_email := NULL;
                  fnd_file.put_line (
                     fnd_file.LOG,
                     'Error finding Attribute10 -- ' || SQLERRM
                  );
            END;
         END IF;

         -- If no email exists then Complete in Error
          IF (x_email IS NULL)
          THEN
             fnd_file.put_line (
                fnd_file.LOG,
                'No Email ID found. Please prvide Email Address while submitting this program or in Order Header DFF.'
             );
             raise_application_error (
                -20001,
                'No Email ID found. Please prvide the Email Address.'
             );
          END IF;
      END;

       fnd_request.set_org_id(MO_GLOBAL.GET_CURRENT_ORG_ID());

       x_add_layout :=
                  fnd_request.add_layout (
                     template_appl_name   => 'XXINTG',
                     template_code        => 'XXINTGOMOEXOEACK',
                     template_language    => 'EN',
                     template_territory   => 'US',
                     output_format        => 'PDF'
                  );

      x_rep_req_id :=
         FND_REQUEST.SUBMIT_REQUEST ('XXINTG',
                                     'XXINTGOMOEXOEACK',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     oe_sys_parameters.value ('SET_OF_BOOKS_ID'),               -- Set of book ID
                                     fnd_profile.value('OE_ID_FLEX_CODE'),       -- Item Flex Code
                                     p_print_description,        -- Print Description
                                     'Y',            -- Booked Status
                                     p_order_type,               -- Order Type
                                     p_order_number,      -- Order Number From
                                     p_order_number,        -- Order Number To
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     'SALES',                -- Order Category
                                     'ALL',                   -- Line Category
                                     NULL,
                                     NULL,
                                     'Y',                       -- Open Orders
                                     NULL,
                                     NULL,
                                     'N',                -- Show Header Attach
                                     'N',                  -- Show Body Attach
                                     'Y',                -- Show Footer Attach
                                     p_email                  -- Email Address
                                            );
      COMMIT;



      x_wfr := fnd_concurrent.wait_for_request (x_rep_req_id,
                                       10,                         -- interval
                                       NULL,                       -- max_wait
                                       x_l_phase,
                                       x_l_status,
                                       x_l_dev_phase,
                                       x_l_dev_status,
                                       x_l_message);


      IF (x_l_dev_phase = 'COMPLETE' AND x_l_dev_status = 'NORMAL')
      THEN

         -- Run the File Movement Program
         BEGIN

            BEGIN
            SELECT SUBSTR (file_name, INSTR (file_name, '/', -1, 1) + 1)
              INTO x_out_file
              FROM fnd_conc_req_outputs
             WHERE concurrent_request_id = x_rep_req_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                   (fnd_file.LOG,
                       'Error in extracting output file name for request ID '
                    || x_rep_req_id ||'--'||SQLERRM
                   );
               raise_application_error (
            -20002,
            'Error in extracting output file name for request ID '||
      x_rep_req_id
         );
         END;

         xx_intg_common_pkg.get_process_param_value
                            (p_process_name      => 'XXONTSOCNFMMAIN',
                             p_param_name        => 'OUTFILE_DIRECTORY',
                             x_param_value       => x_from_dir
                                         );
         xx_intg_common_pkg.get_process_param_value
                            (p_process_name      => 'XXONTSOCNFMMAIN',
                             p_param_name        => 'MAIL_DIRECTORY',
                             x_param_value       => x_to_dir
                                         );

         OPEN c_data_dir (x_from_dir);

         FETCH c_data_dir
          INTO x_from_path;

         IF c_data_dir%NOTFOUND
         THEN
            x_from_path := NULL;
         END IF;

         CLOSE c_data_dir;

         OPEN c_data_dir (x_to_dir);

         FETCH c_data_dir
          INTO x_to_path;

         IF c_data_dir%NOTFOUND
         THEN
            x_to_path := NULL;
         END IF;

         CLOSE c_data_dir;

         END;



         BEGIN
         -- Finally submit the program for movement
            x_pdf_file_name := 'RMA_Pack_List_'||p_order_number||'.pdf';
            fnd_file.put_line(fnd_file.LOG,'Out file name : '||x_out_file);
             x_file_mv_req_id :=
                fnd_request.submit_request (application      => 'XXINTG',
                                           program          => 'XXINTGFILEMOV',
                                           sub_request      => FALSE,
                                           argument1        => x_out_file,
                                           argument2        =>    x_from_path
                                                               || '/',
                                           argument3        => x_to_path
                                                               || '/' ||
      x_pdf_file_name,
                                           argument4        => 'No'
                                          );
              COMMIT;
              x_wfr := fnd_concurrent.wait_for_request (x_file_mv_req_id,
                                                   10,
                                                   NULL,
                                                   x_l_phase1,
                                                   x_l_status1,
                                                   x_l_dev_phase1,
                                                   x_l_dev_status1,
                                                   x_l_message1
                                                  );
               IF (x_l_dev_phase1 = 'COMPLETE' OR x_l_dev_status1 = 'NORMAL')
               THEN

                    fnd_message.set_name('XXINTG','INTG_RMA_WRAP_BODY');
                    x_mail_msg := fnd_message.get;

                    fnd_message.set_name('XXINTG','INTG_RMA_WRAP_SUBJ');
                    fnd_message.set_token('ORDER_NO',p_order_number);
                    x_mail_subj := fnd_message.get;

                    fnd_message.set_name('XXINTG','INTG_RMA_WRAP_MAIL_FROM');
                    x_mail_from := fnd_message.get;

                    fnd_file.put_line(fnd_file.LOG,'Body : '||x_mail_msg);
                    fnd_file.put_line(fnd_file.LOG,'Subject : '||x_mail_subj);
                    fnd_file.put_line(fnd_file.LOG,'Mail From : '||x_mail_from);
                    fnd_file.put_line(fnd_file.LOG,'Calling mail sending package');
                    --- Proceed for sending Mail
                   BEGIN
                   xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_mail_from
                                                ,p_to_name          => x_email
                                                ,p_subject          => x_mail_subj
                                                ,p_message          => x_mail_msg
                                                ,p_oracle_directory => x_to_dir
                                                ,p_binary_file      => x_pdf_file_name
                                               );
                  EXCEPTION
                  WHEN OTHERS THEN
                    fnd_file.put_line (
                        fnd_file.LOG, 'Error in Mail Sending Package -- '||SQLERRM);
                  END;
               ELSE
                  fnd_file.put_line (
                        fnd_file.LOG,
                       'File Movement Prog Req ID : '
                    || x_rep_req_id
                    || CHR (10)
                    || 'Phase : '
                    || x_l_dev_phase1
                    || CHR (10)
                    || 'Status : '
                    || x_l_dev_status1
                    || CHR (10)
                 );
                 raise_application_error (
                    -20003,
                    'File Movement Program not completed Successfully.'
                    );
               END IF;
         END;

      ELSE
         fnd_file.put_line (
            fnd_file.LOG,
               'INTG RMA Pack Slip Report request id : '
            || x_rep_req_id
            || CHR (10)
            || 'Phase : '
            || x_l_dev_phase
            || CHR (10)
            || 'Status : '
            || x_l_dev_status
            || CHR (10)
         );
         raise_application_error (
            -20004,
            'INTG RMA pack Slip Program not completed Successfully.'
         );
      END IF;
   END main_proc;
END xx_om_rma_pack_wrapper_pkg;
/
