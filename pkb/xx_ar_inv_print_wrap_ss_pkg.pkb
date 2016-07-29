DROP PACKAGE BODY APPS.XX_AR_INV_PRINT_WRAP_SS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_inv_print_wrap_ss_pkg
AS
  ----------------------------------------------------------------------
/*
Created By    : Deepta
Creation Date : 18-OCT-2014
File Name     : XX_AR_INV_PRINT_WRAP_SS_PKG.pkb
Description   : This script creates the body of the package
xx_ar_inv_print_wrap_pkg
Change History:
Date        Name                  Remarks
----------- -------------         -----------------------------------
18-OCT-2014 Deepta               Initial Development
*/
  ----------------------------------------------------------------------
  PROCEDURE Submit_new_invoice (errbuf                    OUT VARCHAR2,
                                retcode                   OUT NUMBER,
                                p_order_by                IN VARCHAR2,
                                p_cust_trx_class          IN VARCHAR2,
                                p_cust_trx_type_id        IN NUMBER,
                                p_dates_low               IN VARCHAR2,
                                p_dates_high              IN VARCHAR2,
                                p_installment_number      IN NUMBER,
                                p_open_invoice            IN VARCHAR2,
                                p_check_for_taxyn         IN VARCHAR2,
                                p_tax_registration_number IN VARCHAR2,
                                p_choice                  IN VARCHAR2,
                                p_header_pages            IN NUMBER,
                                p_debug_flag              IN VARCHAR2,
                                p_message_level           IN NUMBER,
                                p_ship_from_warehouse     IN VARCHAR2,
                                p_region                  IN VARCHAR2,
                                p_print_on_pitney_bowes   IN VARCHAR2,
                                p_context_value           IN VARCHAR2,
                                p_profile_option          IN VARCHAR2,
                                p_conc_pgm_short_name     IN VARCHAR2)
  IS
    x_application    VARCHAR2 (10) := 'XXINTG';
    x_layout_status  BOOLEAN := FALSE;
    x_user_id        NUMBER := fnd_global.user_id;
    x_resp_id        NUMBER := fnd_global.resp_id;
    x_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
    x_reqid1         NUMBER;
    x_reqid          NUMBER;
    x_org_id         NUMBER; --:= MO_GLOBAL.get_current_org_id
    x_template       VARCHAR2 (100);
    x_org_name       VARCHAR2 (100);
    x_email_pgm_name VARCHAR2 (100);
        x_ftp_pgm_name VARCHAR2 (100);

    x_ftp_flag       VARCHAR2 (10);
    x_printer_name   VARCHAR2 (100);
    x_printer_style  VARCHAR2 (100);
    x_print_copies   NUMBER;
    x_print_status   BOOLEAN := FALSE;
    x_print_status1  BOOLEAN := FALSE;
  BEGIN
      BEGIN
          SELECT org_id,
                 printer,
                 print_style,
                 number_of_copies
          INTO   x_org_id, x_printer_name, x_printer_style, x_print_copies
          FROM   fnd_concurrent_requests
          WHERE  request_id = fnd_global.conc_request_id;

          SELECT name
          INTO   x_org_name
          FROM   hr_operating_units
          WHERE  organization_id = x_org_id;
      EXCEPTION
          WHEN OTHERS THEN
            fnd_file.Put_line (fnd_file.log, 'ORG ID IS:'
                                             || x_org_id);
      END;

    /*
    BEGIN
          SELECT description
          INTO   x_template
          FROM   fnd_lookup_values
          WHERE  lookup_type = 'XX_INTG_RPT_OU_TEMPLATE_SS'
                 AND meaning = x_org_name
                               ||'|'
                               ||p_conc_pgm_short_name
                 -- AND tag           = p_cnc_pgm_short_name
                 AND LANGUAGE = 'US';
      EXCEPTION
          WHEN no_data_found THEN
            SELECT description
            INTO   x_template
            FROM   fnd_lookup_values
            WHERE  lookup_type = 'XX_INTG_RPT_OU_TEMPLATE_SS'
                   AND meaning = 'DEFAULT'
                                 ||'|'
                                 ||p_conc_pgm_short_name
                   -- AND tag           = p_conc_pgm_short_name
                   AND LANGUAGE = 'US';
          --  RETURN v_temp;
          WHEN OTHERS THEN
            x_template := NULL;
      END;
*/
      -- Submit FTP Program
      fnd_request.Set_org_id (x_org_id);

      fnd_global.Apps_initialize (x_user_id, --User id
      x_resp_id, --responsibility_id
      x_resp_appl_id); --application_id

                                       x_template:= get_template(x_org_name,p_conc_pgm_short_name);

      fnd_file.Put_line (fnd_file.log, 'X_TEMPLATE: '
                                       ||x_template);



      -- Submit the FTP Program
      x_ftp_pgm_name:='XXR2RPRINTNEWINV_SS';
      x_layout_status := fnd_request.Add_layout (
                         template_appl_name => x_application,
                                            template_code => x_template,
                         template_language => 'en',
                                            template_territory => 'US',
                         output_format => 'PDF');

