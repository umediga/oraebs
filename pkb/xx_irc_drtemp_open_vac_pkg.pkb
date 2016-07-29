DROP PACKAGE BODY APPS.XX_IRC_DRTEMP_OPEN_VAC_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IRC_DRTEMP_OPEN_VAC_PKG" 
AS
/*------------------------------------------------------------------------------
 Module Name  : Oracle IRecurietment - Open Vancancy Report- Direct Employee.
 File Name    : xx_irc_drtemp_open_vac_pkg.pkb
 Description  : This package is called from con-current program 'INTG IREC- Open
                Vacancies
                Report - DirectEmployers'. It generates the XML file with the open
                vacancy Details and FTP the xml file to DirectEmployers sever.

 Parameters   : P_EFF_DATE    VARCHAR IN
                P_FILE_NAME   VARCHAR IN

 Created By   : Yogesh Rudrasetty.
 Creation Date: 02/01/2012
 History      : Initial Creation.


 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 23-Aug-2012   Renjith               Removed FTP logic
                                     moved file name to process setup
                                     moved directory to process setup
                                     seperated procedure for file creation
                                     added exceptions
------------------------------------------------------------------------------*/
   FUNCTION lob_to_char (clob_col CLOB)
      RETURN VARCHAR2
   IS
      x_buffer   VARCHAR2 (32767);
      x_amt      BINARY_INTEGER   := 32767;
      x_pos      INTEGER          := 1;
      --x_lcolb        CLOB;
      --x_bfils    BFILE;
      x_var      VARCHAR2 (32767) := '';
   BEGIN
      LOOP
         IF DBMS_LOB.getlength (clob_col) <= 32767
         THEN
            DBMS_LOB.READ (clob_col, x_amt, x_pos, x_buffer);
            x_var := x_var || x_buffer;
            x_pos := x_pos + x_amt;
         ELSE
            x_var :=
                 'Cannot Convert to Varchar2..Exceeding Varchar2 Field Limit';
            EXIT;
         END IF;
      END LOOP;

      RETURN x_var;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN x_var;
      WHEN OTHERS
      THEN
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand,
                           'Cannot Convert From CLOB to CHAR:',
                           SQLERRM
                          );
   END lob_to_char;

