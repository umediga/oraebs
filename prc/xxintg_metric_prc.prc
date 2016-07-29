DROP PROCEDURE APPS.XXINTG_METRIC_PRC;

CREATE OR REPLACE PROCEDURE APPS."XXINTG_METRIC_PRC" (
   errbuf    OUT   VARCHAR2,
   retcode   OUT   VARCHAR2
)
AS
   v_biom_file_type   UTL_FILE.file_type;
   v_biom_data_dir    VARCHAR2 (80);
   v_biom_data        VARCHAR2 (4000);
   v_biom_hdr         VARCHAR2 (200);
   v_file_name        VARCHAR2 (80);
   v_error_flag       VARCHAR2 (1)       := 'S';
   v_dash_line        VARCHAR2 (80);
   v_empty_line       VARCHAR2 (80);
   v_count            NUMBER;
   v_amount           NUMBER;
   v_amount_e         NUMBER;
   v_amount_p         NUMBER;
   v_amount_s         NUMBER;
   v_to_email         VARCHAR2 (240);
   v_from_email       VARCHAR2 (240);
   x_error_code       NUMBER;

   CURSOR c_toemail
   IS
      SELECT parameter_value email
        FROM xx_emf_process_parameters xepp, xx_emf_process_setup xeps
       WHERE xeps.process_name = 'XXINTGAPPTRN'
         AND xeps.process_id = xepp.process_id
         AND xepp.parameter_name = 'TO_EMAIL';
