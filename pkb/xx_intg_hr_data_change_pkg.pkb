DROP PACKAGE BODY APPS.XX_INTG_HR_DATA_CHANGE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_HR_DATA_CHANGE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Omkar Deshpande
 Creation Date : 27-Dec-2013
 File Name     : xx_intg_hr_data_change_pkg
 Description   : This code is being written to find out the HR Employee assignment changes

 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 27-Dec-2013 Omkar D             Initial Version
*/
----------------------------------------------------------------------

   -- Global Variable declarations-
   g_user_id          NUMBER       := fnd_global.user_id;
   g_login_id         NUMBER       := fnd_global.login_id;
   g_request_id       NUMBER       := fnd_global.conc_request_id;
   g_max_request_id   NUMBER       := NULL;
   g_debug_on         VARCHAR2 (1) := 'N';

/**************************************************************************
  Name      : debug_log
  Purpose   : This procedure writes messages in the Log file of the
              concurrent request
  Arguments :
***************************************************************************/
   PROCEDURE debug_log (p_text IN VARCHAR2)
   IS
   BEGIN
      IF g_debug_on = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_text);
      END IF;
   END debug_log;

/**************************************************************************
  Name      : archive_table
  Purpose   : This procedure archives the old data of staging table              
  Arguments :
***************************************************************************/
   
PROCEDURE archive_table(p_date  date)

IS
    BEGIN
        INSERT INTO xx_intg_hr_data_chgs_hist
           SELECT * from xx_intg_hr_data_changes
           where creation_date < p_date;
      
         DELETE FROM xx_intg_hr_data_changes
         where creation_date < p_date;
   END  archive_table;                

/**************************************************************************
  Name      : insert_staging_data
  Purpose   : This procedure inserts current run data in
              xx_intg_hr_data_changes table
  Arguments :
***************************************************************************/
   PROCEDURE insert_staging_data (
      p_request_id                 NUMBER,
      p_person_id                  NUMBER,
      p_employee_number            VARCHAR2,
      p_full_name                  VARCHAR2,
      p_position_id                NUMBER,
      p_position_name              VARCHAR2,
      p_organization_id            NUMBER,
      p_organization_name          VARCHAR2,
      p_cost_string                VARCHAR2,
      p_supervisor_id              NUMBER,
      p_supervisor_name            VARCHAR2,
      p_supervisor_position_id     VARCHAR2,
      p_supervisor_position_name   VARCHAR2,
      p_change_type                VARCHAR2,
      p_created_by                 NUMBER,
      p_creation_date              DATE,
      p_last_update_date           DATE,
      p_last_updated_by            NUMBER
   )
   IS
   BEGIN
      INSERT INTO xx_intg_hr_data_changes
                  (request_id, person_id, employee_number,
                   full_name, position_id, position_name,
                   organization_id, organization_name, cost_string,
                   supervisor_id, supervisor_name,
                   supervisor_position_id, supervisor_position_name,
                   change_type, created_by, creation_date,
                   last_update_date, last_updated_by
                  )
           VALUES (p_request_id, p_person_id, p_employee_number,
                   p_full_name, p_position_id, p_position_name,
                   p_organization_id, p_organization_name, p_cost_string,
                   p_supervisor_id, p_supervisor_name,
                   p_supervisor_position_id, p_supervisor_position_name,
                   p_change_type, p_created_by, p_creation_date,
                   p_last_update_date, p_last_updated_by
                  );
   END insert_staging_data;

