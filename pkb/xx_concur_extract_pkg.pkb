DROP PACKAGE BODY APPS.XX_CONCUR_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CONCUR_EXTRACT_PKG"
IS
----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 07-JAN-2014
 File Name     : xx_concur_extract_pkg.pkb
 Description   : This script creates package body
                 APPS.xx_concur_extract_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 07-Jan-2014 Jaya Maran Jayaraj       Initial Version
 25-Jun-2014 Jaya Maran Jayaraj       Modified for Ticket#7923 to exclude Puerto Rico employees
 29-OCT-2014 Jaya Maran Jayaraj       Modified for Ticket#10700 to include Puerto Rico employees
 31-JUL-2015 Renganayaki (NTT DATA)   Modified to hard-code Paul Benny as Keith Valentine's expense approver
 31-MAR-2016 Renganayaki (NTT DATA)   Case#00010030 - Modified to exclude inactive company and Department in List Extract
*/
----------------------------------------------------------------------

   /* Procedure List_Extract
   ** Extract Company, Cost Center, Project, Project Task and Sub tasks, Product
   ** and Region information from Oracle Application to send to Concur Sytem as
   **  List extract outbound interface
   */
   PROCEDURE list_extract (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      /* Main Cursor to Get Company, Cost Center, Project, Project Task
         and Sub tasks, Productand region information*/
      CURSOR c_list_extract
      IS
         SELECT   arrange, list_name, list_category, level1, level2, level3,
                  level4, level5, level6, level7, level8, level9, level10,
                  VALUE, start_date, end_date, delete_flag
             FROM (SELECT DISTINCT 1 arrange,
                                      '"'
                                   || '*Company>Cost Center'
                                   || '"' list_name,
                                      '"'
                                   || '*Company>Cost Center'
                                   || '"' list_category,
                                   '"' || pcak.segment1 || '"' level1,
                                   '' level2, '' level3, '' level4, '' level5,
                                   '' level6, '' level7, '' level8, '' level9,
                                   '' level10,
                                   '"' || flv.description || '"' VALUE,
                                   '' start_date, '' end_date,
                                   '"' || 'N' || '"' delete_flag
                              FROM pay_cost_allocation_keyflex pcak,
                                   gl_ledgers gle,
                                   gl_ledger_norm_seg_vals gln,
                                   fnd_flex_values_vl flv,
                                   fnd_flex_value_sets fvs
                             WHERE gle.ledger_id = gln.ledger_id
                               AND pcak.segment1 = gln.segment_value
                               AND gle.NAME = 'LDGR US INTG'
                               AND fvs.flex_value_set_id =
                                                         flv.flex_value_set_id
                               AND flv.flex_value = pcak.segment1
                               AND fvs.flex_value_set_name = 'INTG_COMPANY'
                               AND NVL (flv.end_date_active, SYSDATE + 1) > SYSDATE --Added for Case#00010030
                   UNION
                   SELECT DISTINCT 2 arrange,
                                      '"'
                                   || '*Company>Cost Center'
                                   || '"' list_name,
                                      '"'
                                   || '*Company>Cost Center'
                                   || '"' list_category,
                                   '"' || pcak.segment1 || '"' level1,
                                   '"' || pcak.segment2 || '"' level2,
                                   '' level3, '' level4, '' level5, '' level6,
                                   '' level7, '' level8, '' level9,
                                   '' level10,
                                   '"' || flv.description || '"' VALUE,
                                   '' start_date, '' end_date,
                                   '"' || 'N' || '"' delete_flag
                              FROM pay_cost_allocation_keyflex pcak,
                                   gl_ledgers gle,
                                   gl_ledger_norm_seg_vals gln,
                                   fnd_flex_values_vl flv,
                                   fnd_flex_value_sets fvs
                             WHERE gle.ledger_id = gln.ledger_id
                               AND pcak.segment1 = gln.segment_value
                               AND gle.NAME = 'LDGR US INTG'
                               AND fvs.flex_value_set_id =
                                                         flv.flex_value_set_id
                               AND flv.flex_value = pcak.segment2
                               AND fvs.flex_value_set_name = 'INTG_DEPARTMENT'
                               AND NVL (flv.end_date_active, SYSDATE + 1) > SYSDATE --Added for Case#00010030
                   UNION
                   SELECT 3 arrange,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_name,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_category,
                          '"' || segment1 || '"' level1, '' level2, '' level3,
                          '' level4, '' level5, '' level6, '' level7,
                          '' level8, '' level9, '' level10,
                          '"' || NAME || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM pa_projects_all
                   UNION
                   SELECT 4 arrange,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_name,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_category,
                          '"' || pa.segment1 || '"' level1,
                          '"' || pt.task_number || '"' level2, '' level3,
                          '' level4, '' level5, '' level6, '' level7,
                          '' level8, '' level9, '' level10,
                          '"' || pt.task_name || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM pa_projects_all pa, pa_tasks pt
                    WHERE pa.project_id = pt.project_id
                      AND pt.task_id = pt.top_task_id
                   UNION
                   SELECT 5 arrange,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_name,
                             '"'
                          || '*Project>Project Task>Sub Task'
                          || '"' list_category,
                          '"' || pa.segment1 || '"' level1,
                          (SELECT '"' || task_number || '"'
                             FROM pa_tasks
                            WHERE task_id = pt.top_task_id) level2,
                          '"' || pt.task_number || '"' level3, '' level4,
                          '' level5, '' level6, '' level7, '' level8,
                          '' level9, '' level10,
                          '"' || pt.task_name || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM pa_projects_all pa, pa_tasks pt
                    WHERE pa.project_id = pt.project_id
                      AND pt.task_id != pt.top_task_id
                   UNION
                   SELECT 6 arrange,
                          '"' || '*Classification' || '"' list_name,
                          '"' || '*Classification' || '"' list_category,
                          '"' || '00000' || '"' level1, '' level2, '' level3,
                          '' level4, '' level5, '' level6, '' level7,
                          '' level8, '' level9, '' level10,
                          '"' || 'N/A' || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM DUAL
                   UNION
                   SELECT 7 arrange, '"' || '*Product' || '"' list_name,
                          '"' || '*Product' || '"' list_category,
                          '"' || ffvv.flex_value || '"' level1, '' level2,
                          '' level3, '' level4, '' level5, '' level6,
                          '' level7, '' level8, '' level9, '' level10,
                          '"' || ffvv.description || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                    WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvs.flex_value_set_name = 'INTG_PRODUCT'
                      AND ffvv.enabled_flag = 'Y'
                      AND NVL (ffvv.end_date_active, SYSDATE + 1) > SYSDATE
                   UNION
                   SELECT 8 arrange, '"' || '*Region' || '"' list_name,
                          '"' || '*Region' || '"' list_category,
                          '"' || ffvv.flex_value || '"' level1, '' level2,
                          '' level3, '' level4, '' level5, '' level6,
                          '' level7, '' level8, '' level9, '' level10,
                          '"' || ffvv.description || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                    WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvs.flex_value_set_name = 'INTG_REGION'
                      AND ffvv.enabled_flag = 'Y'
                      AND NVL (ffvv.end_date_active, SYSDATE + 1) > SYSDATE
                   UNION
                   SELECT 9 arrange, '"' || '*Intercompany' || '"' list_name,
                          '"' || '*Intercompany' || '"' list_category,
                          '"' || '000' || '"' level1, '' level2, '' level3,
                          '' level4, '' level5, '' level6, '' level7,
                          '' level8, '' level9, '' level10,
                          '"' || 'No Intercompany' || '"' VALUE,
                          '' start_date, '' end_date,
                          '"' || 'N' || '"' delete_flag
                     FROM DUAL
                   UNION
                   SELECT 10 arrange, '"' || '*Future' || '"' list_name,
                          '"' || '*Future' || '"' list_category,
                          '"' || '00000' || '"' level1, '' level2, '' level3,
                          '' level4, '' level5, '' level6, '' level7,
                          '' level8, '' level9, '' level10,
                          '"' || 'Future' || '"' VALUE, '' start_date,
                          '' end_date, '"' || 'N' || '"' delete_flag
                     FROM DUAL
                   UNION
                   SELECT DISTINCT 11 arrange,
                                   '"' || '*Division' || '"' list_name,
                                   '"' || '*Division' || '"' list_category,
                                      '"'
                                   || xx_concur_extract_pkg.division (NAME)
                                   || '"' level1,
                                   '' level2, '' level3, '' level4, '' level5,
                                   '' level6, '' level7, '' level8, '' level9,
                                   '' level10,
                                      '"'
                                   || xx_concur_extract_pkg.division (NAME)
                                   || '"' VALUE,
                                   '' start_date, '' end_date,
                                   '"' || 'N' || '"' delete_flag
                              FROM hr_all_organization_units_tl
                             WHERE LANGUAGE = 'US'
                               AND xx_concur_extract_pkg.division (NAME) IS NOT NULL
                   UNION
                   SELECT DISTINCT 12 arrange,
                                   '"' || '*Product-HCP' || '"' list_name,
                                   '"' || '*Product-HCP' || '"' list_category,
                                   '"' || meaning || '"' level1, '' level2,
                                   '' level3, '' level4, '' level5, '' level6,
                                   '' level7, '' level8, '' level9,
                                   '' level10,
                                   '"' || description || '"' VALUE,
                                   '' start_date, '' end_date,
                                   '"' || 'N' || '"' delete_flag
                              FROM fnd_lookup_values
                             WHERE LANGUAGE = 'US'
                               AND NVL (enabled_flag, 'N') = 'Y'
                               AND NVL (end_date_active, SYSDATE + 1) >
                                                                       SYSDATE
                               AND lookup_type = 'ITGR_HCP_PRODUCT_LIST_TYPE') t
         ORDER BY arrange;

      v_list_file_type   UTL_FILE.file_type;
      v_list_data_dir    VARCHAR2 (80);
      v_list_arc_dir     VARCHAR2 (80);
      v_list_data        VARCHAR2 (4000);
      v_user_name        VARCHAR2 (80);
      v_file_name        VARCHAR2 (80);
      v_prefix           VARCHAR2 (25);
      v_error_flag       VARCHAR2 (1)       := 'S';
      x_error_code       NUMBER;
   BEGIN
      /* Custom Initialization*/
      x_error_code := xx_emf_pkg.set_env;

      /* Get user Name for File Name*/
      BEGIN
         SELECT user_name
           INTO v_user_name
           FROM fnd_user
          WHERE user_id = fnd_global.user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_user_name := NULL;
            v_error_flag := 'E';
            retcode := xx_emf_cn_pkg.cn_prc_err;
            errbuf := 'Invalid User Id :' || fnd_global.user_id;
      END;

      /* Get Values for Data Directory, Archive Directory and File Prefix*/
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURLISTEXPORT',
                                       p_param_name        => 'DATA_DIR',
                                       x_param_value       => v_list_data_dir
                                      );
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURLISTEXPORT',
                                       p_param_name        => 'ARCH_DIR',
                                       x_param_value       => v_list_arc_dir
                                      );
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURLISTEXPORT',
                                       p_param_name        => 'FILE_PREFIX',
                                       x_param_value       => v_prefix
                                      );
      xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
      xx_emf_pkg.write_log
                       (xx_emf_cn_pkg.cn_low,
                        '----------- Concur List Extract File  --------------'
                       );
      xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Set EMF Env       -> ' || x_error_code
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'User Name         -> ' || v_user_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'File Directory    -> ' || v_list_data_dir
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Archive Directory -> ' || v_list_arc_dir
                           );

      /* File name*/
      IF v_error_flag != 'E'
      THEN
         v_file_name :=
               v_prefix
            || v_user_name
            || '_'
            || TO_CHAR (SYSDATE, 'RRRRMMDD_HH24MMSS')
            || '.txt';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'File Name         -> ' || v_file_name
                              );

         /* Open data File*/
         BEGIN
            v_list_file_type :=
               UTL_FILE.fopen_nchar (v_list_data_dir, v_file_name, 'W',
                                     32767);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'File Opened for writing.'
                                 );
         EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
               v_error_flag := 'E';
               retcode := xx_emf_cn_pkg.cn_prc_err;
               errbuf := 'Invalid Path for File Creation:' || v_list_data_dir;
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
               errbuf :=
                       'File could not be opened for writing:' || v_file_name;
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
            v_list_data := NULL;

            /* Get List details from Cursor and write into Data file*/
            FOR v_list_extract IN c_list_extract
            LOOP
               v_list_data := NULL;
               v_list_data :=
                     v_list_extract.list_name
                  || ','
                  || v_list_extract.list_category
                  || ','
                  || v_list_extract.level1
                  || ','
                  || v_list_extract.level2
                  || ','
                  || v_list_extract.level3
                  || ','
                  || v_list_extract.level4
                  || ','
                  || v_list_extract.level5
                  || ','
                  || v_list_extract.level6
                  || ','
                  || v_list_extract.level7
                  || ','
                  || v_list_extract.level8
                  || ','
                  || v_list_extract.level9
                  || ','
                  || v_list_extract.level10
                  || ','
                  || v_list_extract.VALUE
                  || ','
                  || v_list_extract.start_date
                  || ','
                  || v_list_extract.end_date
                  || ','
                  || v_list_extract.delete_flag;
               UTL_FILE.put_line_nchar (v_list_file_type, v_list_data);
               g_list_count := g_list_count +1;
            END LOOP;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'File Writing completed.'
                                 );

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Number of List Records: '||g_list_count
                                 );

            /* Close File*/
            IF UTL_FILE.is_open (v_list_file_type)
            THEN
               UTL_FILE.fclose (v_list_file_type);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Data File Closed.'
                                    );
            END IF;

            /* Archive File*/
            IF v_error_flag != 'E'
            THEN
               BEGIN
                  UTL_FILE.fcopy (v_list_data_dir,
                                  v_file_name,
                                  v_list_arc_dir,
                                  v_file_name
                                 );
                  xx_emf_pkg.write_log
                                     (xx_emf_cn_pkg.cn_low,
                                      'Data File Copied to Archive Directory.'
                                     );
               EXCEPTION
                  WHEN UTL_FILE.invalid_path
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf :=
                           'Invalid Path for File Copy:'
                        || v_list_data_dir
                        || ' - '
                        || v_list_arc_dir;
                  WHEN UTL_FILE.invalid_filename
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf := 'Invalid File Name:' || v_file_name;
                  WHEN OTHERS
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf := 'Error Moving file: ' || SQLERRM;
               END;

               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
            END IF;                                               -- file copy
         END IF;                                                  -- file open
      END IF;                                               -- user validation
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
   END list_extract;