/* IF x_org_name  = 'OU Canada' --- Added By Dhiren 15 Dec 2014 To Fix
Printer Requirment For CAN OU
THEN
-- Set printer options
x_print_status := fnd_submit.set_print_options (printer => x_printer_name
,
style => x_printer_style ,copies => x_print_copies );
--Add printer
x_print_status1 := fnd_request.add_printer (printer => x_printer_name ,
copies => x_print_copies);
ELSE --- Added By Dhiren 15-Dec-2014 -- To Fix No Of Copies Issues */
      -- Set printer options
      x_print_status := fnd_submit.Set_print_options (printer => 'noprint',
                        style
                        =>
                        'PDF Publisher',
                                          copies => 0);

      --Add printer
      x_print_status1 := fnd_request.Add_printer (printer => 'noprint',
                         copies => 0);

      --  END IF;
      IF x_layout_status THEN
        -- DBMS_OUT
        x_reqid := fnd_request.Submit_request (application => x_application,
                              program => x_ftp_pgm_name,
                   description => NULL,
                              start_time => SYSDATE, sub_request => FALSE,
                   argument1 => p_order_by,
                              argument2 => p_cust_trx_class,
                   argument3 => p_cust_trx_type_id,
                              argument4 => p_dates_low,
                   argument5 => p_dates_high,
                              argument6 => p_installment_number,
                   argument7 => p_open_invoice,
                              argument8 => p_check_for_taxyn,
                              argument9 => p_tax_registration_number,
                   argument10 => p_choice,
                              argument11 => p_header_pages,
                   argument12 => p_debug_flag
                   ,
                              argument13 => p_message_level,
                   argument14 => p_ship_from_warehouse,
                              argument15 => p_region,
                   argument16 => 'N', -- The FTP output should not be burst, so value passed is always N
                              argument17 => p_context_value,
                   argument18 => p_profile_option,
                              argument19 => 'FTP');

        fnd_file.Put_line (fnd_file.log, 'Child Program '
                                         ||x_ftp_pgm_name
                                         || ' submitted. Request ID is '
                                         ||x_reqid);
      END IF;



      -- Submit email program

      -- Submit the Email Program
         x_email_pgm_name:='XXR2RPRINTNEWINV_EMAIL_SS';
         x_template:= NULL;
          fnd_request.Set_org_id (x_org_id);

      fnd_global.Apps_initialize (x_user_id, --User id
      x_resp_id, --responsibility_id
      x_resp_appl_id); --application_id



                                       x_template:= get_template(x_org_name,x_email_pgm_name);

                                             fnd_file.Put_line (fnd_file.log, 'X_TEMPLATE: '
                                       ||x_template);

                                             x_layout_status := fnd_request.Add_layout (
				                                template_appl_name => x_application,
				                                                   template_code => x_template,
				                                template_language => 'en',
				                                                   template_territory => 'US',
                         output_format => 'PDF');

       -- Set printer options
            x_print_status := fnd_submit.Set_print_options (printer => 'noprint',
                              style
                              =>
                              'PDF Publisher',
                                                copies => 0);

            --Add printer
            x_print_status1 := fnd_request.Add_printer (printer => 'noprint',
                               copies => 0);

            --  END IF;
            IF x_layout_status THEN
              -- DBMS_OUT
              x_reqid := fnd_request.Submit_request (application => x_application,
                                    program => x_email_pgm_name,
                         description => NULL,
                                    start_time => SYSDATE, sub_request => FALSE,
                         argument1 => p_order_by,
                                    argument2 => p_cust_trx_class,
                         argument3 => p_cust_trx_type_id,
                                    argument4 => p_dates_low,
                         argument5 => p_dates_high,
                                    argument6 => p_installment_number,
                         argument7 => p_open_invoice,
                                    argument8 => p_check_for_taxyn,
                                    argument9 => p_tax_registration_number,
                         argument10 => p_choice,
                                    argument11 => p_header_pages,
                         argument12 => p_debug_flag
                         ,
                                    argument13 => p_message_level,
                         argument14 => p_ship_from_warehouse,
                                    argument15 => p_region,
                         argument16 => p_print_on_pitney_bowes, -- The email output should  be burst
                                    argument17 => p_context_value,
                         argument18 => p_profile_option,
                                    argument19 => 'EMAIL');

              fnd_file.Put_line (fnd_file.log, 'Child Program '
                                               ||x_email_pgm_name
                                               || ' submitted. Request ID is '
                                               ||x_reqid);
            END IF;





      COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
               fnd_file.Put_line (fnd_file.log, SQLERRM);
  END;
  PROCEDURE Submit_select_invoice (errbuf                    OUT VARCHAR2,
                                   retcode                   OUT NUMBER,
                                   p_order_by                IN VARCHAR2,
                                   p_cust_trx_class          IN VARCHAR2,
                                   p_cust_trx_type_id        IN VARCHAR2,--
                                   p_trx_number_low          IN VARCHAR2,
                                   p_trx_number_high         IN VARCHAR2,
                                   p_dates_low               IN VARCHAR2,
                                   p_dates_high              IN VARCHAR2,
                                   p_customer_class_code     IN VARCHAR2,--
                                   p_customer_id             IN NUMBER,
                                   p_installment_number      IN NUMBER,
                                   p_open_invoice            IN VARCHAR2,
                                   p_check_for_taxyn         IN VARCHAR2,
                                   p_tax_registration_number IN VARCHAR2,
                                   p_choice                  IN VARCHAR2,
                                   p_header_pages            IN NUMBER,
                                   p_debug_flag              IN VARCHAR2,
                                   p_message_level           IN NUMBER,
                                   p_random_invoices_flag    IN VARCHAR2,
                                   p_invoice_list_string     IN VARCHAR2,
                                   p_ship_from_warehouse     IN NUMBER,--
                                   p_region                  IN VARCHAR2,
                                   p_print_on_pitney_bowes   IN VARCHAR2,
                                   p_context_value           IN VARCHAR2,
                                   p_profile_option          IN VARCHAR2,
                                   p_conc_pgm_short_name     IN VARCHAR2)
  IS
    x_application   VARCHAR2 (10) := 'XXINTG';
    x_layout_status BOOLEAN := FALSE;
    x_user_id       NUMBER := fnd_global.user_id;
    x_resp_id       NUMBER := fnd_global.resp_id;
    x_resp_appl_id  NUMBER := fnd_global.resp_appl_id;
    x_reqid1        NUMBER;
    x_reqid         NUMBER;
    x_org_id        NUMBER; --:= MO_GLOBAL.get_current_org_id
    x_template      VARCHAR2 (100);
    x_org_name      VARCHAR2 (100);
    x_date_low      DATE;
    x_date_high     DATE;
    x_ftp_flag      VARCHAR2 (10);
    x_printer_name  VARCHAR2 (100);
    x_printer_style VARCHAR2 (100);
    x_print_copies  NUMBER;
    x_print_status  BOOLEAN := FALSE;
    x_print_status1 BOOLEAN := FALSE;
  BEGIN
      BEGIN
          SELECT org_id,
                 printer,
                 print_style,
                 number_of_copies
          INTO   x_org_id, x_printer_name, x_printer_style, x_print_copies
          FROM   fnd_concurrent_requests
          WHERE  request_id = fnd_global.conc_request_id;

          SELECT name
          INTO   x_org_name
          FROM   hr_operating_units
          WHERE  organization_id = x_org_id;

          fnd_file.Put_line (fnd_file.log, 'p_dates_low: '
                                           ||p_dates_low);

          fnd_file.Put_line (fnd_file.log, 'p_dates_high: '
                                           ||p_dates_high);

          x_date_low := fnd_date.Canonical_to_date (p_dates_low);

          x_date_high := fnd_date.Canonical_to_date (p_dates_high);

          fnd_file.Put_line (fnd_file.log, 'x_date_low: '
                                           ||x_date_low);

          fnd_file.Put_line (fnd_file.log, 'x_date_high: '
                                           ||x_date_high);

          -- x_date_low:=to_char(to_date(x_date_low,'DD-MON-YY'),'yyyy/mm/dd')||
          -- '
          -- 00:
          -- 00:00';
          -- x_date_high:=to_char(to_date(x_date_high,'DD-MON-YY'),'yyyy/mm/dd')
          -- ||'
          -- 00:00:00';
          fnd_file.Put_line (fnd_file.log, 'x_date_low: '
                                           ||x_date_low);

          fnd_file.Put_line (fnd_file.log, 'x_date_high: '
                                           ||x_date_high);
      END;



      fnd_request.Set_org_id (x_org_id);

      fnd_global.Apps_initialize (x_user_id, --User id
      x_resp_id, --responsibility_id
      x_resp_appl_id); --application_id

      x_template:=get_template(x_org_name,p_conc_pgm_short_name);

      fnd_file.Put_line (fnd_file.log, 'X_TEMPLATE: '
                                       ||x_template);

      -- Submit the FTP Program
      x_layout_status := fnd_request.Add_layout (
                         template_appl_name => x_application,
                                            template_code => x_template,
                         template_language => 'en',
                                            template_territory => 'US',
                         output_format => 'PDF');