BEGIN
   x_error_code := xx_emf_pkg.set_env;
   v_dash_line :=
      '--------------------------------------------------------------------------------';
   v_empty_line := '';
   v_file_name := 'METRICS_' || TO_CHAR (SYSDATE - 1, 'DD_MON_RRRR')
                  || '.txt';
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                         'File Name         -> ' || v_file_name
                        );
   xx_intg_common_pkg.get_process_param_value
                                            (p_process_name      => 'XXINTGAPPTRN',
                                             p_param_name        => 'DATA_DIR',
                                             x_param_value       => v_biom_data_dir
                                            );
   xx_intg_common_pkg.get_process_param_value
                                            (p_process_name      => 'XXINTGAPPTRN',
                                             p_param_name        => 'FROM_EMAIL',
                                             x_param_value       => v_from_email
                                            );

   BEGIN
      v_biom_file_type :=
              UTL_FILE.fopen_nchar (v_biom_data_dir, v_file_name, 'W', 32767);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'File Opened for writing.');
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'Invalid Path for File Creation:' || v_biom_data_dir;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'File handle is invalid for File :' || v_file_name;
      WHEN UTL_FILE.write_error
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'Unable to write the File :' || v_file_name;
      WHEN UTL_FILE.invalid_operation
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'File could not be opened for writing:' || v_file_name;
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'Invalid Max Line Size ' || v_file_name;
      WHEN UTL_FILE.access_denied
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'Access denied for File :' || v_file_name;
      WHEN OTHERS
      THEN
         v_error_flag := 'E';
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'File ' || v_file_name || '-' || SQLERRM;
   END;

   IF v_error_flag != 'E'
   THEN
      v_biom_hdr :=
            '                        Production Data Volume for '
         || TO_CHAR (SYSDATE - 1, 'DD-MON-RRRR');
      UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_hdr);
      UTL_FILE.put_line_nchar (v_biom_file_type, v_dash_line);
      v_biom_data := NULL;
      v_count := 0;

      --Number of Order Lines Entered
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_lines_all
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1)
            AND NVL (cancelled_flag, 'N') != 'Y'
            AND line_category_code = 'ORDER';

         v_biom_data :=
               'Number of Order Lines Entered                   : '
            || ROUND (v_count, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_amount := 0;

      --$ Value of Order Lines Entered
      BEGIN
         SELECT NVL (SUM (  NVL (ordered_quantity, 0)
                          * NVL (unit_selling_price, 0)
                         ),
                     0
                    )
           INTO v_amount_e
           FROM apps.oe_order_lines_all
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1)
            AND NVL (cancelled_flag, 'N') != 'Y'
            AND line_category_code = 'ORDER';

         v_biom_data :=
               '$ Value of Order Lines Entered                  : $'
            || ROUND (v_amount_e, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an Order Line Entered        : $'
            || ROUND (v_amount_e / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an Order Line Entered        : $0';
         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;
      v_amount := 0;

      --Number of Order Lines Picked
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_lines_all ool,
                apps.mtl_material_transactions mmt,
                apps.mtl_transaction_types mtl
          WHERE 1 = 1
            AND ool.line_id = mmt.trx_source_line_id
            AND mmt.transaction_type_id = mtl.transaction_type_id
            AND mtl.transaction_type_name = 'Sales Order Pick'
            AND NVL (ool.cancelled_flag, 'N') != 'Y'
            AND ool.line_category_code = 'ORDER'
            AND TRUNC (mmt.transaction_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               'Number of Order Lines Picked                    : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      --v_count := 0;
      v_amount := 0;

      --Amount of Order Lines Picked
      BEGIN
         SELECT NVL (SUM (  NVL (ordered_quantity, 0)
                          * NVL (unit_selling_price, 0)
                         ),
                     0
                    )
           INTO v_amount_p
           FROM apps.oe_order_lines_all ool,
                apps.mtl_material_transactions mmt,
                apps.mtl_transaction_types mtl
          WHERE 1 = 1
            AND ool.line_id = mmt.trx_source_line_id
            AND mmt.transaction_type_id = mtl.transaction_type_id
            AND NVL (cancelled_flag, 'N') != 'Y'
            AND line_category_code = 'ORDER'
            AND mtl.transaction_type_name = 'Sales Order Pick'
            AND TRUNC (mmt.transaction_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               '$ Value of Order Lines Picked                   : '
            || ROUND (v_amount_p, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an Order Line Picked         : $'
            || ROUND (v_amount_p / v_count, 0);

          ELSE
          v_biom_data :=
               'Average $ Value of an Order Line Picked         : $0';
          END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of Order Lines Shipped
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_lines_all
          WHERE TRUNC (actual_shipment_date) = TRUNC (SYSDATE - 1)
            AND NVL (cancelled_flag, 'N') != 'Y'
            AND line_category_code = 'ORDER';

         v_biom_data :=
               'Number of Order Lines Shipped                   : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      --v_count := 0;
      v_amount := 0;

      --$ Value of Order Lines Shipped
      BEGIN
         SELECT NVL (SUM (  NVL (ordered_quantity, 0)
                          * NVL (unit_selling_price, 0)
                         ),
                     0
                    )
           INTO v_amount_s
           FROM apps.oe_order_lines_all
          WHERE TRUNC (actual_shipment_date) = TRUNC (SYSDATE - 1)
            AND NVL (cancelled_flag, 'N') != 'Y'
            AND line_category_code = 'ORDER';

         v_biom_data :=
               '$ Value of Order Lines Shipped                  : $'
            || ROUND (v_amount_s, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an Order Line Shipped        : $'
            || ROUND (v_amount_s / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an Order Line Shipped        : $0';

         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of Order Lines Entered
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_headers_all
          WHERE header_id IN (
                   SELECT header_id
                     FROM apps.oe_order_lines_all
                    WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1)
                      AND NVL (cancelled_flag, 'N') != 'Y'
                      AND line_category_code = 'ORDER');

         v_biom_data :=
               'Number of Orders Entered                        : '
            || ROUND (v_count, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count >0 THEN
         v_biom_data :=
               'Average $ Value of an Order Entered             : $'
            || ROUND (v_amount_e / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an Order Entered             : $0';
         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
      END;

      v_biom_data := NULL;
      v_count := 0;
      v_amount := 0;

      --Number of Orders Picked
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_headers_all
          WHERE header_id IN (
                   SELECT ool.header_id
                     FROM apps.oe_order_lines_all ool,
                          apps.mtl_material_transactions mmt,
                          apps.mtl_transaction_types mtl
                    WHERE 1 = 1
                      AND ool.line_id = mmt.trx_source_line_id
                      AND NVL (cancelled_flag, 'N') != 'Y'
                      AND line_category_code = 'ORDER'
                      AND mmt.transaction_type_id = mtl.transaction_type_id
                      AND mtl.transaction_type_name = 'Sales Order Pick'
                      AND TRUNC (mmt.transaction_date) = TRUNC (SYSDATE - 1));

         v_biom_data :=
               'Number of Orders Picked                         : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an Order Picked              : $'
            || ROUND (v_amount_p / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an Order Picked              : $0';
         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of Orders Shipped
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.oe_order_headers_all
          WHERE header_id IN (
                   SELECT header_id
                     FROM apps.oe_order_lines_all
                    WHERE TRUNC (actual_shipment_date) = TRUNC (SYSDATE - 1)
                      AND NVL (cancelled_flag, 'N') != 'Y'
                      AND line_category_code = 'ORDER');

         v_biom_data :=
               'Number of Orders Shipped                        : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an Order Shipped             : $'
            || ROUND (v_amount_s / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an Order Shipped             : $0';
         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of A/R Invoices Generated
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.ra_customer_trx_all
          WHERE customer_trx_id IN (
                   SELECT customer_trx_id
                     FROM apps.ra_customer_trx_lines_all il,
                          apps.oe_order_lines_all ol
                    WHERE il.interface_line_attribute6 = ol.line_id
                      AND ol.line_category_code = 'ORDER'
                      AND TRUNC (il.creation_date) = TRUNC (SYSDATE - 1));

         v_biom_data :=
               'Number of AR Invoices Created                   : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --$ Value of A/R Invoices Generated
      BEGIN
         SELECT SUM (extended_amount)
           INTO v_amount
           FROM apps.ra_customer_trx_lines_all il, apps.oe_order_lines_all ol
          WHERE il.interface_line_attribute6 = ol.line_id
            AND ol.line_category_code = 'ORDER'
            AND TRUNC (il.creation_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               '$ Value of AR Invoices Created                  : $'
            || ROUND (v_amount, 0);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
         IF v_count > 0 THEN
         v_biom_data :=
               'Average $ Value of an AR Invoice                : $'
            || ROUND (v_amount / v_count, 0);
         ELSE
         v_biom_data :=
               'Average $ Value of an AR Invoice                : $0';
         END IF;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of Purchase Orders Created
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.po_headers_all
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               'Number of Purchase Orders Created               : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of A/P Invoices Processed
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.xla_events
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1)
            AND event_type_code = 'INVOICE VALIDATED';

         v_biom_data :=
               'Number of AP Invoices Created                   : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --Number of Quotes Entered
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM apps.aso_quote_headers_all
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               'Number of Quotes Entered                        : ' || v_count;
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_count := 0;

      --$ Value of Quotes Entered
      BEGIN
         SELECT NVL (SUM (NVL (total_quote_price, 0)), 0)
           INTO v_count
           FROM apps.aso_quote_headers_all
          WHERE TRUNC (creation_date) = TRUNC (SYSDATE - 1);

         v_biom_data :=
               '$ Value of Quotes Entered                       : $'
            || ROUND (v_count, 2);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);
         UTL_FILE.put_line_nchar (v_biom_file_type, v_empty_line);
      END;

      v_biom_data := NULL;
      v_biom_data := '                                       End of Report';
      UTL_FILE.put_line_nchar (v_biom_file_type, v_dash_line);
      UTL_FILE.put_line_nchar (v_biom_file_type, v_biom_data);

      /* Close File*/
      IF UTL_FILE.is_open (v_biom_file_type)
      THEN
         UTL_FILE.fclose (v_biom_file_type);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Data File Closed.');
      END IF;

      v_to_email := NULL;

      FOR v_toemail IN c_toemail
      LOOP
         v_to_email := v_to_email || v_toemail.email || ',';
      END LOOP;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'To Email :' || v_to_email);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'From Email :' || v_from_email
                           );
      xx_intg_mail_util_pkg.send_mail_attach
         (p_from_name             => v_from_email,
          p_to_name               => v_to_email,
          p_cc_name               => NULL,
          p_bc_name               => NULL,
          p_subject               =>    'Production Data Volume for '
                                     || TO_CHAR (SYSDATE - 1, 'DD-MON-RRRR'),
          p_message               => 'Attached File with Metrics of Yesterday Transactions in Production',
          p_oracle_directory      => v_biom_data_dir,
          p_binary_file           => v_file_name
         );
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
      retcode := xx_emf_cn_pkg.cn_prc_err;
      errbuf := SQLERRM;
END xxintg_metric_prc;
/