-- --------------------------------------------------------------------- --

   PROCEDURE main ( errbuf        OUT      VARCHAR2,
                    retcode       OUT      NUMBER,
                    p_eff_date    IN       VARCHAR2,
                    p_file_name   IN       VARCHAR2
   )
   IS
      --- Local variables declaration
      x_file_type       UTL_FILE.file_type;
      x_dir_path        VARCHAR2 (500);
      x_ret_code        NUMBER;
      x_error_message   VARCHAR2(1000);
      x_data_dir        VARCHAR2(40);
      x_file_name       VARCHAR2 (500);
      -- Cursor to fetch records to insert into staging table
      CURSOR vac_cur
      IS
         (SELECT fnd_global.conc_request_id, r.NAME, ipc.org_name,
                 pv.vacancy_id vacancy_id, ipc.job_title,
                 ipc.detailed_description job_requirements,
                 (SELECT    fnd_profile.VALUE
                                       ('IRC_FRAMEWORK_AGENT')
                         ||'/'|| 'OA_HTML/OA.jsp?OAFunc='
                         || fnd_profile.VALUE ('IRC_JOB_NOTIFICATION_URL')
                         || '&'
                         || 'p_svid='
                         || TO_CHAR (vac.vacancy_id)
                         || '&'
                         || 'p_spid='
                         || TO_CHAR (ipc.posting_content_id)
                         || '&'
                         || 'p_site_id='
                         || TO_CHAR (rse.recruiting_site_id)
                                                job_posting_url
                    FROM irc_posting_contents_tl ipctl,
                         irc_posting_contents ipc,
                         per_recruitment_activities rec,
                         per_recruitment_activity_for recf,
                         per_all_vacancies vac,
                         irc_search_criteria isc,
                         irc_all_recruiting_sites rse,
                         irc_all_recruiting_sites_tl rsetl
                   WHERE ipctl.LANGUAGE = USERENV ('LANG')
                     AND ipctl.posting_content_id = rec.posting_content_id
                     AND ipc.posting_content_id = rec.posting_content_id
                     AND rse.recruiting_site_id = rec.recruiting_site_id
                     AND rsetl.recruiting_site_id = rec.recruiting_site_id
                     AND rsetl.LANGUAGE = USERENV ('LANG')
                     AND rec.recruitment_activity_id =
                                                  recf.recruitment_activity_id
                     AND recf.vacancy_id = vac.vacancy_id
                     AND vac.vacancy_id = isc.object_id(+)
                     AND vac.vacancy_id = pv.vacancy_id
                     AND isc.object_type(+) = 'VACANCY'
                     AND rse.site_name = 'iRecruitment External Site'
                     AND UPPER (NVL (vac.attribute13, 'NO')) ! = 'YES')
                                                                how_to_apply,
                 DECODE (pv.attribute4,
                         NULL, (hla.town_or_city || ', ' || hla.region_2),
                         DECODE (pv.attribute5,
                                 NULL, (hla.town_or_city || ', '
                                        || hla.region_2),
                                 pv.attribute4 || ', ' || pv.attribute5
                                )
                        ) location_code,
                 NULL file_name, xx_emf_cn_pkg.cn_new process_code,
                 NULL ERROR_CODE, NULL created_by, SYSDATE creation_date,
                 NULL last_updated_by, NULL last_update_date,
                 NULL last_update_login, NULL attribute1, NULL attribute2,
                 NULL attribute3, NULL attribute4, NULL attribute5
            FROM per_vacancies pv,
                 irc_posting_contents_tl ipc,
                 hr_locations_all hla,
                 apps.per_requisitions r,
                 irc_all_recruiting_sites irs,
                 per_recruitment_activities pra
           WHERE NVL(TO_DATE(p_eff_date, 'YYYY-MM-DD HH24:MI:SS'), SYSDATE)  --TO_DATE (NVL (p_eff_date, SYSDATE), 'YYYY/MM/DD HH24:MI:SS')
                    BETWEEN pv.date_from
                        AND NVL (pv.date_to,
                                 NVL(TO_DATE (p_eff_date,  --TO_DATE (NVL (p_eff_date, SYSDATE),
                                          'YYYY-MM-DD HH24:MI:SS'  --'YYYY/MM/DD HH24:MI:SS'
                                         ), SYSDATE)
                                )
             AND pv.status = 'APPROVED'
             AND ipc.posting_content_id = pv.primary_posting_id
             AND ipc.LANGUAGE = 'US'
             AND pv.location_id = hla.location_id
             AND r.requisition_id = pv.requisition_id
             AND pra.posting_content_id = ipc.posting_content_id
             AND irs.recruiting_site_id = pra.recruiting_site_id
             AND irs.site_name = 'iRecruitment External Site'
             AND UPPER (NVL (pv.attribute13, 'NO')) ! =
                                                 'YES'
                                                      -- non-confidential jobs
             AND (   hla.country = 'US'
                  OR (pv.attribute4 IS NOT NULL AND pv.attribute5 IS NOT NULL
                     )
                 )
             AND NVL(TO_DATE(p_eff_date, 'YYYY-MM-DD HH24:MI:SS'), SYSDATE)  --TO_DATE (NVL (p_eff_date, SYSDATE), 'YYYY/MM/DD HH24:MI:SS')
                    BETWEEN pra.date_start
                        AND NVL (pra.date_end,
                                 NVL(TO_DATE (p_eff_date,  --TO_DATE (NVL (p_eff_date, SYSDATE),
                                          'YYYY-MM-DD HH24:MI:SS'  --'YYYY/MM/DD HH24:MI:SS'
                                         ), SYSDATE)
                                ))
         UNION ALL
         (SELECT fnd_global.conc_request_id, r.NAME, ipc.org_name,
                 pv.vacancy_id vacancy_id, ipc.job_title,
                 ipc.detailed_description job_requirements,
                 (SELECT    fnd_profile.VALUE
                                       ('IRC_FRAMEWORK_AGENT')
                         ||'/'|| 'OA_HTML/OA.jsp?OAFunc='
                         || fnd_profile.VALUE ('IRC_JOB_NOTIFICATION_URL')
                         || '&'
                         || 'p_svid='
                         || TO_CHAR (vac.vacancy_id)
                         || '&'
                         || 'p_spid='
                         || TO_CHAR (ipc.posting_content_id)
                         || '&'
                         || 'p_site_id='
                         || TO_CHAR (rse.recruiting_site_id)
                                                job_posting_url
                    FROM irc_posting_contents_tl ipctl,
                         irc_posting_contents ipc,
                         per_recruitment_activities rec,
                         per_recruitment_activity_for recf,
                         per_all_vacancies vac,
                         irc_search_criteria isc,
                         irc_all_recruiting_sites rse,
                         irc_all_recruiting_sites_tl rsetl
                   WHERE ipctl.LANGUAGE = USERENV ('LANG')
                     AND ipctl.posting_content_id = rec.posting_content_id
                     AND ipc.posting_content_id = rec.posting_content_id
                     AND rse.recruiting_site_id = rec.recruiting_site_id
                     AND rsetl.recruiting_site_id = rec.recruiting_site_id
                     AND rsetl.LANGUAGE = USERENV ('LANG')
                     AND rec.recruitment_activity_id =
                                                  recf.recruitment_activity_id
                     AND recf.vacancy_id = vac.vacancy_id
                     AND vac.vacancy_id = isc.object_id(+)
                     AND vac.vacancy_id = pv.vacancy_id
                     AND isc.object_type(+) = 'VACANCY'
                     AND rse.site_name = 'iRecruitment External Site'
                     AND UPPER (NVL (vac.attribute13, 'NO')) ! = 'YES')
                                                                 how_to_apply,
                 pv.attribute4 || ', ' || pv.attribute5 location_code,
                 NULL file_name, xx_emf_cn_pkg.cn_new process_code,
                 NULL ERROR_CODE, NULL created_by, SYSDATE creation_date,
                 NULL last_updated_by, NULL last_update_date,
                 NULL last_update_login, NULL attribute1, NULL attribute2,
                 NULL attribute3, NULL attribute4, NULL attribute5
            FROM per_vacancies pv,
                 irc_posting_contents_tl ipc,
                 apps.per_requisitions r,
                 irc_all_recruiting_sites irs,
                 per_recruitment_activities pra
           WHERE NVL(TO_DATE(p_eff_date, 'YYYY-MM-DD HH24:MI:SS'), SYSDATE)  --TO_DATE (NVL (p_eff_date, SYSDATE), 'YYYY/MM/DD HH24:MI:SS')
                    BETWEEN pv.date_from
                        AND NVL (pv.date_to,
                                 NVL(TO_DATE (p_eff_date,  --TO_DATE (NVL (p_eff_date, SYSDATE),
                                          'YYYY-MM-DD HH24:MI:SS'  --'YYYY/MM/DD HH24:MI:SS'
                                        ), SYSDATE)
                                )
             AND pv.status = 'APPROVED'
             AND ipc.posting_content_id = pv.primary_posting_id
             AND ipc.LANGUAGE = 'US'
             AND pv.location_id IS NULL
             AND r.requisition_id = pv.requisition_id
             AND pra.posting_content_id = ipc.posting_content_id
             AND irs.recruiting_site_id = pra.recruiting_site_id
             AND irs.site_name = 'iRecruitment External Site'
             AND UPPER (NVL (pv.attribute13, 'NO')) ! =
                                                 'YES'
                                                      -- non-confidential jobs
             AND pv.attribute4 IS NOT NULL
             AND pv.attribute5 IS NOT NULL
             AND NVL(TO_DATE(p_eff_date, 'YYYY-MM-DD HH24:MI:SS'), SYSDATE)  --TO_DATE (NVL (p_eff_date, SYSDATE), 'YYYY/MM/DD HH24:MI:SS')
                    BETWEEN pra.date_start
                        AND NVL (pra.date_end,
                                 NVL(TO_DATE (p_eff_date,  --TO_DATE (NVL (p_eff_date, SYSDATE),
                                          'YYYY-MM-DD HH24:MI:SS'  --'YYYY/MM/DD HH24:MI:SS'
                                         ), SYSDATE)
                                ));

      -- Cursor to fetch record from staging table
      CURSOR vac_stage_cur (c_request_id NUMBER)
      IS
         SELECT *
           FROM xx_irc_direct_employee_stg
          WHERE conc_request_id = c_request_id
            AND process_code = xx_emf_cn_pkg.cn_in_prog
            AND ERROR_CODE IS NULL;

      vac_stage_rec    vac_stage_cur%ROWTYPE;

      TYPE vac_curarray IS TABLE OF vac_cur%ROWTYPE;
      x_vac_data               vac_curarray;
      x_error_code             NUMBER;
      x_is_rec                 VARCHAR2(1) := 'Y';
-- --------------------------------------------------------------------- --
   PROCEDURE file_writing ( p_file_name       IN     VARCHAR2
                           ,x_return_code     OUT    NUMBER
                           ,x_error_msg       OUT    VARCHAR2)

   IS
        x_dir_path          VARCHAR2(1000);

        x_exists            BOOLEAN;
        x_file_length       NUMBER;
        x_size              NUMBER;
        x_file_prefix       VARCHAR2(20);
   BEGIN
      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXIRCDIRECTEMP_CP'
                                                 ,p_param_name      => 'DATA_DIR'
                                                 ,x_param_value     =>  x_data_dir);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Process setup Directory: '||x_data_dir);
      -- fetching source directory path to a variable
      BEGIN
         SELECT directory_path
           INTO x_dir_path
           FROM all_directories
          WHERE directory_name = x_data_dir;--'XX_IRC_DIREMP_DIR';
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'path: '||x_dir_path);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_msg := SUBSTR (SQLERRM, 1, 250);
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_low,
                               xx_emf_cn_pkg.cn_tech_error,
                               xx_emf_cn_pkg.cn_exp_unhand,
                               'Oracle Directory Not Defined',
                               SQLERRM);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Oracle Directory Not Defined');
         WHEN OTHERS
         THEN
            x_error_msg := SUBSTR (SQLERRM, 1, 250);
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand,
                              'Could Not Fetch The Path From Oracle Directory',
                              SQLERRM
                             );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Could Not Fetch The Path From Oracle Directory '||x_data_dir);
      END;

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXIRCDIRECTEMP_CP'
                                                 ,p_param_name      => 'FILE_PREFIX'
                                                 ,x_param_value     =>  x_file_prefix);
      IF x_file_prefix <> '-' THEN
        x_file_name := x_file_prefix||p_file_name;
      ELSE
        x_file_name := p_file_name;
      END IF;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name: '||x_file_name);
      -- opening the file
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name: '||x_file_name);
         x_file_type := UTL_FILE.fopen (x_data_dir, x_file_name, 'W', 32767);
      EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || x_file_name;
          WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := x_file_name || SQLERRM;
      END; -- End of File open exception

      IF NVL(x_return_code,0) = 0 THEN
         FND_FILE.PUT_LINE (fnd_file.LOG, 'file opened');
         UTL_FILE.PUT_LINE (x_file_type, '<JOBS>');
         FND_FILE.PUT_LINE (fnd_file.output, '<JOBS>');

         FOR vac_stage_rec in vac_stage_cur(fnd_global.conc_request_id)
         LOOP
            BEGIN
                --fnd_file.put_line(fnd_file.log,'FND <REQNUMBER>'||vac_rec.name||'</REQNUMBER>');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'FND <REQNUMBER>'||vac_stage_rec.VACANCY_NAME||'</REQNUMBER>');
                -- fill in data
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOB>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOBTITLE><![CDATA['||vac_stage_rec.job_title||']]></JOBTITLE>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<REQNUMBER>'||vac_stage_rec.vacancy_name||'</REQNUMBER>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOBCOMPANY>'||vac_stage_rec.org_name||'</JOBCOMPANY>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOBLOCATION>'||vac_stage_rec.location_code||'</JOBLOCATION>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOBBODY><![CDATA['||lob_to_char(vac_stage_rec.job_requirements)||']]></JOBBODY>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<JOBLINK><![CDATA['||vac_stage_rec.how_to_apply||']]></JOBLINK>');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'</JOB>');
                --fnd_file.put_line(fnd_file.log,'UTL <REQNUMBER>'||vac_stage_rec.name||'</REQNUMBER>');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'UTL <REQNUMBER>'||vac_stage_rec.VACANCY_NAME||'</REQNUMBER>');

                UTL_FILE.PUT_LINE(x_file_type,'<JOB>');
                UTL_FILE.PUT_LINE(x_file_type,'<JOBTITLE><![CDATA['||vac_stage_rec.job_title||']]></JOBTITLE>');
                UTL_FILE.PUT_LINE(x_file_type,'<REQNUMBER>'||vac_stage_rec.vacancy_name||'</REQNUMBER>');
                UTL_FILE.PUT_LINE(x_file_type,'<JOBCOMPANY>'||vac_stage_rec.org_name||'</JOBCOMPANY>');
                UTL_FILE.PUT_LINE(x_file_type,'<JOBLOCATION>'||vac_stage_rec.location_code||'</JOBLOCATION>');
                UTL_FILE.PUT_LINE(x_file_type,'<JOBBODY><![CDATA['||lob_to_char(vac_stage_rec.job_requirements)||']]></JOBBODY>');
                UTL_FILE.PUT_LINE(x_file_type,'<JOBLINK><![CDATA['||vac_stage_rec.how_to_apply||']]></JOBLINK>');
                UTL_FILE.PUT_LINE(x_file_type,'</JOB>');
            EXCEPTION
                WHEN OTHERS THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,vac_stage_rec.VACANCY_NAME,SQLERRM );
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Cannot write the record details for the vacancy' || vac_stage_rec.VACANCY_NAME );
                    x_error_msg := SUBSTR(SQLERRM,1,250);
                    x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;

                    -- Records updated as errored
                    UPDATE XX_IRC_DIRECT_EMPLOYEE_STG
                       SET error_code = xx_emf_cn_pkg.CN_REC_ERR
                     WHERE conc_request_id = fnd_global.conc_request_id
                       AND vacancy_name =vac_stage_rec.VACANCY_NAME
                       AND process_code = xx_emf_cn_pkg.CN_IN_PROG;

                    COMMIT;
            END;
         END LOOP;

         UTL_FILE.PUT_LINE (x_file_type, '</JOBS>');
         FND_FILE.PUT_LINE (fnd_file.output, '</JOBS>');
      END IF;

      UTL_FILE.fgetattr ( x_data_dir
                         ,x_file_name
                         ,x_exists
                         ,x_file_length
                         ,x_size);

      IF x_exists THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_file_name||' File exits in Directory '||x_data_dir);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'NO File exits in Directory');
      END IF;

      IF UTL_FILE.IS_OPEN(x_file_type) THEN
         UTL_FILE.FCLOSE   (x_file_type);
      END IF;
      FND_FILE.PUT_LINE (fnd_file.LOG, 'file close');
      FND_FILE.PUT_LINE (fnd_file.output,'#################################################');
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Writing File: ' ||SQLERRM);
          xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          x_error_msg := 'Error while Writing File: ' ||SQLERRM;
          UTL_FILE.fclose (x_file_type);
   END file_writing;