/* Procedure Hr_Extract
** Extract active employee information to be sent to
** Concur system as a part of HR outbound interface
*/
   PROCEDURE hr_extract (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS                                               /* Cursor for 700 Record*/
      CURSOR c_700record
      IS
         SELECT NVL (papf.employee_number, papf.npw_number) employee_number,
                awsl.signing_limit
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                ap_web_signing_limits_all awsl,
                hr_locations_all hla
          WHERE papf.person_id = paaf.person_id
            AND paaf.location_id = hla.location_id
            AND ppos.person_id = papf.person_id
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            --AND hla.country = 'US'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) >
                                                               TRUNC (SYSDATE)
            AND assignment_type IN ('E')
            AND papf.person_id = awsl.employee_id
            AND paaf.primary_flag = 'Y'
            AND papf.employee_number IN (
                   SELECT (SELECT NVL (employee_number,
                                       npw_number)
                             FROM per_all_people_f
                            WHERE person_id = paaf.supervisor_id
                              AND SYSDATE BETWEEN effective_start_date
                                              AND effective_end_date)
                                                                   supervisor
                     FROM per_all_people_f papf,
                          per_all_assignments_f paaf,
                          per_periods_of_service ppos,
                          per_person_types ppt,
                          per_person_type_usages_f pptuf,
                          pay_cost_allocation_keyflex pcak,
                          hr_all_organization_units haou,
                          hr_locations_all hla
                    WHERE papf.person_id = paaf.person_id
                      AND papf.person_id = pptuf.person_id
                      AND ppos.person_id = papf.person_id
                      AND ppt.person_type_id = pptuf.person_type_id
                      AND haou.organization_id = paaf.organization_id
                      AND paaf.location_id = hla.location_id
                      AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
                      AND hla.country = 'US'
                      --AND NVL(hla.region_2,'QQ') <> 'PR' --Modified for Ticket#7923
                      AND ppos.period_of_service_id =
                             (SELECT MAX (period_of_service_id)
                                FROM per_periods_of_service ppos1
                               WHERE ppos1.person_id = papf.person_id
                                 AND date_start <= TRUNC (SYSDATE))
                      AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                              AND pptuf.effective_end_date
                      AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                              AND paaf.effective_end_date
                      AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                              AND papf.effective_end_date
                      AND NVL (ppos.actual_termination_date, SYSDATE + 1) >=
                                                               TRUNC (SYSDATE)
                      AND ppt.system_person_type IN ('EMP', 'EMP_APL')
                      AND paaf.assignment_type = 'E'
                      AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
                      AND paaf.primary_flag = 'Y'
                      AND (papf.person_id,
                           NVL (ppos.actual_termination_date,
                                TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                               )
                          ) NOT IN (SELECT employee_id, effective_end_date
                                      FROM xx_concur_hr_active_tbl xch
                                     WHERE active_flag = 'N')
                   UNION
                   SELECT (SELECT NVL (employee_number,
                                       npw_number)
                             FROM per_all_people_f
                            WHERE person_id = paaf.supervisor_id
                              AND SYSDATE BETWEEN effective_start_date
                                              AND effective_end_date)
                                                                   supervisor
                     FROM per_all_people_f papf,
                          per_all_assignments_f paaf,
                          per_periods_of_service ppos,
                          per_person_types ppt,
                          per_person_type_usages_f pptuf,
                          pay_cost_allocation_keyflex pcak,
                          hr_all_organization_units haou,
                          hr_locations_all hla,
                          xx_concur_hr_active_tbl xxch
                    WHERE papf.person_id = paaf.person_id
                      AND papf.person_id = pptuf.person_id
                      AND ppos.person_id = papf.person_id
                      AND ppt.person_type_id = pptuf.person_type_id
                      AND haou.organization_id = paaf.organization_id
                      AND paaf.location_id = hla.location_id
                      AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
                      AND xxch.employee_id = papf.person_id
                      AND NVL (xxch.employee_number, 'XYZ') =
                                                          papf.employee_number
                      AND xxch.active_flag = 'Y'
                      AND hla.country = 'US'
                      --AND NVL(hla.region_2,'QQ') <> 'PR' --Modified for Ticket#7923
                      AND ppos.period_of_service_id =
                             (SELECT MAX (period_of_service_id)
                                FROM per_periods_of_service ppos1
                               WHERE ppos1.person_id = papf.person_id
                                 AND date_start <= TRUNC (SYSDATE))
                      AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                  AND paaf.effective_end_date
                           OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                               AND paaf.effective_end_date =
                                      (SELECT MAX (asg.effective_end_date)
                                         FROM per_all_assignments_f asg
                                        WHERE asg.assignment_id =
                                                            paaf.assignment_id
                                          AND asg.period_of_service_id =
                                                     paaf.period_of_service_id
                                          AND asg.period_of_service_id =
                                                     ppos.period_of_service_id)
                              )
                          )
                      AND NVL (ppos.actual_termination_date, SYSDATE + 1) <
                                                               TRUNC (SYSDATE)
                      AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                              AND papf.effective_end_date
                      AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                              AND pptuf.effective_end_date
                      AND ppt.system_person_type IN ('EX_EMP')
                      AND paaf.assignment_type = 'E'
                      AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
                      AND paaf.primary_flag = 'Y');