/**************************************************************************
  Name      : process_data_changes
  Purpose   : 1) Retrievs the up to date data from database
              2) Compares the current data with the previous runs data
              3) Generated the file of changed data elements
***************************************************************************/
   PROCEDURE process_data_changes (p_filename IN VARCHAR2)
   IS
      CURSOR csr_emp_data
      IS
         SELECT papf.person_id, papf.employee_number, papf.full_name,
                hapf.position_id, hapf.NAME position_name,
                haou.organization_id, haou.NAME org_name,
                pcak.concatenated_segments, paaf.supervisor_id
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                hr_all_positions_f hapf,
                hr_all_organization_units haou,
                pay_cost_allocation_keyflex pcak
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND paaf.position_id = hapf.position_id
            AND paaf.organization_id = haou.organization_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND paaf.assignment_type IN ('E')
            AND ppos.period_of_service_id = (SELECT MAX(period_of_service_id) --For re-hires, select the latest period of service
                                   FROM per_periods_of_service ppos2
                                   WHERE ppos2.person_id = papf.person_id
                                   AND   date_start <= TRUNC(SYSDATE)
                                   )                                   
            AND NVL(ppos.actual_termination_date,TRUNC(SYSDATE)+1) > TRUNC(SYSDATE) 
            AND paaf.primary_flag = 'Y'
            AND NVL (papf.attribute5, 'X') <> 'N'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date
            UNION
             SELECT papf.person_id, papf.npw_number, papf.full_name,
                hapf.position_id, hapf.NAME position_name,
                haou.organization_id, haou.NAME org_name,
                pcak.concatenated_segments, paaf.supervisor_id
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppos,
                hr_all_positions_f hapf,
                hr_all_organization_units haou,
                pay_cost_allocation_keyflex pcak
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND paaf.position_id = hapf.position_id
            AND paaf.organization_id = haou.organization_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND paaf.assignment_type IN ('C')
            AND ppos.period_of_placement_id = (SELECT MAX(period_of_placement_id) --For re-hires, select the latest period of service
                                   FROM per_periods_of_placement ppos2
                                   WHERE ppos2.person_id = papf.person_id
                                   AND   date_start <= TRUNC(SYSDATE)
                                   )                                   
            AND NVL(ppos.actual_termination_date,TRUNC(SYSDATE)+1) > TRUNC(SYSDATE) 
            AND paaf.primary_flag = 'Y'
            AND NVL (papf.attribute5, 'X') <> 'N'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date;                                    

      CURSOR csr_supervisor_details (p_person_id IN NUMBER)
      IS
         SELECT papf.full_name supervisor_name,
                hapf.position_id supervisor_position_id,
                hapf.NAME supervisor_position_name
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                hr_all_positions_f hapf
          WHERE papf.person_id = paaf.person_id
            AND paaf.assignment_type IN ('E', 'C')
            AND papf.person_id = p_person_id
            AND paaf.position_id = hapf.position_id
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date;

      CURSOR csr_latest_data
      IS
         SELECT *
           FROM xx_intg_hr_data_changes
          WHERE request_id = g_request_id;

      CURSOR csr_previous_run_data (p_person_id NUMBER)
      IS
         SELECT DISTINCT person_id, organization_id, position_id,
                         supervisor_id, supervisor_name, organization_name,
                         position_name, supervisor_position_name
                    FROM xx_intg_hr_data_changes
                   WHERE request_id = NVL (g_max_request_id, g_request_id)
                     AND person_id = p_person_id;
                     
       CURSOR c_msg_recipients
    IS
    SELECT parameter_value email_id
      FROM xx_emf_process_setup ps,
           xx_emf_process_parameters pp
     WHERE ps.process_id = pp.process_id
       and PS.PROCESS_NAME = 'XXPERPOSNOTIF'
       AND pp.parameter_name = 'PO_ADMIN'; 

      
      l_supervisor_name            VARCHAR2 (400);
      l_supervisor_position_id     NUMBER;
      l_supervisor_position_name   VARCHAR2 (400);
      l_change_type                VARCHAR2 (10);
      l_changed_data               VARCHAR2 (4000);
      l_person_count               NUMBER;
      l_changed                    VARCHAR2 (1);
      l_file_handle                UTL_FILE.file_type;
      l_dir                        VARCHAR2 (50)      := 'XXHRLRN';
      l_field_chg_data_head        VARCHAR2 (4000);        -- added for header
      X_ERROR_MSG                  varchar2 (3000);
      L_BURST                      varchar2(1) := 'N';
      x_reqid                     NUMBER;
      X_SMTP_SERVER_NAME  varchar2(200);
      x_email_from       VARCHAR2(200);
      X_EMAIL_RECIPIENTS         varchar2(1000):=null;
      
   BEGIN
      BEGIN
         SELECT MAX (request_id)
          INTO g_max_request_id
           FROM xx_intg_hr_data_changes;
      EXCEPTION
         WHEN OTHERS
         THEN
            g_max_request_id := NULL;
      END;
      
      FOR r_msg_recipients IN c_msg_recipients
       LOOP      
           X_EMAIL_RECIPIENTS:= X_EMAIL_RECIPIENTS||R_MSG_RECIPIENTS.EMAIL_ID||',';
      END LOOP;
      
       --Query to fetch Email Server Name
       
        BEGIN
       
                 SELECT  parameter_value
                         into x_smtp_server_name
                              FROM fnd_svc_comp_param_vals pv
                                  ,fnd_svc_comp_params_b pb
                             WHERE pv.parameter_id = pb.parameter_id
                               AND parameter_name = 'OUTBOUND_SERVER';
                     
        EXCEPTION
                WHEN OTHERS THEN         
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Could not Fetch Email Server Details!');
        END;
        
        --Query to fetch 'Email From' Details
        
         BEGIN
       
                 SELECT parameter_value    
                        into x_email_from
                    FROM fnd_svc_comp_param_vals pv
                        ,fnd_svc_comp_params_b pb
                    WHERE pv.parameter_id = pb.parameter_id
                      AND parameter_name = 'REPLYTO';
                     
        EXCEPTION
                WHEN OTHERS THEN         
                FND_FILE.PUT_LINE(FND_FILE.log,'Could not Fetch Email From Details!');
        END;

      FOR rec_emp_data IN csr_emp_data
      LOOP
         l_supervisor_name := NULL;
         l_supervisor_position_id := NULL;
         l_supervisor_position_name := NULL;
         l_change_type := NULL;

         OPEN csr_supervisor_details (rec_emp_data.supervisor_id);

         FETCH csr_supervisor_details
          INTO l_supervisor_name, l_supervisor_position_id,
               l_supervisor_position_name;

         CLOSE csr_supervisor_details;
         
         l_person_count:=0;

         BEGIN
            SELECT COUNT (person_id)
              INTO l_person_count
              FROM xx_intg_hr_data_changes
             WHERE person_id = rec_emp_data.person_id
               AND request_id = g_max_request_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_person_count := 0;
         END;

         IF l_person_count > 0
         THEN
            l_change_type := 'UPDATE';
         ELSE
            l_change_type := 'NEW';
         END IF;
         
         debug_log('The Change Type for-'||rec_emp_data.person_id||' is -'||l_change_type); 

         insert_staging_data (g_request_id,
                              rec_emp_data.person_id,
                              rec_emp_data.employee_number,
                              rec_emp_data.full_name,
                              rec_emp_data.position_id,
                              rec_emp_data.position_name,
                              rec_emp_data.organization_id,
                              rec_emp_data.org_name,
                              rec_emp_data.concatenated_segments,
                              rec_emp_data.supervisor_id,
                              l_supervisor_name,
                              l_supervisor_position_id,
                              l_supervisor_position_name,
                              l_change_type,
                              g_user_id,
                              TRUNC (SYSDATE),
                              TRUNC (SYSDATE),
                              g_user_id
                             );
         COMMIT;
      END LOOP;

      IF g_max_request_id IS NOT NULL
      then
       /*  BEGIN
            l_file_handle := UTL_FILE.fopen (l_dir, p_filename, 'w');
         EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
               UTL_FILE.fclose (l_file_handle);
               fnd_file.put_line
                           (fnd_file.LOG,
                            'XXHRLRN Directory does not exist OR not visible'
                           );
               RAISE;
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose (l_file_handle);
               fnd_file.put_line (fnd_file.LOG, 'Write Error encountered');
               RAISE;
            WHEN OTHERS
            THEN
               UTL_FILE.fclose (l_file_handle);
               RAISE;
         END;*/

     /*    l_field_chg_data_head :=
               'Full_Name'
            || ','
            || 'Previous Position'
            || ','
            || 'Current Position'
            || ','
            || 'Previous Organization'
            || ','
            || 'Current Organization'
            || ','
            || 'Previous Supervisor'
            || ','
            || 'Current Supervisor'
            || ','
            || 'Change Type';
         UTL_FILE.put_line (l_file_handle, l_field_chg_data_head);*/
         
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '<?xml version="1.0"?>');
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '<PERDUMMY1>');

         FOR rec_latest_data IN csr_latest_data
         LOOP
            FOR rec_previous_run_data IN
               csr_previous_run_data (rec_latest_data.person_id)
            LOOP
               IF nvl(rec_previous_run_data.position_id,'XXXX') !=
                                                  nvl(rec_latest_data.position_id,'XXXX')
               THEN
                  l_changed := 'Y';
               ELSIF nvl(rec_previous_run_data.organization_id,'XXXX') !=
                                               nvl(rec_latest_data.organization_id,'XXXX')
               THEN
                  l_changed := 'Y';
               ELSIF nvl(rec_previous_run_data.supervisor_id,'XXXX')!=
                                                 nvl(rec_latest_data.supervisor_id,'XXXX')
               THEN
                  l_changed := 'Y';
               ELSE
                  l_changed := 'N';
               END IF;

               if L_CHANGED = 'Y' 
               then
               
               l_burst := 'Y';
            /*      l_changed_data := NULL;
                  l_changed_data :=
                        '"'||rec_latest_data.full_name||'"'
                     || ','||'"'
                     || rec_previous_run_data.position_name||'"'
                     || ','||'"'
                     || rec_latest_data.position_name||'"'
                     || ','||'"'
                     || rec_previous_run_data.organization_name||'"'
                     || ','||'"'
                     || rec_latest_data.organization_name||'"'
                     || ','||'"'
                     || rec_previous_run_data.supervisor_name||'"'
                     || ','||'"'
                     || rec_latest_data.supervisor_name||'"'
                     || ','||'"'
                     || rec_latest_data.change_type||'"';
                  --
                  UTL_FILE.put_line (l_file_handle, l_changed_data);*/
                  
           FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '<HRNOTF_REPORT>');
          
          FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<EMP_NUM>' || rec_latest_data.employee_number || '</EMP_NUM>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<POS_NAME>' || rec_latest_data.full_name || '</POS_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_POSIT>'||replace(rec_previous_run_data.position_name, '&', '&'||'amp;')||'</PRE_POSIT>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<POSIT_NAME>' ||replace(rec_latest_data.position_name, '&', '&'||'amp;') || '</POSIT_NAME>'); 
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_HR_ORG>' || replace(REC_PREVIOUS_RUN_DATA.ORGANIZATION_NAME, '&', '&'||'amp;') || '</PRE_HR_ORG>'); 
            FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<HR_ORG>' || replace(rec_latest_data.organization_name, '&', '&'||'amp;') || '</HR_ORG>');           
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<COST_STR>' || rec_latest_data.cost_string || '</COST_STR>'); 
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_SUP_NAME>' || rec_previous_run_data.supervisor_name || '</PRE_SUP_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<SUP_NAME>' || REC_LATEST_DATA.SUPERVISOR_NAME || '</SUP_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<SUP_POS>' || replace(REC_LATEST_DATA.SUPERVISOR_POSITION_NAME, '&', '&'||'amp;') || '</SUP_POS>');
          FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<CHG_STATUS>' ||  rec_latest_data.change_type || '</CHG_STATUS>');
          
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '</HRNOTF_REPORT>'); 
                  
               END IF;
            END LOOP;
            
            IF (rec_latest_data.change_type ='NEW') THEN
            
             l_burst := 'Y';
        /*    l_changed_data := NULL;
                  l_changed_data :=
                        '"'||rec_latest_data.full_name||'"'
                     || ','||'"'
                     || NULL||'"'
                     || ','||'"'
                     || rec_latest_data.position_name||'"'
                     || ','||'"'
                     || NULL||'"'
                     || ','||'"'
                     || rec_latest_data.organization_name||'"'
                     || ','||'"'
                     || NULL||'"'
                     || ','||'"'
                     || rec_latest_data.supervisor_name||'"'
                     || ','||'"'
                     || rec_latest_data.change_type||'"';
                  --
                  UTL_FILE.put_line (l_file_handle, l_changed_data);*/
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '<HRNOTF_REPORT>');
            
            FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<EMP_NUM>' || rec_latest_data.employee_number || '</EMP_NUM>');      
            FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<POS_NAME>' || rec_latest_data.full_name || '</POS_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_POSIT>'|| '' ||'</PRE_POSIT>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<POSIT_NAME>' || replace(rec_latest_data.position_name, '&', '&'||'amp;') || '</POSIT_NAME>'); 
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_HR_ORG>' || '' || '</PRE_HR_ORG>'); 
            FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<HR_ORG>' || replace(rec_latest_data.organization_name, '&', '&'||'amp;') || '</HR_ORG>'); 
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<COST_STR>' || rec_latest_data.cost_string || '</COST_STR>'); 
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PRE_SUP_NAME>' || '' || '</PRE_SUP_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<SUP_NAME>' || rec_latest_data.supervisor_name || '</SUP_NAME>');
           FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<SUP_POS>' || replace(REC_LATEST_DATA.SUPERVISOR_POSITION_NAME, '&', '&'||'amp;') || '</SUP_POS>');
          FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<CHG_STATUS>' ||  rec_latest_data.change_type || '</CHG_STATUS>');
           
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '</HRNOTF_REPORT>');
          
          END IF;   
            
            
         end LOOP;
         
         --Print Email Details in XML file
       
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '<PO_ADMIN_EMAIL>');
       
       FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<PO_EMAIL>' || x_email_recipients || '</PO_EMAIL>');
            
       FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<SERVER_NAME>' || x_smtp_server_name || '</SERVER_NAME>');
            
        FND_FILE.
          PUT_LINE (
            FND_FILE.OUTPUT,
            '<EMAIL_FROM>' || x_email_from || '</EMAIL_FROM>');
       
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '</PO_ADMIN_EMAIL>');
         
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '</PERDUMMY1>');

       /*  IF UTL_FILE.is_open (l_file_handle)
         THEN
            UTL_FILE.fclose (l_file_handle);
         END IF;*/
      end if;
      
       begin
          IF l_burst = 'Y' THEN
          x_reqid := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                                   'XDOBURSTREP',
                                                    NULL,
                                                    NULL,
                                                    FALSE,
                                                    'Y',
                                                    g_request_id,
                                                   'N'
                                                );  
          COMMIT;
          END IF;
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Bursting Failed!');
          END;
      
      
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_msg := 'Error in Procedure ->' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, x_error_msg);
   END process_data_changes;

/**************************************************************************
  Name      : main
  Purpose   : This procedure is the main procedure of this program
              Called from "INTG HR Assignment Data Changes"
              concurrent request.
              1) Derives the file name
              2) Calls Process_data_changes to creat the file of changed data elements              
***************************************************************************/ 

   PROCEDURE main (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2)
   IS
      l_file_name   VARCHAR2 (400);
      x_err_msg     VARCHAR2 (3000);
   BEGIN
      BEGIN
         SELECT 'HRDATACHANGE' || TO_CHAR (SYSDATE, 'MMDDYY') || '.csv'
           INTO l_file_name
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_file_name := 'HRDATACHANGE' || '.csv';
      END;

      process_data_changes (l_file_name);
      
      archive_table(trunc(sysdate));
   END;
END xx_intg_hr_data_change_pkg;
/