-- --------------------------------------------------------------------- --

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_irc_direct_employee_stg
             WHERE conc_request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT COUNT (1) error_count
              FROM xx_irc_direct_employee_stg
             WHERE conc_request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_in_prog
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_irc_direct_employee_stg
             WHERE conc_request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_irc_direct_employee_stg
             WHERE conc_request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
      BEGIN
         OPEN c_get_total_cnt;
         FETCH c_get_total_cnt
         INTO x_total_cnt;
         CLOSE c_get_total_cnt;

         OPEN c_get_error_cnt;
         FETCH c_get_error_cnt
         INTO x_error_cnt;
         CLOSE c_get_error_cnt;

         OPEN c_get_success_cnt;
         FETCH c_get_success_cnt
         INTO x_success_cnt;
         CLOSE c_get_success_cnt;

         xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                     p_success_recs_cnt      => x_success_cnt,
                                     p_warning_recs_cnt      => 0,
                                     p_error_recs_cnt        => x_error_cnt
                                    );
      END update_record_count;

-- --------------------------------------------------------------------- --
 -- Setting stage
      PROCEDURE set_stage (p_stage VARCHAR2)
      IS
      BEGIN
         g_stage := p_stage;
      END set_stage;

-- --------------------------------------------------------------------- --

      -- Cross Updating the stagin table
      PROCEDURE update_staging_records (p_error_code VARCHAR2)
      IS
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_irc_direct_employee_stg
            SET process_code = g_stage
                                      --,error_code = p_error_code --DECODE ( error_code, NULL, p_error_code, error_code)
         ,
                creation_date = SYSDATE,
                created_by = fnd_global.user_id,
                last_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id,
                last_update_login = x_last_update_login
          WHERE conc_request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_new;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error while Updating STAGE status : '
                                  || SQLERRM
                                 );
      END update_staging_records;