/*         UNION
         SELECT NVL (papf.employee_number, papf.npw_number) employee_number,
                awsl.signing_limit
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppop,
                ap_web_signing_limits_all awsl,
                hr_locations_all hla
          WHERE papf.person_id = paaf.person_id
            AND paaf.location_id = hla.location_id
            AND ppop.person_id = papf.person_id
            AND ppop.period_of_placement_id =
                   (SELECT MAX (period_of_placement_id)
                      FROM per_periods_of_placement ppop1
                     WHERE ppop1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND hla.country = 'US'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND NVL (ppop.actual_termination_date, SYSDATE + 1) >
                                                               TRUNC (SYSDATE)
            AND assignment_type IN ('C')
            AND papf.person_id = awsl.employee_id
            AND paaf.primary_flag = 'Y';*/

      /* Cursor for 300 non US Record*/
      CURSOR c_300_record
      IS                                                  --Active supervisors
         SELECT '"' || papf.first_name || '"' first_name,
                '"' || papf.middle_names || '"' middle_names,
                '"' || papf.last_name || '"' last_name,
                papf.full_name full_name, papf.person_id,
                papf.employee_number,
                   '"'
                || xx_concur_extract_pkg.pay_group (papf.employee_number)
                || '"' expense_group,
                '"' || papf.email_address || '"' email_address,
                ppos.actual_termination_date effective_end_date,
                   '"'
                || xx_concur_extract_pkg.active_status
                                                 (papf.person_id,
                                                  ppos.actual_termination_date
                                                 )
                || '"' active_flag,
                '"' || '101' || '"' segment1,
                '"' || '1101' || '"' segment2,
                '"' || '00000' || '"' segment4,
                '"' || '500' || '"' segment5,
                '"' || '101' || '"' segment6,
                '"' || '000' || '"' segment7,
                '"' || '00000' || '"' segment8, NULL supervisor,
                '"' || 'Y' || '"' approver_flag,
                   '"'
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name,
                   '"integra_product_code='
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name1,
                '"' || hla.country || '"' country
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND hla.country <> 'US'
               --OR (hla.country = 'US'
                 -- AND hla.region_2 = 'PR')) --Modified for Ticket#7923
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) >=
                                                               TRUNC (SYSDATE)
            AND ppt.system_person_type IN ('EMP', 'EMP_APL')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y'
            AND (papf.person_id,
                 NVL (ppos.actual_termination_date,
                      TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                     )
                ) NOT IN (SELECT employee_id, effective_end_date
                            FROM xx_concur_hr_active_tbl xch
                           WHERE active_flag = 'N')
            AND send_supervisor (papf.person_id) = 'Y'
         UNION
         --Active supervisor in previous run
         SELECT '"' || papf.first_name || '"' first_name,
                '"' || papf.middle_names || '"' middle_names,
                '"' || papf.last_name || '"' last_name,
                papf.full_name full_name, papf.person_id,
                papf.employee_number,
                   '"'
                || xx_concur_extract_pkg.pay_group (papf.employee_number)
                || '"' expense_group,
                '"' || papf.email_address || '"' email_address,
                ppos.actual_termination_date effective_end_date,
                   '"'
                || xx_concur_extract_pkg.active_status
                                                 (papf.person_id,
                                                  ppos.actual_termination_date
                                                 )
                || '"' active_flag,
                '"' || pcak.segment1 || '"' segment1,
                '"' || pcak.segment2 || '"' segment2,
                '"' || pcak.segment4 || '"' segment4,
                '"' || pcak.segment5 || '"' segment5,
                '"' || pcak.segment6 || '"' segment6,
                '"' || pcak.segment7 || '"' segment7,
                '"' || pcak.segment8 || '"' segment8, NULL supervisor,
                '"' || 'Y' || '"' approver_flag,
                   '"'
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name,
                   '"integra_product_code='
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name1,
                '"' || hla.country || '"' country
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla,
                xx_concur_hr_active_tbl xxch
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND xxch.employee_id = papf.person_id
            AND NVL (xxch.employee_number, 'XYZ') = papf.employee_number
            AND xxch.active_flag = 'Y'
            AND hla.country <> 'US'
                --OR (hla.country = 'US'
                  --AND hla.region_2 = 'PR')) --Modified for Ticket#7923
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                        AND paaf.effective_end_date
                 OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                     AND paaf.effective_end_date =
                            (SELECT MAX (asg.effective_end_date)
                               FROM per_all_assignments_f asg
                              WHERE asg.assignment_id = paaf.assignment_id
                                AND asg.period_of_service_id =
                                                     paaf.period_of_service_id
                                AND asg.period_of_service_id =
                                                     ppos.period_of_service_id)
                    )
                )
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) <
                                                               TRUNC (SYSDATE)
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppt.system_person_type IN ('EX_EMP')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y'
            AND send_supervisor (papf.person_id) = 'Y';

      /*UNION
      --Active contingent worker supervisor
      SELECT '"' || papf.first_name || '"' first_name,
             '"' || papf.middle_names || '"' middle_names,
             '"' || papf.last_name || '"' last_name,
             papf.full_name full_name, papf.person_id,
             papf.npw_number employee_number,
             '"' || papf.email_address || '"' email_address,
             ppop.actual_termination_date effective_end_date,
                '"'
             || 'N'
             || '"' active_flag,
             '"' || pcak.segment1 || '"' segment1,
             '"' || pcak.segment2 || '"' segment2,
             '"' || pcak.segment4 || '"' segment4,
             '"' || pcak.segment5 || '"' segment5,
             '"' || pcak.segment6 || '"' segment6,
             '"' || pcak.segment7 || '"' segment7,
             '"' || pcak.segment8 || '"' segment8,
             NULL supervisor,
             '"'||'Y'|| '"'  approver_flag,
                '"'
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name,
                '"integra_product_code='
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name1,
             '"'||hla.country|| '"' country
        FROM per_all_people_f papf,
             per_all_assignments_f paaf,
             per_periods_of_placement ppop,
             per_person_types ppt,
             per_person_type_usages_f pptuf,
             pay_cost_allocation_keyflex pcak,
             hr_all_organization_units haou,
             hr_locations_all hla
       WHERE papf.person_id = paaf.person_id
         AND papf.person_id = pptuf.person_id
         AND ppop.person_id = papf.person_id
         AND ppt.person_type_id = pptuf.person_type_id
         AND haou.organization_id = paaf.organization_id
         AND paaf.location_id = hla.location_id
         AND ppop.period_of_placement_id =
                (SELECT MAX (period_of_placement_id)
                   FROM per_periods_of_placement ppop1
                  WHERE ppop1.person_id = papf.person_id
                    AND date_start <= TRUNC (SYSDATE))
         AND haou.cost_allocation_keyflex_id =
                                            pcak.cost_allocation_keyflex_id
         AND hla.country <> 'US'
         AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                 AND pptuf.effective_end_date
         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                 AND paaf.effective_end_date
         AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
         AND NVL (ppop.actual_termination_date, SYSDATE + 1) >=
                                                            TRUNC (SYSDATE)
         AND ppt.system_person_type IN ('CWK')
         AND paaf.assignment_type IN ('C')
         AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
         AND paaf.primary_flag = 'Y'
         AND (papf.person_id,
              NVL (ppop.actual_termination_date,
                   TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                  )
             ) NOT IN (SELECT employee_id, effective_end_date
                         FROM xx_concur_hr_active_tbl xch
                        WHERE active_flag = 'N')
         AND send_supervisor(papf.person_id,paaf.assignment_id) = 'Y';
      UNION
      --Active contingent worker supervisor in previous run
      SELECT '"' || papf.first_name || '"' first_name,
             '"' || papf.middle_names || '"' middle_names,
             '"' || papf.last_name || '"' last_name,
             papf.full_name full_name, papf.person_id,
             papf.npw_number employee_number,
             '"' || papf.email_address || '"' email_address,
             ppop.actual_termination_date effective_end_date,
                '"'
             || 'N'
             || '"' active_flag,
             '"' || pcak.segment1 || '"' segment1,
             '"' || pcak.segment2 || '"' segment2,
             '"' || pcak.segment4 || '"' segment4,
             '"' || pcak.segment5 || '"' segment5,
             '"' || pcak.segment6 || '"' segment6,
             '"' || pcak.segment7 || '"' segment7,
             '"' || pcak.segment8 || '"' segment8,
             (SELECT NVL (employee_number, npw_number)
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) supervisor,
             (SELECT    '"'
                     || DECODE (COUNT (1), 0, 'N', 'Y')
                     || '"'
                FROM per_all_assignments_f
               WHERE supervisor_id = papf.person_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) approver_flag,
                '"'
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name,
                '"integra_product_code='
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name1,
             '"'||hla.country|| '"' country
        FROM per_all_people_f papf,
             per_all_assignments_f paaf,
             per_periods_of_placement ppop,
             per_person_types ppt,
             per_person_type_usages_f pptuf,
             pay_cost_allocation_keyflex pcak,
             hr_all_organization_units haou,
             hr_locations_all hla,
             xx_concur_hr_active_tbl xxch
       WHERE papf.person_id = paaf.person_id
         AND papf.person_id = pptuf.person_id
         AND ppop.person_id = papf.person_id
         AND ppt.person_type_id = pptuf.person_type_id
         AND haou.organization_id = paaf.organization_id
         AND paaf.location_id = hla.location_id
         AND ppop.period_of_placement_id =
                (SELECT MAX (period_of_placement_id)
                   FROM per_periods_of_placement ppop1
                  WHERE ppop1.person_id = papf.person_id
                    AND date_start <= TRUNC (SYSDATE))
         AND haou.cost_allocation_keyflex_id =
                                            pcak.cost_allocation_keyflex_id
         AND hla.country <> 'US'
         AND xxch.employee_id = papf.person_id
         AND NVL (xxch.employee_number, 'XYZ') = papf.npw_number
         AND xxch.active_flag = 'Y'
         AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
         AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                     AND paaf.effective_end_date
              OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                  AND paaf.effective_end_date =
                         (SELECT MAX (asg.effective_end_date)
                            FROM per_all_assignments_f asg
                           WHERE asg.assignment_id = paaf.assignment_id
                             AND asg.person_id = papf.person_id)
                 )
             )
         AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                 AND pptuf.effective_end_date
         AND NVL (ppop.actual_termination_date, SYSDATE + 1) <
                                                            TRUNC (SYSDATE)
         AND ppt.system_person_type IN ('EX_CWK')
         AND paaf.assignment_type IN ('C')
         AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
         AND paaf.primary_flag = 'Y'
         AND send_supervisor(papf.person_id,paaf.assignment_id) = 'Y';*/

      /* Cursor for 300 and 350 Record*/
      CURSOR c_300_350_record
      IS                                                    --Active employees
         SELECT '"' || papf.first_name || '"' first_name,
                '"' || papf.middle_names || '"' middle_names,
                '"' || papf.last_name || '"' last_name,
                papf.full_name full_name, papf.person_id,
                papf.employee_number,
                   '"'
                || xx_concur_extract_pkg.pay_group (papf.employee_number)
                || '"' expense_group,
                '"' || papf.email_address || '"' email_address,
                ppos.actual_termination_date effective_end_date,
                   '"'
                || xx_concur_extract_pkg.active_status
                                                 (papf.person_id,
                                                  ppos.actual_termination_date
                                                 )
                || '"' active_flag,
                '"' || pcak.segment1 || '"' segment1,
                '"' || pcak.segment2 || '"' segment2,
                '"' || pcak.segment4 || '"' segment4,
                '"' || pcak.segment5 || '"' segment5,
                '"' || pcak.segment6 || '"' segment6,
                '"' || pcak.segment7 || '"' segment7,
                '"' || pcak.segment8 || '"' segment8,
                (SELECT NVL (employee_number, npw_number)
                   FROM per_all_people_f
                  WHERE person_id = paaf.supervisor_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date) supervisor,
                (SELECT    '"'
                        || DECODE (COUNT (1), 0, 'N', 'Y')
                        || '"'
                   FROM per_all_assignments_f
                  WHERE supervisor_id = papf.person_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date) approver_flag,
                   '"'
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name,
                   '"integra_product_code='
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name1
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND hla.country = 'US'
            --AND NVL(hla.region_2,'QQ') <> 'PR' --Modified for Ticket#7923
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) >=
                                                               TRUNC (SYSDATE)
            AND ppt.system_person_type IN ('EMP', 'EMP_APL')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y'
            AND (papf.person_id,
                 NVL (ppos.actual_termination_date,
                      TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                     )
                ) NOT IN (SELECT employee_id, effective_end_date
                            FROM xx_concur_hr_active_tbl xch
                           WHERE active_flag = 'N')
         UNION
         --Active employees in previous run
         SELECT '"' || papf.first_name || '"' first_name,
                '"' || papf.middle_names || '"' middle_names,
                '"' || papf.last_name || '"' last_name,
                papf.full_name full_name, papf.person_id,
                papf.employee_number,
                   '"'
                || xx_concur_extract_pkg.pay_group (papf.employee_number)
                || '"' expense_group,
                '"' || papf.email_address || '"' email_address,
                ppos.actual_termination_date effective_end_date,
                   '"'
                || xx_concur_extract_pkg.active_status
                                                 (papf.person_id,
                                                  ppos.actual_termination_date
                                                 )
                || '"' active_flag,
                '"' || pcak.segment1 || '"' segment1,
                '"' || pcak.segment2 || '"' segment2,
                '"' || pcak.segment4 || '"' segment4,
                '"' || pcak.segment5 || '"' segment5,
                '"' || pcak.segment6 || '"' segment6,
                '"' || pcak.segment7 || '"' segment7,
                '"' || pcak.segment8 || '"' segment8,
                (SELECT NVL (employee_number, npw_number)
                   FROM per_all_people_f
                  WHERE person_id = paaf.supervisor_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date) supervisor,
                (SELECT    '"'
                        || DECODE (COUNT (1), 0, 'N', 'Y')
                        || '"'
                   FROM per_all_assignments_f
                  WHERE supervisor_id = papf.person_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date) approver_flag,
                   '"'
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name,
                   '"integra_product_code='
                || xx_concur_extract_pkg.division_name (paaf.organization_id)
                || '"' division_name1
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla,
                xx_concur_hr_active_tbl xxch
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND xxch.employee_id = papf.person_id
            AND NVL (xxch.employee_number, 'XYZ') = papf.employee_number
            AND xxch.active_flag = 'Y'
            AND hla.country = 'US'
            --AND NVL(hla.region_2,'QQ') <> 'PR' --Modified for Ticket#7923
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                        AND paaf.effective_end_date
                 OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                     AND paaf.effective_end_date =
                            (SELECT MAX (asg.effective_end_date)
                               FROM per_all_assignments_f asg
                              WHERE asg.assignment_id = paaf.assignment_id
                                AND asg.period_of_service_id =
                                                     paaf.period_of_service_id
                                AND asg.period_of_service_id =
                                                     ppos.period_of_service_id)
                    )
                )
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) <
                                                               TRUNC (SYSDATE)
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppt.system_person_type IN ('EX_EMP')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y';

      /*UNION
      --Active contingent workers
      SELECT '"' || papf.first_name || '"' first_name,
             '"' || papf.middle_names || '"' middle_names,
             '"' || papf.last_name || '"' last_name,
             papf.full_name full_name, papf.person_id,
             papf.npw_number employee_number,
             '"'
             ||xx_concur_extract_pkg.pay_group(papf.npw_number)
             || '"' expense_group,
             '"' || papf.email_address || '"' email_address,
             ppop.actual_termination_date effective_end_date,
             '"' || 'N' || '"' active_flag,
             '"' || pcak.segment1 || '"' segment1,
             '"' || pcak.segment2 || '"' segment2,
             '"' || pcak.segment4 || '"' segment4,
             '"' || pcak.segment5 || '"' segment5,
             '"' || pcak.segment6 || '"' segment6,
             '"' || pcak.segment7 || '"' segment7,
             '"' || pcak.segment8 || '"' segment8,
             (SELECT NVL (employee_number, npw_number)
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) supervisor,
             (SELECT    '"'
                     || DECODE (COUNT (1), 0, 'N', 'Y')
                     || '"'
                FROM per_all_assignments_f
               WHERE supervisor_id = papf.person_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) approver_flag,
                '"'
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name,
                '"integra_product_code='
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name1
        FROM per_all_people_f papf,
             per_all_assignments_f paaf,
             per_periods_of_placement ppop,
             per_person_types ppt,
             per_person_type_usages_f pptuf,
             pay_cost_allocation_keyflex pcak,
             hr_all_organization_units haou,
             hr_locations_all hla
       WHERE papf.person_id = paaf.person_id
         AND papf.person_id = pptuf.person_id
         AND ppop.person_id = papf.person_id
         AND ppt.person_type_id = pptuf.person_type_id
         AND haou.organization_id = paaf.organization_id
         AND paaf.location_id = hla.location_id
         AND ppop.period_of_placement_id =
                (SELECT MAX (period_of_placement_id)
                   FROM per_periods_of_placement ppop1
                  WHERE ppop1.person_id = papf.person_id
                    AND date_start <= TRUNC (SYSDATE))
         AND haou.cost_allocation_keyflex_id =
                                            pcak.cost_allocation_keyflex_id
         AND hla.country = 'US'
         AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                 AND pptuf.effective_end_date
         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                 AND paaf.effective_end_date
         AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
         AND NVL (ppop.actual_termination_date, SYSDATE + 1) >=
                                                            TRUNC (SYSDATE)
         AND ppt.system_person_type IN ('CWK')
         AND paaf.assignment_type IN ('C')
         AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
         AND paaf.primary_flag = 'Y'
         AND (    papf.email_address IS NOT NULL
              AND LOWER (papf.email_address) LIKE '%integralife.com'
             )
         AND (papf.person_id,
              NVL (ppop.actual_termination_date,
                   TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                  )
             ) NOT IN (SELECT employee_id, effective_end_date
                         FROM xx_concur_hr_active_tbl xch
                        WHERE active_flag = 'N')
      UNION
      --Active contingent workers in previous run
      SELECT '"' || papf.first_name || '"' first_name,
             '"' || papf.middle_names || '"' middle_names,
             '"' || papf.last_name || '"' last_name,
             papf.full_name full_name, papf.person_id,
             papf.npw_number employee_number,
             '"'
             ||xx_concur_extract_pkg.pay_group(papf.npw_number)
             || '"' expense_group,
             '"' || papf.email_address || '"' email_address,
             ppop.actual_termination_date effective_end_date,
             '"' || 'N' || '"' active_flag,
             '"' || pcak.segment1 || '"' segment1,
             '"' || pcak.segment2 || '"' segment2,
             '"' || pcak.segment4 || '"' segment4,
             '"' || pcak.segment5 || '"' segment5,
             '"' || pcak.segment6 || '"' segment6,
             '"' || pcak.segment7 || '"' segment7,
             '"' || pcak.segment8 || '"' segment8,
             (SELECT NVL (employee_number, npw_number)
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) supervisor,
             (SELECT    '"'
                     || DECODE (COUNT (1), 0, 'N', 'Y')
                     || '"'
                FROM per_all_assignments_f
               WHERE supervisor_id = papf.person_id
                 AND SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date) approver_flag,
                '"'
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name,
                '"integra_product_code='
             || xx_concur_extract_pkg.division_name (paaf.organization_id)
             || '"' division_name1
        FROM per_all_people_f papf,
             per_all_assignments_f paaf,
             per_periods_of_placement ppop,
             per_person_types ppt,
             per_person_type_usages_f pptuf,
             pay_cost_allocation_keyflex pcak,
             hr_all_organization_units haou,
             hr_locations_all hla,
             xx_concur_hr_active_tbl xxch
       WHERE papf.person_id = paaf.person_id
         AND papf.person_id = pptuf.person_id
         AND ppop.person_id = papf.person_id
         AND ppt.person_type_id = pptuf.person_type_id
         AND haou.organization_id = paaf.organization_id
         AND paaf.location_id = hla.location_id
         AND ppop.period_of_placement_id =
                (SELECT MAX (period_of_placement_id)
                   FROM per_periods_of_placement ppop1
                  WHERE ppop1.person_id = papf.person_id
                    AND date_start <= TRUNC (SYSDATE))
         AND haou.cost_allocation_keyflex_id =
                                            pcak.cost_allocation_keyflex_id
         AND hla.country = 'US'
         AND xxch.employee_id = papf.person_id
         AND NVL (xxch.employee_number, 'XYZ') = papf.npw_number
         AND xxch.active_flag = 'Y'
         AND (    papf.email_address IS NOT NULL
              AND LOWER (papf.email_address) LIKE '%integralife.com'
             )
         AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
         AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                     AND paaf.effective_end_date
              OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                  AND paaf.effective_end_date =
                         (SELECT MAX (asg.effective_end_date)
                            FROM per_all_assignments_f asg
                           WHERE asg.assignment_id = paaf.assignment_id
                             AND asg.person_id = papf.person_id)
                 )
             )
         AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                 AND pptuf.effective_end_date
         AND NVL (ppop.actual_termination_date, SYSDATE + 1) <
                                                            TRUNC (SYSDATE)
         AND ppt.system_person_type IN ('EX_CWK')
         AND paaf.assignment_type IN ('C')
         AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
         AND paaf.primary_flag = 'Y';*/
      CURSOR c_email
      IS
         SELECT employee_number, full_name
           FROM xx_concur_hr_email_tbl;

      v_hr_file_type    UTL_FILE.file_type;
      v_hr_data_dir     VARCHAR2 (80);
      v_hr_arc_dir      VARCHAR2 (80);
      v_hr_100data      VARCHAR2 (4000);
      v_hr_300data      VARCHAR2 (10000);
      v_hr_350data      VARCHAR2 (10000);
      v_hr_700data      VARCHAR2 (4000);
      v_user_name       VARCHAR2 (80);
      v_file_name       VARCHAR2 (80);
      v_prefix          VARCHAR2 (40);
      v_error_flag      VARCHAR2 (1)       := 'S';
      v_insert          NUMBER;
      v_email_flag      VARCHAR2 (1)       := 'N';
      v_from_email      VARCHAR2 (100);
      v_to_email        VARCHAR2 (100);
      v_message         VARCHAR2 (500);
      v_subject         VARCHAR2 (500);
      v_hr_login_type   UTL_FILE.file_type;
      v_hr_login_dir    VARCHAR2 (80);
      v_login_file      VARCHAR2 (80);
      v_login_data      VARCHAR2 (500);
      x_error_code      NUMBER;
      v_bcc_name        VARCHAR2 (60);
      v_cc_name         VARCHAR2 (60);
      v_login_header    VARCHAR2 (60)      := 'Emp No.    Employee Name';
      v_supervisor      VARCHAR2 (20);
   BEGIN
      /*custom Initialization*/
      x_error_code := xx_emf_pkg.set_env;

      DELETE FROM xx_concur_hr_email_tbl;

      /*Get user name for file name*/
      BEGIN
         SELECT user_name
           INTO v_user_name
           FROM fnd_user
          WHERE user_id = fnd_global.user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_user_name := NULL;
            v_error_flag := 'E';
            retcode := xx_emf_cn_pkg.cn_prc_err;
            errbuf := 'Invalid User Id :' || fnd_global.user_id;
      END;

      /*Get Values for Data directory, Archive directory and File prefix*/
      xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'DATA_DIR',
                                         x_param_value       => v_hr_data_dir
                                        );
      xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'ARCH_DIR',
                                         x_param_value       => v_hr_arc_dir
                                        );
      xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'FILE_PREFIX',
                                         x_param_value       => v_prefix
                                        );
      xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
      xx_emf_pkg.write_log
                       (xx_emf_cn_pkg.cn_low,
                        '------------ Concur HR Extract File ----------------'
                       );
      xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Set EMF Env       -> ' || x_error_code
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'User Name         -> ' || v_user_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'File Directory    -> ' || v_hr_data_dir
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Archive Directory -> ' || v_hr_arc_dir
                           );

      IF v_error_flag != 'E'
      THEN
         v_file_name :=
               v_prefix
            || v_user_name
            || '_'
            || TO_CHAR (SYSDATE, 'RRRRMMDD_HH24MMSS')
            || '.txt';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'File Name         -> ' || v_file_name
                              );

         /* Open File*/
         BEGIN
            v_hr_file_type :=
                 UTL_FILE.fopen_nchar (v_hr_data_dir, v_file_name, 'W', 6400);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'File Opened for writing.'
                                 );
         EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
               v_error_flag := 'E';
               retcode := xx_emf_cn_pkg.cn_prc_err;
               errbuf := 'Invalid Path for File Creation:' || v_hr_data_dir;
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
               errbuf :=
                       'File could not be opened for writing:' || v_file_name;
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

         /* Write 100 Record File*/
         IF v_error_flag != 'E'
         THEN
            v_hr_100data :=
                  '100'
               || ','
               || '0'
               || ','
               || '"welcome"'
               || ','
               || '"UPDATE"'
               || ','
               || '"EN"'
               || ','
               || '"N"'
               || ','
               || '"N"';
            g_hr_count := g_hr_count+1;
            UTL_FILE.put_line_nchar (v_hr_file_type, v_hr_100data);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '100 Record Entered into File.'
                                 );

            /* Write 300 Record File*/
            FOR v_300record IN c_300_record
            LOOP
               v_insert := 0;
               v_hr_300data := NULL;

               IF     REPLACE (v_300record.email_address, '"', '') IS NOT NULL
                  AND UPPER (REPLACE (v_300record.email_address, '"', '')) LIKE
                                                            '%SEASPINE.COM'
               THEN
                  v_hr_300data :=
                        '300'
                     || ','
                     || v_300record.first_name
                     || ','
                     || v_300record.middle_names
                     || ','
                     || v_300record.last_name
                     || ','
                     || v_300record.employee_number
                     || ','
                     || REPLACE (v_300record.email_address, '''')
                     || ','
                     || '"welcome"'
                     || ','
                     || v_300record.email_address
                     || ','
                     || '"en_US"'
                     || ','
                     || v_300record.country
                     || ','
                     || NULL
                     || ','
                     || '"LDGR US INTG"'
                     || ','
                     || '"USD"'
                     || ','
                     || NULL
                     || ','
                     || v_300record.active_flag
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_300record.segment1
                     || ','
                     || v_300record.segment2
                     || ','
                     || v_300record.segment4
                     || ','
                     || v_300record.segment5
                     || ','
                     || v_300record.segment6
                     || ','
                     || v_300record.segment7
                     || ','
                     || v_300record.segment8
                     || ','
                     || v_300record.division_name
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_300record.expense_group
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_300record.supervisor
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL                 --v_300record.supervisor column62
                     || ','
                     || '"N"'                                   --expense user
                     || ','
                     || v_300record.approver_flag
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || '"ALW"'
                     || ','
                     || v_300record.supervisor
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || '"Y"'
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL;
                  UTL_FILE.put_line_nchar (v_hr_file_type, v_hr_300data);
                  g_hr_count := g_hr_count+1;
               ELSIF    REPLACE (v_300record.email_address, '"', '') IS NULL
                     OR UPPER (REPLACE (v_300record.email_address, '"', '')) NOT LIKE
                                                           '%SEASPINE.COM%'
               THEN
                  INSERT INTO xx_concur_hr_email_tbl
                       VALUES (v_300record.full_name,
                               v_300record.employee_number);

                  v_email_flag := 'Y';
               END IF;
            END LOOP;

            /* Write 300 Record File*/
            FOR v_300record IN c_300_350_record
            LOOP
               v_insert := 0;
               v_hr_300data := NULL;

               IF REPLACE (v_300record.supervisor, '"', '') = '22'
               THEN
                  BEGIN
                     SELECT '"' || global_value || '"'
                       INTO v_supervisor
                       FROM ff_globals_f
                      WHERE GLOBAL_NAME = 'INTG_BOD_ALT_APPROVER';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_supervisor := v_300record.supervisor;
                  END;
               ELSE
                  v_supervisor := v_300record.supervisor;
               END IF;

               --Change start for case#00004423
               IF v_300record.employee_number = '127394' THEN

                  BEGIN
                     SELECT NVL (employee_number, npw_number)
                       INTO v_supervisor
                       FROM per_all_people_f
                      WHERE person_id = 520
                        AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_supervisor := v_300record.supervisor;
                  END;

               END IF;

               DBMS_OUTPUT.PUT_LINE('v_supervisor : ' ||v_supervisor);
               --Change end for case#00004423

               IF     REPLACE (v_300record.email_address, '"', '') IS NOT NULL
                  AND UPPER (REPLACE (v_300record.email_address, '"', '')) LIKE
                                                            '%SEASPINE.COM'
               THEN
                  v_hr_300data :=
                        '300'
                     || ','
                     || v_300record.first_name
                     || ','
                     || v_300record.middle_names
                     || ','
                     || v_300record.last_name
                     || ','
                     || v_300record.employee_number
                     || ','
                     || REPLACE (v_300record.email_address, '''')
                     || ','
                     || '"welcome"'
                     || ','
                     || v_300record.email_address
                     || ','
                     || '"en_US"'
                     || ','
                     || '"US"'
                     || ','
                     || NULL
                     || ','
                     || '"LDGR US INTG"'
                     || ','
                     || '"USD"'
                     || ','
                     || NULL
                     || ','
                     || v_300record.active_flag
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_300record.segment1
                     || ','
                     || v_300record.segment2
                     || ','
                     || v_300record.segment4
                     || ','
                     || v_300record.segment5
                     || ','
                     || v_300record.segment6
                     || ','
                     || v_300record.segment7
                     || ','
                     || v_300record.segment8
                     || ','
                     || v_300record.division_name
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_300record.expense_group
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_supervisor
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL                 --v_300record.supervisor column62
                     || ','
                     || '"Y"'
                     || ','
                     || v_300record.approver_flag
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || '"ALW"'
                     || ','
                     || v_supervisor
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || '"Y"'
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL;
                  UTL_FILE.put_line_nchar (v_hr_file_type, v_hr_300data);
                  g_hr_count := g_hr_count+1;
               ELSIF    REPLACE (v_300record.email_address, '"', '') IS NULL
                     OR UPPER (REPLACE (v_300record.email_address, '"', '')) NOT LIKE
                                                           '%SEASPINE.COM%'
               THEN
                  INSERT INTO xx_concur_hr_email_tbl
                       VALUES (v_300record.full_name,
                               v_300record.employee_number);

                  v_email_flag := 'Y';
               END IF;
            END LOOP;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '300 Record Entered into File.'
                                 );

            /* Write 350 Record File*/
            FOR v_350record IN c_300_350_record
            LOOP
               v_insert := 0;
               v_hr_350data := NULL;

               BEGIN
                  SELECT COUNT (1)
                    INTO v_insert
                    FROM xx_concur_hr_active_tbl
                   WHERE employee_id = v_350record.person_id;
               END;

               IF     REPLACE (v_350record.email_address, '"', '') IS NOT NULL
                  AND UPPER (REPLACE (v_350record.email_address, '"', '')) LIKE
                                                            '%SEASPINE.COM'
               THEN
                  v_hr_350data :=
                        '350'
                     || ','
                     || v_350record.employee_number
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || '"Default Travel Class"'
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || v_350record.division_name1
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL
                     || ','
                     || NULL;
                  UTL_FILE.put_line_nchar (v_hr_file_type, v_hr_350data);
                  g_hr_count := g_hr_count+1;

                  IF        --REPLACE (v_350record.active_flag, '"', '') = 'Y'
                     --AND
                     v_insert = 0
                  THEN
                     INSERT INTO xx_concur_hr_active_tbl
                          VALUES (v_350record.person_id,
                                  v_350record.employee_number,
                                  v_350record.effective_end_date,
                                  REPLACE (v_350record.active_flag, '"', ''),
                                  fnd_global.conc_request_id);
                  ELSE
                     UPDATE xx_concur_hr_active_tbl
                        SET effective_end_date =
                                                v_350record.effective_end_date,
                            active_flag =
                                    REPLACE (v_350record.active_flag, '"', ''),
                            request_id = fnd_global.conc_request_id
                      WHERE employee_id = v_350record.person_id;
                  END IF;
               END IF;
            END LOOP;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '350 Record Entered into File.'
                                 );

            /* Write 700 Record File*/
            FOR v_700record IN c_700record
            LOOP
               v_hr_700data := NULL;
               v_hr_700data :=
                     '700'
                  || ','
                  || '"EXP"'
                  || ','
                  || v_700record.employee_number
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || NULL
                  || ','
                  || v_700record.signing_limit
                  || ','
                  || '"USD"';
               UTL_FILE.put_line_nchar (v_hr_file_type, v_hr_700data);
               g_hr_count := g_hr_count+1;
            END LOOP;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '700 Record Entered into File.'
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'HR Records in File(Including Header): '||g_hr_count
                                 );

            IF UTL_FILE.is_open (v_hr_file_type)
            THEN
               UTL_FILE.fclose (v_hr_file_type);
            END IF;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Data File Closed.');

            /* Send Email for records with Email id*/
            IF v_email_flag = 'Y'
            THEN
               --UTL_FILE.fremove (v_hr_login_dir, v_login_file);
               xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURHREXPORT',
                                        p_param_name        => 'EMAIL_DIR',
                                        x_param_value       => v_hr_login_dir
                                       );
               xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'EMAIL_FILENAME',
                                         x_param_value       => v_login_file
                                        );
               xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'EMAIL_SUBJECT',
                                         x_param_value       => v_subject
                                        );
               xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'EMAIL_MESSAGE',
                                         x_param_value       => v_message
                                        );
               xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'FROM_EMAIL',
                                         x_param_value       => v_from_email
                                        );
               xx_intg_common_pkg.get_process_param_value
                                        (p_process_name      => 'XXCONCURHREXPORT',
                                         p_param_name        => 'TO_EMAIL',
                                         x_param_value       => v_to_email
                                        );
               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '--------  Concur HR Extract Mailing Bad File   --------'
                    );
               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Mail From         -> ' || v_from_email
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Mail To           -> ' || v_to_email
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Subject           -> ' || v_subject
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Message           -> ' || v_message
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'File Directory    -> ' || v_hr_login_dir
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'File Name         -> ' || v_login_file
                                    );
               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
               v_hr_login_type :=
                  UTL_FILE.fopen_nchar (v_hr_login_dir,
                                        v_login_file,
                                        'W',
                                        6400
                                       );
               UTL_FILE.put_line_nchar (v_hr_login_type, v_login_header);

               FOR v_email IN c_email
               LOOP
                  v_login_data := NULL;
                  v_login_data :=
                        v_email.employee_number
                     || RPAD (' ', (6 - LENGTH (v_email.employee_number)))
                     || RPAD (' ', 5)
                     || v_email.full_name;
                  UTL_FILE.put_line_nchar (v_hr_login_type, v_login_data);
               END LOOP;

               IF UTL_FILE.is_open (v_hr_login_type)
               THEN
               UTL_FILE.fclose (v_hr_login_type);
               END IF;

               v_bcc_name := '';
               v_cc_name := '';
               xx_intg_mail_util_pkg.send_mail_attach
                                        (p_from_name             => v_from_email,
                                         p_to_name               => v_to_email,
                                         p_cc_name               => NULL,
                                         p_bc_name               => NULL,
                                         p_subject               => v_subject,
                                         p_message               => v_message,
                                         p_max_size              => 9999999999,
                                         p_oracle_directory      => v_hr_login_dir,
                                         p_binary_file           => v_login_file
                                        );
            END IF;

            /* Archive File*/
            IF v_error_flag != 'E'
            THEN
               BEGIN
                  UTL_FILE.fcopy (v_hr_data_dir,
                                  v_file_name,
                                  v_hr_arc_dir,
                                  v_file_name
                                 );
                  xx_emf_pkg.write_log
                                     (xx_emf_cn_pkg.cn_low,
                                      'Data File Copied to Archive Directory.'
                                     );
               EXCEPTION
                  WHEN UTL_FILE.invalid_path
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf :=
                           'Invalid Path for File Copy:'
                        || v_hr_data_dir
                        || ' - '
                        || v_hr_arc_dir;
                  WHEN UTL_FILE.invalid_filename
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf := 'Invalid File Name:' || v_file_name;
                  WHEN OTHERS
                  THEN
                     v_error_flag := 'E';
                     retcode := xx_emf_cn_pkg.cn_prc_err;
                     errbuf := 'Error Moving file: ' || SQLERRM;
               END;

               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
            END IF;                                               -- file copy
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
   END hr_extract;