/* IF x_org_name  = 'OU Canada' --- Added By Dhiren 15 Dec 2014 To Fix
Printer Requirment For CAN OU
THEN
-- Set printer options
x_print_status := fnd_submit.set_print_options (printer => x_printer_name
,
style => x_printer_style ,copies => x_print_copies );
--Add printer
x_print_status1 := fnd_request.add_printer (printer => x_printer_name ,
copies => x_print_copies);
ELSE --- Added By Dhiren 15-Dec-2014 -- To Fix No Of Copies Issues */
      -- Set printer options
      x_print_status := fnd_submit.Set_print_options (printer => 'noprint',
                        style
                        =>
                        'PDF Publisher',
                                          copies => 0);

      --Add printer
      x_print_status1 := fnd_request.Add_printer (printer => 'noprint',
                         copies => 0);

      IF x_layout_status THEN
        x_reqid := fnd_request.Submit_request (application => x_application,
                   program => p_conc_pgm_short_name
                   ,
                                                      description => NULL,
                                           start_time => SYSDATE,
                                                      sub_request => FALSE,
                                           argument1 => p_order_by
                   , argument2 => p_cust_trx_class,
                   argument3 => p_cust_trx_type_id,
                     argument4 => p_trx_number_low,
                     argument5 => p_trx_number_high,
                     argument6 => p_dates_low
                   --'2014/01/01 00:00:00'--x_date_low --'2014/01/01 00:00:00
                   -- '--
                   -- x_date_low--
                   , argument7 => p_dates_high
                   --'2014/01/01 00:00:00'--x_date_high -- '
                   -- 2014
                   -- /
                   -- 12/01 00:00:00'--sysdate--x_date_high--p_customer_id
                   , argument8 => p_customer_class_code,
                   argument9 => p_customer_id,
                   argument10 => p_installment_number
                                           ,
                   argument11 => p_open_invoice
                   ,
                   argument12 => p_check_for_taxyn,
                   argument13 =>
                   p_tax_registration_number,
                   argument14 => p_choice,
                   argument15 => p_header_pages,
                   argument16 => p_debug_flag,
                   argument17 => p_message_level,
                   argument18 =>
                   p_random_invoices_flag,
                   argument19 =>
                   p_invoice_list_string,
                   argument20 =>
                   p_ship_from_warehouse,
                   argument21 => p_region,
                   argument22 => x_ftp_flag
                   --p_print_on_pitney_bowes
                   , argument23 => p_context_value,
                   argument24 => p_profile_option
                   );

        fnd_file.Put_line (fnd_file.log, 'Child Program '
                                         || p_conc_pgm_short_name
                                         || ' submitted. Request ID is '
                                         ||x_reqid);

        COMMIT;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
               fnd_file.Put_line (fnd_file.log, SQLERRM);
  END;

  FUNCTION get_template (
         p_org_name      IN VARCHAR2,
         p_Conc_pgm_name IN VARCHAR2)
      RETURN VARCHAR
      IS
      x_template       VARCHAR2 (100);
            BEGIN
                SELECT description
                INTO   x_template
                FROM   fnd_lookup_values
                WHERE  lookup_type = 'XX_INTG_RPT_OU_TEMPLATE_SS'
                       AND meaning = p_org_name
                                     ||'|'
                                     ||p_Conc_pgm_name
                       -- AND tag           = p_conc_pgm_short_name
                       AND LANGUAGE = 'US';
             RETURN x_template;
            EXCEPTION
                WHEN no_data_found THEN
                  SELECT description
                  INTO   x_template
                  FROM   fnd_lookup_values
                  WHERE  lookup_type = 'XX_INTG_RPT_OU_TEMPLATE_SS'
                         AND meaning = 'DEFAULT'
                                       ||'|'
                                       ||p_Conc_pgm_name
                         -- AND tag           = p_conc_pgm_short_name
                         AND LANGUAGE = 'US';
                --  RETURN v_temp;
                WHEN OTHERS THEN
                  x_template := NULL;

                  RETURN x_template;
      END;



END;

/
