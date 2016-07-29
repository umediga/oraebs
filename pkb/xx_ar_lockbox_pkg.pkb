DROP PACKAGE BODY APPS.XX_AR_LOCKBOX_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_LOCKBOX_PKG" 
----------------------------------------------------------------------
/* $Header: XXARLOCKBOXINT.pkb 1.0 2012/02/08 12:00:00 schakraborty noship $ */
/*
Created By     : IBM Development Team
Creation Date  : 22-Feb-2012
File Name      : XX_AR_LOCKBOX_PKG.pkb
Description    : This script creates the specification of the XX_AR_LOCKBOX_PKG package
Change History:
Version Date        Name                    Remarks
------- ----------- ----                    ----------------------
1.0     22-Feb-12   IBM Development Team    Initial development.
1,1     04-Oct-12   ABhargava/KSeal         Modified foe Multiple Files and OU Derivation
1.2     22-NOV-2013  Jagdish Bhosale        Added parameter for seeded lock box program
*/
/*----------------------------------------------------------------------*/
AS
   /*----------------------------------------------------------------------*/
   /*--- Cursor Declaration     N/A                                           */
   /*----------------------------------------------------------------------*/

   /*----------------------Env Set-----------------------*/
   PROCEDURE set_cnv_env (p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;

   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In xx_ar_lockbox_pks.' || G_API_NAME || ': ' || p_dbg_text);
   END dbg_low;

   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'In xx_ar_lockbox_pks' || G_API_NAME || ': ' || p_dbg_text);
   END dbg_med;

   /*---------------------------------------------*/
   PROCEDURE xx_ar_process_lockbox (p_errbuf              OUT VARCHAR2,
                                    p_retcode             OUT VARCHAR2,
                                    x_format_name      IN     VARCHAR2,
                                    p_data_filename    IN     VARCHAR2,
                                    x_operating_unit   IN     VARCHAR2)
   IS
      /*--- Variable Declaration */
      x_process_ctl_id   NUMBER;
      x_wrapper          NUMBER;
      x_error_code       NUMBER;
      x_request_id       NUMBER;
      x_batch_id         NUMBER;
      x_total_cnt        NUMBER;
      x_ou               VARCHAR2 (10) := NULL;
   BEGIN
      /* Submit First Concurrent Program */
      /* Setting EMF enviornment*/
      set_cnv_env (xx_emf_cn_pkg.CN_YES);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Calling ARLOCKBOX Set_cnv_env');

      -- Change by Kunal on 20-Sep-2012 for selection OU from mapping
      BEGIN
         IF (x_operating_unit IS NULL)
         THEN

            SELECT   organization_id
              INTO   x_ou
              FROM   HR_OPERATING_UNITS
             WHERE   name = (SELECT  PARAMETER_VALUE
                             from xx_emf_process_parameters a,
                                  xx_emf_process_setup b
                             where a.process_id = b.process_id
                             and   b.process_name = 'XXARLOCKBOXINT'
                             and instr(p_data_filename,parameter_name) > 0);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Operating Unit : ' || x_ou);

            IF (x_ou IS NULL)
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'OU-Bank Name mapping not Exists');
               raise_application_error (-20001, 'OU-Bank Name mapping not Found');
            ELSE
               G_OPERATING_UNIT := x_ou;
            END IF;
         ELSE
            G_OPERATING_UNIT := x_operating_unit;
         END IF;
      END;


      /*----------------------------------------------------------------------*/
      x_request_id := fnd_global.conc_request_id;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Retreiving Wrapper program request id: ' || x_request_id);

      BEGIN
         SELECT   transmission_format_id
           INTO   G_TRANSMISSION_FORMAT_ID
           FROM   ar_transmission_formats
          WHERE   format_name =
                     NVL (x_format_name,     -- if NULL get it from Process setup, Kunal 20-Sep-2012
                          xx_emf_pkg.get_paramater_value ('XXARLOCKBOXINT', 'format_name')); --'INTG BOA LOCKBOX';
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.cn_high,
               'transmission_format_id not found against supplied value: '
               || NVL (x_format_name,        -- if NULL get it from Process setup, Kunal 20-Sep-2012
                       xx_emf_pkg.get_paramater_value ('XXARLOCKBOXINT', 'format_name'))
            );
            x_error_code := SQLCODE;
            xx_emf_pkg.propagate_error (x_error_code);
      END;

      IF G_TRANSMISSION_FORMAT_ID IS NOT NULL
      THEN
         IF (xx_ar_initiate (G_TRANSMISSION_FORMAT_ID, p_data_filename) <> TRUE)
         THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, G_ERRBUF);
            COMMIT;
            p_errbuf := G_ERRBUF;
            p_retcode := 2;

            RAISE E_FATAL_ERROR;
         END IF;

         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                  'Request Id returned from Process Lockbox is: ' || G_REQUEST_ID);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Receipts Counting');

            SELECT   batch_id
              INTO   x_batch_id
              FROM   ar_batches_all
             WHERE   request_id = G_REQUEST_ID;

            SELECT   COUNT (1)
              INTO   x_total_cnt
              FROM   AR_INTERIM_CASH_RECEIPTS_all
             WHERE   batch_id = batch_id;

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.cn_high,
               'Receipts created in this request, Please refer Process Lockbox program LOG for details'
            );
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                     'No receipts created in this request: ' || x_request_id);
               x_batch_id := NULL;
               x_total_cnt := 0;
         END;
      ELSE
         x_total_cnt := 0;
         p_errbuf := SQLERRM;
         p_retcode := 2;
         RAISE E_FATAL_ERROR;
      END IF;

      COMMIT;
   /*----------------------------------------------------------------------*/

   EXCEPTION
      WHEN E_FATAL_ERROR
      THEN
         p_errbuf := 'LOCKBOX Process Failed at wrapper program level';
         p_retcode := 2;
      WHEN OTHERS
      THEN
         p_errbuf := 'LOCKBOX Process Failed at wrapper program level';
         p_retcode := 2;
   END xx_ar_process_lockbox;

   /*----------------------------------------------------------------------*/

   /*--- This function is to initiate First Concurrent Program             */

   /*----------------------------------------------------------------------*/

   FUNCTION xx_ar_initiate (p_transmission_format_id IN NUMBER, p_data_filename IN VARCHAR2)
      RETURN BOOLEAN
   IS
      /* --- Variable Declaration  */
      x_submit_req_id     NUMBER;
      x_conc_request_id   NUMBER;
      x_datafile          VARCHAR2 (240);
      x_ctlfile           VARCHAR2 (240);
      x_wrapper           NUMBER;
      x_org_id            NUMBER := fnd_global.org_id;
      x_wait              VARCHAR2 (10) := 'Y';
      x_phase             VARCHAR2 (100);
      x_status            VARCHAR2 (100);
      x_dev_phase         VARCHAR2 (100);
      x_dex_status        VARCHAR2 (100);
      x_message           VARCHAR2 (240);
      x_check             BOOLEAN;
      x_error_code        NUMBER;
      x_instance_name     VARCHAR2 (240);
      x_identifier2       VARCHAR2 (240);
      x_identifier3       VARCHAR2 (240);
      x_identifier4       VARCHAR2 (1);
   /*----------------------------------------------------------------------*/
   BEGIN
      BEGIN
         /*--- Using process setup form to get Lockbox number and against it deriving lockbox id---*/
         SELECT   ala.lockbox_id
           INTO   G_LOCKBOX_ID
           FROM   xx_emf_process_parameters xepp, xx_emf_process_setup xeps, ar_lockboxes_all ala
          WHERE       xepp.process_id = xeps.process_id
                  AND xeps.process_name = 'XXARLOCKBOXINT'
                  AND parameter_name = 'IDENTIFIER4'
                  AND xepp.parameter_value = ala.lockbox_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            G_LOCKBOX_ID := NULL;
      END;

      SELECT   instance_name INTO x_instance_name FROM v$instance;

      SELECT   directory_path || '/' || p_data_filename
        INTO   x_datafile
        FROM   all_directories
       WHERE   directory_name = 'XXARLOCKBOXDATA';

      G_TRANS_NAME := 'Lockbox' || TO_CHAR (SYSDATE, 'yyyy/mm/dd hh:mm:ss');
      x_ctlfile := 'XXARLOCKBOXLDR';
      x_wrapper := apps.fnd_global.conc_request_id;

      IF G_OPERATING_UNIT = NULL
      THEN
         G_ERRBUF := x_error_code;
         G_RETCODE := '2';
      END IF;

      /*--------Setting Org-----------*/
      fnd_request.set_org_id (G_OPERATING_UNIT);
      /*--------Calling Lockbox program-----------*/
      x_submit_req_id :=
         FND_REQUEST.SUBMIT_REQUEST (application   => 'AR',
                                     program       => 'ARLPLB',
                                     description   => NULL,
                                     start_time    => NULL,
                                     sub_request   => NULL,
                                     argument1     => 'Y'                       -- CODE_NEW_TRANS_YN
                                                         ,
                                     argument2     => ''                          -- TRANSMISSION_ID
                                                        ,
                                     argument3     => ''                  -- TRANSMISSION_REQUEST_ID
                                                        ,
                                     argument4     => G_TRANS_NAME              -- TRANSMISSION_NAME
                                                                  ,
                                     argument5     => 'Y'                      -- CODE_RUN_IMPORT_YN
                                                         ,
                                     argument6     => x_datafile                        -- FILE_NAME
                                                                ,
                                     argument7     => x_ctlfile                      -- CONTROL_FILE
                                                               ,
                                     argument8     => G_TRANSMISSION_FORMAT_ID -- TRANSMISSION_FORMAT_ID
                                                                              ,
                                     argument9     => 'Y'                  -- CODE_RUN_VALIDATION_YN
                                                         ,
                                     argument10    => 'N'          -- CODE_PAY_UNRELATED_INVOICES_YN
                                                         ,
                                     argument11    => ''       --G_LOCKBOX_ID          -- LOCKBOX_ID
                                                        ,
                                     argument12    => TO_CHAR (SYSDATE, 'yyyy/mm/dd hh:mm:ss') -- GL_DATE
                                                                                              ,
                                     argument13    => 'A'                      -- CODE_REPORT_FORMAT
                                                         ,
                                     argument14    => 'N'                -- CODE_COMPLETE_BATCHES_YN
                                                         ,
                                     argument15    => 'N' --'Y'              -- CODE_RUN_APPL_YN(Post Quick Cash)
                                                         ,
                                     argument16    => 'N' --'Y'              -- Alternate name search
                                                         ,
                                     argument17    => ''                   -- IGNORE_INVALID_TXN_NUM
                                                        ,
                                                                          argument18    => ''                   -- USSGL_Transaction_code
                                                        ,
                                     argument19    => x_org_id                                --'82'
                                                              ,
                                     -----------------------------------------------------------------
                                     -- New Parameters added after WAVE1 Patching Jagdish 10/21/2013
                                     -------------------------------------------------------------------
                                     argument20    => '',       --20. apply unearn discounts
                                     argument21    => 1,        --21. Number of instances
                                     argument22    => 'L',
                                     argument23    => '');

      COMMIT;
      G_REQUEST_ID := x_submit_req_id;

      /*----------------------------------------------------------------------*/
      IF x_wait = 'Y'
      THEN
         LOOP
            /* Wait for the completion of Import Items program */
            x_check :=
               fnd_concurrent.wait_for_request (x_submit_req_id,
                                                1,
                                                0,
                                                x_phase,
                                                x_status,
                                                x_dev_phase,
                                                x_dex_status,
                                                x_message);

            /* If the request terminates successfully then show log message. */
            IF (UPPER (x_dev_phase) = 'COMPLETE')
               AND UPPER (x_status) NOT IN ('ERROR', 'CANCELLED', 'TERMINATED')
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, 'Loader Program Status: ' || x_dex_status);

               /*-------- Retrieving directory values and mode from process setup form--------*/

               BEGIN
                  SELECT   directory_path || '/'
                    INTO   x_identifier2
                    FROM   all_directories
                   WHERE   directory_name = 'XXARLOCKBOXDATA';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           'Error getting directory for data file');
               END;

               BEGIN
                  SELECT   directory_path
                    INTO   x_identifier3
                    FROM   all_directories
                   WHERE   directory_name = 'XXARLOCKBOXARCH';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           'Error getting directory for archive file');
               END;

               BEGIN
                  SELECT   parameter_value
                    INTO   x_identifier4
                    FROM   XX_EMF_PROCESS_PARAMETERS xepp, xx_emf_process_setup xeps
                   WHERE       xepp.process_id = xeps.process_id
                           AND xeps.process_name = 'XXINTGFILEMOV'
                           AND parameter_name = 'IDENTIFIER2';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           'Error getting file movement mode');
               END;

               /*---------------------------------*/
               /*--------Calling the Common File movement program---------*/
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'argument1: ' || p_data_filename);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'argument2: ' || x_identifier2);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'argument3: ' || x_identifier3);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'argument4: ' || x_identifier4);
               x_conc_request_id :=
                  fnd_request.submit_request (application   => 'XXINTG',
                                              program       => 'XXINTGFILEMOV',
                                              sub_request   => FALSE,
                                              argument1     => p_data_filename,
                                              argument2     => x_identifier2,
                                              argument3     => x_identifier3,
                                              argument4     => x_identifier4);
               RETURN (TRUE);
            END IF;                                               --request terminates successfully.

            IF (UPPER (x_dev_phase) = 'COMPLETE')
               AND UPPER (x_status) IN ('ERROR', 'CANCELLED', 'TERMINATED')
            THEN
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.cn_high,
                  'Loader Program Status: ' || x_dex_status || ' Not successful2'
               );
               EXIT;
            END IF;
         END LOOP;
      END IF;

      /*----------------------------------------------------------------------*/
      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         G_ERRBUF := SQLCODE || ', ' || SQLERRM;
         G_RETCODE := '2';
         RETURN (FALSE);
   END xx_ar_initiate;
END XX_AR_LOCKBOX_PKG;
/
