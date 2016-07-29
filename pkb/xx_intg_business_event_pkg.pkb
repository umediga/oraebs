DROP PACKAGE BODY APPS.XX_INTG_BUSINESS_EVENT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_BUSINESS_EVENT_PKG" 
AS

-- **********************************************************************
--    Procedure to set environment.
-- **********************************************************************
PROCEDURE set_cnv_env (p_required_flag VARCHAR2
                       DEFAULT xx_emf_cn_pkg.cn_yes)
IS

  x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;

BEGIN

  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');

  -- Set the environment
  x_error_code := xx_emf_pkg.set_env(p_process_name => 'XX_R2R_INT_045');

  IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
  THEN
     xx_emf_pkg.propagate_error (x_error_code);
  END IF;

EXCEPTION
  WHEN OTHERS
  THEN
     RAISE xx_emf_pkg.g_e_env_not_set;
END set_cnv_env;


FUNCTION XX_INTG_BEVENT_GXP   ( p_subscription_guid IN RAW
                                ,p_event IN OUT NOCOPY wf_event_t)
RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
  l_param1 NUMBER;
  l_param2 NUMBER;

  l_proc_name   VARCHAR2(100);

  l_conc_param1 VARCHAR2(100);
  l_conc_param2 VARCHAR2(100);
  l_conc_param3 VARCHAR2(100);

  l_req_id      NUMBER;
  l_pay_prof    VARCHAR2(100);

  L_REQUESTED_BY NUMBER;
  L_RESPONSIBILITY_APPL_ID NUMBER;
  L_RESPONSIBILITY_ID NUMBER;

  l_bank_name VARCHAR2(200);
  l_prfx      VARCHAR2(100);

  l_err_count NUMBER;


  g_err_msg    VARCHAR2(200);