/* Procedure active_status
** Derive Active Flag for 300 record in HR extract
*/
   FUNCTION active_status (
      p_employee_id          IN   NUMBER,
      p_effective_end_date   IN   DATE
   )
      RETURN VARCHAR2
   IS
   BEGIN
      IF NVL (TRUNC (p_effective_end_date), (TRUNC (SYSDATE) + 1)) <=
                                                              TRUNC (SYSDATE)
      THEN
         RETURN ('N');
      ELSE
         RETURN ('Y');
      END IF;
   END;

/* Procedure Division Name
** Derive Division name for 350 record in HR extract
*/
   FUNCTION division_name (p_organization_id IN NUMBER)
      RETURN VARCHAR2
   IS
      v_organization_name   VARCHAR2 (40);
   BEGIN
      SELECT SUBSTR (SUBSTR (SUBSTR (NAME, (INSTR (NAME, '-') + 1)),
                               INSTR (SUBSTR (NAME, (INSTR (NAME, '-') + 1)),
                                      '-'
                                     )
                             + 1
                            ),
                     1,
                     (  INSTR (SUBSTR (SUBSTR (NAME, (INSTR (NAME, '-') + 1)),
                                         INSTR (SUBSTR (NAME,
                                                        (INSTR (NAME, '-') + 1
                                                        )
                                                       ),
                                                '-'
                                               )
                                       + 1
                                      ),
                               '-'
                              )
                      - 1
                     )
                    )
        INTO v_organization_name
        FROM hr_all_organization_units_tl
       WHERE organization_id = p_organization_id AND LANGUAGE = 'US';

      RETURN (v_organization_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END;

      /* Procedure Division
   ** Derive Division name for List extract
   */
   FUNCTION division (p_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_organization_name   VARCHAR2 (40);
   BEGIN
      SELECT SUBSTR (SUBSTR (SUBSTR (p_name, (INSTR (p_name, '-') + 1)),
                               INSTR (SUBSTR (p_name,
                                              (INSTR (p_name, '-') + 1
                                              )
                                             ),
                                      '-'
                                     )
                             + 1
                            ),
                     1,
                     (  INSTR (SUBSTR (SUBSTR (p_name,
                                               (INSTR (p_name, '-') + 1
                                               )
                                              ),
                                         INSTR (SUBSTR (p_name,
                                                        (  INSTR (p_name, '-')
                                                         + 1
                                                        )
                                                       ),
                                                '-'
                                               )
                                       + 1
                                      ),
                               '-'
                              )
                      - 1
                     )
                    )
        INTO v_organization_name
        FROM DUAL;

      RETURN (v_organization_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END;

   FUNCTION send_supervisor (p_person_id IN NUMBER)
      RETURN VARCHAR2
   IS
      v_supervisor_count   NUMBER;
   BEGIN
      v_supervisor_count := 0;

      BEGIN
         SELECT COUNT (1)
           INTO v_supervisor_count
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND hla.country = 'US'
            --AND NVL(hla.region_2,'QQ') <> 'PR' --Modified for Ticket#7923
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) >=
                                                               TRUNC (SYSDATE)
            AND ppt.system_person_type IN ('EMP', 'EMP_APL')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y'
            AND paaf.supervisor_id = p_person_id
            AND (papf.person_id,
                 NVL (ppos.actual_termination_date,
                      TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                     )
                ) NOT IN (SELECT employee_id, effective_end_date
                            FROM xx_concur_hr_active_tbl xch
                           WHERE active_flag = 'N');
      END;

      /*IF v_supervisor_count1 = 0 THEN

      BEGIN
         --Active employees in previous run

         SELECT COUNT (1)
           INTO v_supervisor_count2
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                xx_concur_hr_active_tbl xxch
          WHERE papf.person_id = paaf.person_id
            AND xxch.employee_id = papf.person_id
            AND xxch.employee_number = papf.employee_number
            AND xxch.active_flag = 'Y'
            AND paaf.supervisor_id = p_person_id;
        /* SELECT COUNT (1)
           INTO v_supervisor_count2
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf,
                pay_cost_allocation_keyflex pcak,
                hr_all_organization_units haou,
                hr_locations_all hla,
                xx_concur_hr_active_tbl xxch
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = pptuf.person_id
            AND ppos.person_id = papf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND haou.organization_id = paaf.organization_id
            AND paaf.location_id = hla.location_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND xxch.employee_id = papf.person_id
            AND xxch.employee_number = papf.employee_number
            AND xxch.active_flag = 'Y'
            AND hla.country = 'US'
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      FROM per_periods_of_service ppos1
                     WHERE ppos1.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                        AND paaf.effective_end_date
                 OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                     AND paaf.effective_end_date =
                            (SELECT MAX (asg.effective_end_date)
                               FROM per_all_assignments_f asg
                              WHERE asg.assignment_id = paaf.assignment_id
                                AND asg.period_of_service_id =
                                                     paaf.period_of_service_id
                                AND asg.period_of_service_id =
                                                     ppos.period_of_service_id)
                    )
                )
            AND NVL (ppos.actual_termination_date, SYSDATE + 1) <
                                                               TRUNC (SYSDATE)
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppt.system_person_type IN ('EX_EMP')
            AND paaf.assignment_type = 'E'
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            AND paaf.primary_flag = 'Y'
            AND paaf.supervisor_id = p_person_id;
                                              UNION
                                              --Active contingent workers
                                              SELECT 1 supervisor_count
                                                FROM per_all_people_f papf,
                                                     per_all_assignments_f paaf,
                                                     per_periods_of_placement ppop,
                                                     per_person_types ppt,
                                                     per_person_type_usages_f pptuf,
                                                     pay_cost_allocation_keyflex pcak,
                                                     hr_all_organization_units haou,
                                                     hr_locations_all hla
                                               WHERE papf.person_id = paaf.person_id
                                                 AND papf.person_id = pptuf.person_id
                                                 AND ppop.person_id = papf.person_id
                                                 AND ppt.person_type_id = pptuf.person_type_id
                                                 AND haou.organization_id = paaf.organization_id
                                                 AND paaf.location_id = hla.location_id
                                                 AND ppop.period_of_placement_id =
                                                        (SELECT MAX (period_of_placement_id)
                                                           FROM per_periods_of_placement ppop1
                                                          WHERE ppop1.person_id = papf.person_id
                                                            AND date_start <= TRUNC (SYSDATE))
                                                 AND haou.cost_allocation_keyflex_id =
                                                                               pcak.cost_allocation_keyflex_id
                                                 AND hla.country = 'US'
                                                 AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                                                         AND pptuf.effective_end_date
                                                 AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                                         AND paaf.effective_end_date
                                                 AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                                         AND papf.effective_end_date
                                                 AND NVL (ppop.actual_termination_date, SYSDATE + 1) >=
                                                                                               TRUNC (SYSDATE)
                                                 AND ppt.system_person_type IN ('CWK')
                                                 AND paaf.assignment_type IN ('C')
                                                 AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
                                                 AND paaf.primary_flag = 'Y'
                                                 AND paaf.supervisor_id = p_person_id
                                                 AND paaf.assignment_id = p_assignment_id
                                                 AND (papf.person_id,
                                                      NVL (ppop.actual_termination_date,
                                                           TO_DATE ('31-DEC-4712', 'DD-MON-RRRR')
                                                          )
                                                     ) NOT IN (SELECT employee_id, effective_end_date
                                                                 FROM xx_concur_hr_active_tbl xch
                                                                WHERE active_flag = 'N')
                                              UNION
                                              --Active contingent workers in previous run
                                              SELECT 1 supervisor_count
                                                FROM per_all_people_f papf,
                                                     per_all_assignments_f paaf,
                                                     per_periods_of_placement ppop,
                                                     per_person_types ppt,
                                                     per_person_type_usages_f pptuf,
                                                     pay_cost_allocation_keyflex pcak,
                                                     hr_all_organization_units haou,
                                                     hr_locations_all hla,
                                                     xx_concur_hr_active_tbl xxch
                                               WHERE papf.person_id = paaf.person_id
                                                 AND papf.person_id = pptuf.person_id
                                                 AND ppop.person_id = papf.person_id
                                                 AND ppt.person_type_id = pptuf.person_type_id
                                                 AND haou.organization_id = paaf.organization_id
                                                 AND paaf.location_id = hla.location_id
                                                 AND ppop.period_of_placement_id =
                                                        (SELECT MAX (period_of_placement_id)
                                                           FROM per_periods_of_placement ppop1
                                                          WHERE ppop1.person_id = papf.person_id
                                                            AND date_start <= TRUNC (SYSDATE))
                                                 AND haou.cost_allocation_keyflex_id =
                                                                               pcak.cost_allocation_keyflex_id
                                                 AND hla.country = 'US'
                                                 AND xxch.employee_id = papf.person_id
                                                 AND NVL (xxch.employee_number, 'XYZ') = papf.npw_number
                                                 AND xxch.active_flag = 'Y'
                                                 AND paaf.supervisor_id = p_person_id
                                                 AND paaf.assignment_id = p_assignment_id
                                                 AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                                         AND papf.effective_end_date
                                                 AND (   TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                                             AND paaf.effective_end_date
                                                      OR (    paaf.effective_end_date < TRUNC (SYSDATE)
                                                          AND paaf.effective_end_date =
                                                                 (SELECT MAX (asg.effective_end_date)
                                                                    FROM per_all_assignments_f asg
                                                                   WHERE asg.assignment_id =
                                                                                            paaf.assignment_id
                                                                     AND asg.person_id = papf.person_id)
                                                         )
                                                     )
                                                 AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                                                         AND pptuf.effective_end_date
                                                 AND NVL (ppop.actual_termination_date, SYSDATE + 1) <
                                                                                               TRUNC (SYSDATE)
                                                 AND ppt.system_person_type IN ('EX_CWK')
                                                 AND paaf.assignment_type IN ('C')
                                                 AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
                                                 AND paaf.primary_flag = 'Y'
      ) t;*/

     -- END;

     -- END IF;

      IF v_supervisor_count > 0
      THEN
         RETURN ('Y');
      ELSE
         RETURN ('N');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN ('N');
   END send_supervisor;

   FUNCTION pay_group (p_emp_number VARCHAR2)
      RETURN VARCHAR2
   IS
      v_count   NUMBER        := 0;
      v_group   VARCHAR2 (20);
   BEGIN
      v_count := 0;

      SELECT COUNT (1)
        INTO v_count
        FROM fnd_lookup_values
       WHERE lookup_type = 'XX_CONCUR_NON_PAY_GROUP'
         AND lookup_code = p_emp_number
         AND enabled_flag = 'Y'
         AND LANGUAGE = 'US'
         AND NVL (end_date_active, SYSDATE + 1) > SYSDATE;

      IF v_count = 0
      THEN
         v_group := 'US';
      ELSE
         v_group := 'US-Non Pay';
      END IF;

      RETURN (v_group);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_group := 'US';
         RETURN (v_group);
   END;
END XX_CONCUR_EXTRACT_PKG;
/
