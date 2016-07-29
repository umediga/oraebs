DROP PACKAGE BODY APPS.XX_ONT_SO_ACKNOWLEDGE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_SO_ACKNOWLEDGE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-APR-2012
 File Name     : XX_ONT_SO_ACKNOWLEDGE_PKG.pkb
 Description   : This script creates the body of the package
                  xx_ont_so_acknowledge_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-APR-2012 Sharath Babu          Initial Development
 10-MAY-2012 Sharath Babu          Modified arguments list
 15-MAY-2012 Sharath Babu          Commented wait statement
 02-Aug-2012 Renjith               added parameter p_title as per CR
 31-Aug-2012 Renjith               added exceptions for Internal orders
 20-Mar-2013 Renjith               Added code for charge sheet, O2C-EXT_054
 16-APR-2013 Sharath Babu          Modified to include output type parm as per DCR
 27-May-2013 Deepta Nityanand      Modified to add the report INTG RMA Pack List  Report
*/
----------------------------------------------------------------------
   FUNCTION send_so_ack_email (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
      x_application             VARCHAR2 (10)                     := 'XXINTG';
      x_program_name1           VARCHAR2 (20)            := 'XXONTSOCNFMMAIN';
      x_program_desc            VARCHAR2 (50)
                                           := 'INTG Sales Order Confirmation';
      x_program_name2           VARCHAR2 (20)             := 'XXONTCHRGSHEET';
      x_program_name3           VARCHAR2 (20)           := 'XXINTGOMOEXOEACK';
      -- 'INTG RMA Pack List  Report'
      x_reqid                   NUMBER;
      x_header_id               NUMBER;
      x_user_id                 NUMBER                  := fnd_global.user_id;
      x_resp_id                 NUMBER                  := fnd_global.resp_id;
      x_resp_appl_id            NUMBER             := fnd_global.resp_appl_id;
      x_org_id                  NUMBER        := fnd_profile.VALUE ('ORG_ID');
      x_err_msg                 VARCHAR2 (1000);
      x_order_number            NUMBER;
      x_sotype_name             VARCHAR2 (240);
      x_source_name             VARCHAR2 (240);
      x_solookup_meaning        VARCHAR2 (80);
      x_soexception_flag        VARCHAR2 (1)                           := 'N';
      x_source_exception_flag   VARCHAR2 (1)                           := 'N';
      x_cons_type               VARCHAR2 (80);
      x_cons_flag               VARCHAR2 (1)                           := 'N';
      x_layout_status           BOOLEAN                              := FALSE;
      x_sob                     NUMBER;
      x_email                   oe_order_headers_all.attribute4%TYPE;
      x_flex_code               VARCHAR2 (50);
      x_lkup                    VARCHAR2 (50);
      x_lkup1                   VARCHAR2 (50);
      x_ord_type                NUMBER;
      c_ret_ord_typ    CONSTANT VARCHAR2 (30)           := 'ILS RETURN ORDER';
      x_ret_ord_typ             VARCHAR2 (30);
      x_rma_flag                VARCHAR2 (1);
   BEGIN
      x_header_id := p_event.getvalueforparameter ('HEADER_ID');

      --x_header_id := p_event.geteventkey ();
      BEGIN
         SELECT ooh.order_number, typ.NAME,
                REPLACE (ooh.attribute4, ';', ',')
           -- Added for DCR for XXINTGOMOEXOEACK
         INTO   x_order_number, x_sotype_name,
                x_email
           FROM oe_order_headers_all ooh, oe_transaction_types_tl typ
          WHERE 1 = 1
            AND ooh.booked_flag = 'Y'
            AND ooh.flow_status_code = 'BOOKED'
            AND ooh.order_type_id = typ.transaction_type_id
            AND typ.LANGUAGE = 'US'
            AND ooh.header_id = x_header_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_order_number := NULL;
            x_sotype_name := NULL;
            x_email := NULL;            -- Added for DCR for XXINTGOMOEXOEACK
      END;

      BEGIN
         SELECT meaning
           INTO x_cons_type
           FROM fnd_lookup_values_vl
          WHERE lookup_type = 'XXOM_CONSIGNMENT_ORDER_TYPES'
            AND NVL (enabled_flag, 'X') = 'Y'
            AND meaning = x_sotype_name
            AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                            AND NVL (end_date_active, SYSDATE);

         x_cons_flag := 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            x_cons_flag := 'N';
            x_cons_type := NULL;
      END;

      BEGIN
         SELECT meaning
           INTO x_ret_ord_typ
           FROM fnd_lookup_values_vl
          WHERE lookup_type = 'XXOM_RMA_RETURN_ORDER_TYPES'
            AND NVL (enabled_flag, 'X') = 'Y'
            AND meaning = x_sotype_name
            AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                            AND NVL (end_date_active, SYSDATE);

         x_rma_flag := 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            x_rma_flag := 'N';
            x_ret_ord_typ := NULL;
      END;

      IF NVL (x_cons_flag, 'N') = 'Y'
      THEN
         IF x_order_number IS NOT NULL
         THEN
            fnd_global.apps_initialize (x_user_id,                  --User id
                                        x_resp_id,        --responsibility_id
                                        x_resp_appl_id);     --application_id
            x_layout_status :=
               fnd_request.add_layout (template_appl_name      => x_application,
                                       template_code           => 'XXONTCHRGSHEET',
                                       template_language       => 'en',
                                       template_territory      => 'US',
                                       output_format           => 'PDF'
                                      );
            --Submit request
            x_reqid :=
               fnd_request.submit_request (application      => x_application,
                                           program          => x_program_name2,
                                           description      => NULL,
                                           start_time       => SYSDATE,
                                           sub_request      => FALSE,
                                           argument1        => x_header_id,
                                           argument2        => NULL,
                                           argument3        => 'Y',
                                           argument4        => NULL
                                          );
            COMMIT;
         END IF;
      ELSIF NVL (x_rma_flag, 'X') = 'Y'
      THEN
         IF x_email IS NOT NULL
         THEN
            BEGIN
               SELECT TO_NUMBER (oe_sys_parameters.VALUE ('SET_OF_BOOKS_ID'))
                 INTO x_sob
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_sob := NULL;
            END;

            BEGIN
               SELECT order_type_id
                 INTO x_ord_type
                 FROM oe_order_types_v ot
                WHERE ot.org_id = fnd_profile.VALUE ('ORG_ID')
                  AND UPPER (NAME) = c_ret_ord_typ;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_ord_type := NULL;
            END;

            x_flex_code := fnd_profile.VALUE ('OE_ID_FLEX_CODE');
            fnd_global.apps_initialize (x_user_id,                   --User id
                                        x_resp_id,         --responsibility_id
                                        x_resp_appl_id);      --application_id
            --Submit request
            fnd_request.set_org_id (x_org_id);
            x_layout_status :=
               fnd_request.add_layout (template_appl_name      => x_application,
                                       template_code           => 'XXINTGOMOEXOEACK',
                                       template_language       => 'en',
                                       template_territory      => 'US',
                                       output_format           => 'PDF'
                                      );
            x_reqid :=
               fnd_request.submit_request (application      => x_application,
                                           program          => 'XXINTGOMOEXOEACK',
                                           description      => NULL,
                                           start_time       => SYSDATE,
                                           sub_request      => FALSE,
                                           argument1        => x_sob,
                                           argument2        => x_flex_code,
                                           --'MSTK',
                                           argument3        => 'I',
                                           --x_lkup,     --'I',
                                           argument4        => 'Y',
                                           --x_lkup1,    --'Y',
                                           argument5        => x_ord_type,
                                           --NULL,
                                           argument6        => x_order_number,
                                           argument7        => x_order_number,
                                           argument8        => NULL,
                                           argument9        => NULL,
                                           argument10       => NULL,
                                           argument11       => NULL,
                                           argument12       => NULL,
                                           argument13       => NULL,
                                           argument14       => NULL,
                                           argument15       => NULL,
                                           argument16       => NULL,
                                           argument17       => NULL,
                                           argument18       => NULL,
                                           argument19       => NULL,
                                           argument20       => 'SALES',
                                           argument21       => 'ALL',
                                           argument22       => NULL,
                                           argument23       => NULL,
                                           argument24       => 'Y',
                                           argument25       => NULL,
                                           argument26       => NULL,
                                           argument27       => 'N',
                                           argument28       => 'N',
                                           argument29       => 'Y',
                                           argument30       => NULL,
                                           argument31       => 'N'
                                          );
            COMMIT;
         END IF;
      ELSE
         BEGIN
            SELECT meaning
              INTO x_solookup_meaning
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'XXOM_SALES_ACK_EXCEPTIONS'
               AND NVL (enabled_flag, 'X') = 'Y'
               AND meaning = x_sotype_name
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);

            x_soexception_flag := 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               x_soexception_flag := 'N';
         END;

         --Check Order Source for EDI orders from GHX Mailbox
         BEGIN
            SELECT oos.NAME
              INTO x_source_name
              FROM oe_order_headers_all ooh, oe_order_sources oos
             WHERE 1 = 1
               AND ooh.order_source_id = oos.order_source_id
               AND ooh.header_id = x_header_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_source_name := NULL;
         END;

         x_solookup_meaning := NULL;

         BEGIN
            SELECT meaning
              INTO x_solookup_meaning
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'XXOM_SALES_ACK_SOURCE_EXCEPT'
               AND NVL (enabled_flag, 'X') = 'Y'
               AND meaning = x_source_name
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);

            x_source_exception_flag := 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               x_source_exception_flag := 'N';
         END;

         IF     x_order_number IS NOT NULL
            AND NVL (x_soexception_flag, 'N') = 'N'
            AND NVL (x_source_exception_flag, 'N') = 'N'
         THEN
            fnd_global.apps_initialize (x_user_id,                  --User id
                                        x_resp_id,        --responsibility_id
                                        x_resp_appl_id);     --application_id
            --Submit request
            x_reqid :=
               fnd_request.submit_request (application      => x_application,
                                           program          => x_program_name1,
                                           description      => x_program_desc,
                                           start_time       => SYSDATE,
                                           sub_request      => FALSE,
                                           argument1        => 'S'       --'C'
                                                                  ,
                                           argument2        => x_header_id,
                                           argument3        => 'Y',
                                           argument4        => NULL,
                                           argument5        => NULL,
                                           argument6        => 'PDF'
                                          --Added as per DCR
                                          );
            COMMIT;
         END IF;
      END IF;                                                          -- type

      COMMIT;
      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'ERROR';
   END send_so_ack_email;
END xx_ont_so_acknowledge_pkg;
/