BEGIN

  --Set EMF environment
   set_cnv_env;

  l_param1   := p_event.getvalueforparameter(xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','PARAM1'));
  l_param2   := p_event.getvalueforparameter(xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','PARAM2'));

  /*Added for Ticekt#8251 - Start*/
  dbms_lock.sleep(20);
  g_err_msg := 'Error Fetching Concurrent Program Name';
  select b.concurrent_program_name
  into l_proc_name
  from fnd_concurrent_programs b
  where  CONCURRENT_PROGRAM_ID = l_param2;

  BEGIN

  SELECT COUNT(1)
  INTO l_err_count
  FROM fnd_concurrent_requests
  WHERE request_id =   l_param1
  AND phase_code = 'C'
  AND status_code = 'C';

  IF l_err_count = 0 THEN

    g_err_msg := 'Concurrent Request '||l_param1||'Completed in Error/Warning.';
  ------Added EMF Log Message to insert data into EMF table ------
    xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Global XML Payment Disbursement',
                p_error_text               => 'Business Event Failed',
                p_record_identifier_1      => l_proc_name,
                p_record_identifier_2      => g_err_msg,
                p_record_identifier_3      => l_param1,
                p_record_identifier_4      => l_param2
               );
    ------Added EMF Log Message end------

    RETURN('ERROR');
  END IF;

  END;
  /*Added for Ticekt#8251 - End*/
  IF l_proc_name = xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','CONC_PROG_NAME')
  THEN
      g_err_msg := 'Error Fetching Payment Profile Details';
      begin
        select a.payment_format_code
        into l_pay_prof
        from iby_payment_profiles a,
             IBY_PAY_SERVICE_REQUESTS b,
             XXINTG_PAY_DISB_REQID_V c
        where a.PAYMENT_PROFILE_ID = b.PAYMENT_PROFILE_ID
        and   b.CALL_APP_PAY_SERVICE_REQ_CODE = c.argument2
        and   c.request_id =   l_param1;

      -- Added on 13-Aug-13 for R2R-INT-095 (Payment Instruction File) quick payment (start)
    EXCEPTION WHEN NO_DATA_FOUND THEN

        g_err_msg := 'Error Fetching Application Details (Payment Instruction File) quick payment ';
          begin
          select REQUESTED_BY,RESPONSIBILITY_APPLICATION_ID, RESPONSIBILITY_ID
          into L_REQUESTED_BY,L_RESPONSIBILITY_APPL_ID, L_RESPONSIBILITY_ID
          from fnd_concurrent_requests
          where request_id = l_param1;

          fnd_global.apps_initialize(L_REQUESTED_BY,L_RESPONSIBILITY_ID,L_RESPONSIBILITY_APPL_ID);

          g_err_msg := 'Error Fetching Request ID';
          l_conc_param1 := l_param1;

      g_err_msg := 'Error Fetching Directory Path';
          select DIRECTORY_PATH
          into l_conc_param2
          from all_directories where directory_name = 'XXPIFDATA';

          l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         (
                                         application      =>      'XXINTG'
                                        ,program          =>      'XXAPJPMCSUAPIF'
                                        ,description      =>      'Payment Instruction File FTP Program'
                                        ,start_time       =>      SYSDATE
                                        ,sub_request      =>      NULL
                                        ,argument1        =>      l_conc_param1
                                        ,argument2        =>      l_conc_param2
                                        );
           COMMIT;

          ------Added EMF Log Message to insert data into EMF table ------
           xx_emf_pkg.error (
                        p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Global XML Payment Disbursement',
                        p_error_text               => 'Business Event Success',
                        p_record_identifier_1      => l_proc_name,
                        p_record_identifier_2      => l_param1,
                        p_record_identifier_3      => l_param2,
                        p_record_identifier_4      => l_req_id
                       );
          ------Added EMF Log Message end------

          RETURN ('SUCCESS');
      -- Added on 13-Aug-13 for R2R-INT-095 (Payment Instruction File) quick payment (end)

      EXCEPTION
           WHEN OTHERS THEN

          ------Added EMF Log Message to insert data into EMF table ------
           xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Global XML Payment Disbursement',
                p_error_text               => 'Business Event Failed',
                p_record_identifier_1      => l_proc_name,
                p_record_identifier_2      => g_err_msg,
                p_record_identifier_3      => l_param1,
                p_record_identifier_4      => l_param2
               );
    ------Added EMF Log Message end------

    RETURN('ERROR');
    END;
    END;
      IF l_pay_prof = xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','PAY_PROCESS') THEN
          g_err_msg := 'Error Fetching Application Details';
          select REQUESTED_BY,RESPONSIBILITY_APPLICATION_ID, RESPONSIBILITY_ID
          into L_REQUESTED_BY,L_RESPONSIBILITY_APPL_ID, L_RESPONSIBILITY_ID
          from fnd_concurrent_requests
          where request_id = l_param1;

          fnd_global.apps_initialize(L_REQUESTED_BY,L_RESPONSIBILITY_ID,L_RESPONSIBILITY_APPL_ID);

          g_err_msg := 'Error Fetching Request ID';
          l_conc_param1 := l_param1;

          g_err_msg := 'Error Fetching Bank Code';
          select BANK_NAME,BANK_ACCOUNT_NAME
          into l_conc_param2,l_bank_name
          from XXINTG_PAY_DISB_BANK_V
          where request_id =  l_conc_param1;

          l_prfx :=  xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045',l_bank_name);

          IF l_prfx IS NOT NULL THEN
              l_conc_param2 := l_prfx||'_'||l_conc_param2;
          END IF;

          g_err_msg := 'Error Fetching Directory Path';
          select DIRECTORY_PATH
          into l_conc_param3
          from all_directories where directory_name = 'XXXMLPAYDATA';

         -- l_conc_param3 := '/u01/app/oracle/SITT/apps/apps_st/appl/xxintf/12.0.0/in/data/glbxmlpay';



          l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         (
                                         application      =>      'XXINTG'
                                        ,program          =>      'XXAPFUNDSDISB'
                                        ,description      =>      'INTG Funds Disbursement FTP Program'
                                        ,start_time       =>      SYSDATE
                                        ,sub_request      =>      NULL
                                        ,argument1        =>      l_conc_param1
                                        ,argument2        =>      l_conc_param2
                                        ,argument3        =>      l_conc_param3
                                        );
           COMMIT;

          ------Added EMF Log Message to insert data into EMF table ------
           xx_emf_pkg.error (
                        p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Global XML Payment Disbursement',
                        p_error_text               => 'Business Event Success',
                        p_record_identifier_1      => l_proc_name,
                        p_record_identifier_2      => l_param1,
                        p_record_identifier_3      => l_param2,
                        p_record_identifier_4      => l_req_id
                       );
          ------Added EMF Log Message end------

          RETURN ('SUCCESS');

      -- Added on 17-July-13 for R2R-INT-095 (Payment Instruction File) (start)
    ELSIF l_pay_prof = xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','PIF_PROCESS') THEN
          g_err_msg := 'Error Fetching Application Details (Payment Instruction File) ';

          select REQUESTED_BY,RESPONSIBILITY_APPLICATION_ID, RESPONSIBILITY_ID
          into L_REQUESTED_BY,L_RESPONSIBILITY_APPL_ID, L_RESPONSIBILITY_ID
          from fnd_concurrent_requests
          where request_id = l_param1;

          fnd_global.apps_initialize(L_REQUESTED_BY,L_RESPONSIBILITY_ID,L_RESPONSIBILITY_APPL_ID);

          g_err_msg := 'Error Fetching Request ID';
          l_conc_param1 := l_param1;

      g_err_msg := 'Error Fetching Directory Path';
          select DIRECTORY_PATH
          into l_conc_param2
          from all_directories where directory_name = 'XXPIFDATA';

          l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         (
                                         application      =>      'XXINTG'
                                        ,program          =>      'XXAPJPMCSUAPIF'
                                        ,description      =>      'Payment Instruction File FTP Program'
                                        ,start_time       =>      SYSDATE
                                        ,sub_request      =>      NULL
                                        ,argument1        =>      l_conc_param1
                                        ,argument2        =>      l_conc_param2
                                        );
           COMMIT;

          ------Added EMF Log Message to insert data into EMF table ------
           xx_emf_pkg.error (
                        p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Global XML Payment Disbursement',
                        p_error_text               => 'Business Event Success',
                        p_record_identifier_1      => l_proc_name,
                        p_record_identifier_2      => l_param1,
                        p_record_identifier_3      => l_param2,
                        p_record_identifier_4      => l_req_id
                       );
          ------Added EMF Log Message end------

          RETURN ('SUCCESS');
      -- Added on 17-July-13 for R2R-INT-095 (Payment Instruction File) (end)
      END IF;
          -- Added on 17-July-13 for R2R-INT-095 (Master Vendor List) (start)
    ELSIF l_proc_name = xx_emf_pkg.get_paramater_value ('XX_R2R_INT_045','CONC_PROG_NAME_MVL')
     THEN
          select REQUESTED_BY,RESPONSIBILITY_APPLICATION_ID, RESPONSIBILITY_ID
          into L_REQUESTED_BY,L_RESPONSIBILITY_APPL_ID, L_RESPONSIBILITY_ID
          from fnd_concurrent_requests
          where request_id = l_param1;

          fnd_global.apps_initialize(L_REQUESTED_BY,L_RESPONSIBILITY_ID,L_RESPONSIBILITY_APPL_ID);

          g_err_msg := 'Error Fetching Request ID';
          l_conc_param1 := l_param1;

          select DIRECTORY_PATH
          into l_conc_param2
          from all_directories where directory_name = 'XXMVLDATA';

         -- l_conc_param3 := '/u01/app/oracle/SITT/apps/apps_st/appl/xxintf/12.0.0/in/data/glbxmlpay';



          l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         (
                                         application      =>      'XXINTG'
                                        ,program          =>      'XXAPJPMCSUAMVLFTP'
                                        ,description      =>      'Master Vendor List FTP Program'
                                        ,start_time       =>      SYSDATE
                                        ,sub_request      =>      NULL
                                        ,argument1        =>      l_conc_param1
                                        ,argument2        =>      l_conc_param2
                                       );
           COMMIT;

          ------Added EMF Log Message to insert data into EMF table ------
           xx_emf_pkg.error (
                        p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Global XML Payment Disbursement',
                        p_error_text               => 'Business Event Success',
                        p_record_identifier_1      => l_proc_name,
                        p_record_identifier_2      => l_param1,
                        p_record_identifier_3      => l_param2,
                        p_record_identifier_4      => l_req_id
                       );
          ------Added EMF Log Message end------

          RETURN ('SUCCESS');
           -- Added on 17-July-13 for R2R-INT-095 (Master Vendor List) (end)
  END IF;

EXCEPTION
WHEN OTHERS THEN

    ------Added EMF Log Message to insert data into EMF table ------
    xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Global XML Payment Disbursement',
                p_error_text               => 'Business Event Failed',
                p_record_identifier_1      => l_proc_name,
                p_record_identifier_2      => g_err_msg,
                p_record_identifier_3      => l_param1,
                p_record_identifier_4      => l_param2
               );
    ------Added EMF Log Message end------

    RETURN('ERROR');

END XX_INTG_BEVENT_GXP;

END XX_INTG_BUSINESS_EVENT_PKG;
/