-- --------------------------------------------------------------------- --

   --Main
   BEGIN
      BEGIN
         retcode := xx_emf_cn_pkg.cn_success;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Before Setting Environment'
                              );
         -- Set the environment
         x_error_code := xx_emf_pkg.set_env;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE xx_emf_pkg.g_e_env_not_set;
      END;

      -- Bulk insert of eligible records into staging table
      BEGIN
         OPEN vac_cur;

         LOOP
            FETCH vac_cur
            BULK COLLECT INTO x_vac_data LIMIT 1000;

            FORALL i IN 1 .. x_vac_data.COUNT
               INSERT INTO xx_irc_direct_employee_stg
                    VALUES x_vac_data (i);
            EXIT WHEN vac_cur%NOTFOUND;
         END LOOP;
         CLOSE vac_cur;
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            errbuf := SUBSTR (SQLERRM, 1, 250);
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand,
                              'Bulk Collect/Insert Failed',
                              SQLERRM
                             );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Bulk Collect/Insert Failed');
      END;

      -- Set the staging records to In Process status
      set_stage (xx_emf_cn_pkg.cn_in_prog);
      -- Cross updating staging table
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Start Calling update_staging_records..');
      update_staging_records (xx_emf_cn_pkg.cn_success);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'End Calling update_staging_records..'||fnd_global.conc_request_id);

      ---
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Checking Record count..');
      file_writing ( p_file_name      => p_file_name
                    ,x_return_code    => x_ret_code
                    ,x_error_msg      => x_error_message);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'after writting..error code: '||x_ret_code||' error message: '||x_error_message);

      IF x_ret_code = xx_emf_cn_pkg.CN_PRC_ERR THEN
         errbuf := SUBSTR (SQLERRM, 1, 250);
         xx_emf_pkg.error ( xx_emf_cn_pkg.cn_low,
                            xx_emf_cn_pkg.cn_tech_error,
                            xx_emf_cn_pkg.cn_exp_unhand,
                            'File Writting failed',
                            x_error_message
                          );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'File Writting failed: '||x_error_message);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,'ULT File Error: '||x_error_message);
      END IF;
      ---

      -- Records updated as Success
      UPDATE xx_irc_direct_employee_stg
         SET process_code = xx_emf_cn_pkg.cn_process_data,
             error_code   = NVL(x_ret_code,xx_emf_cn_pkg.cn_success),
             file_name    = x_file_name
       WHERE conc_request_id = fnd_global.conc_request_id
         AND process_code    = xx_emf_cn_pkg.cn_in_prog
         AND error_code IS NULL;

      -- Generate EMF processing report to display in output
      update_record_count;
      xx_emf_pkg.create_report;
      IF x_ret_code IS NOT NULL THEN
         retcode := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         retcode := 1;
         errbuf := SUBSTR (SQLERRM, 1, 250);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand,
                           'Unexpected error ',
                           SQLERRM
                          );
   END main;
END xx_irc_drtemp_open_vac_pkg;
/
