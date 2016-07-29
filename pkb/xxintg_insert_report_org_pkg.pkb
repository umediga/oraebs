DROP PACKAGE BODY APPS.XXINTG_INSERT_REPORT_ORG_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_INSERT_REPORT_ORG_PKG" 
AS
   PROCEDURE insert_reporting_org (
      x_errbuff   OUT   VARCHAR2,
      x_retcode   OUT   NUMBER
   )
   AS
      CURSOR csr_get_report_org
      IS
         SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                TRUNC (SYSDATE)
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id=ppos.person_id
            AND ppos.period_of_service_id = (select max(period_of_service_id)
                                             from per_periods_of_service ppos1
                                             where ppos1.person_id=papf.person_id
                                             and ppos1.date_start <= trunc(sysdate)
                                             )
            AND ppos.actual_termination_date is NULL
            AND papf.person_id = paaf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('E')
            AND ppt.system_person_type IN ('EMP')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
          UNION
           SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                ppos.date_start
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND ppos.date_start > trunc(sysdate)
            AND ppos.period_of_service_id = (select max(period_of_service_id)
                                             from per_periods_of_service ppos1
                                             where ppos1.person_id=papf.person_id
                                             )
            AND ppos.date_start BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND ppos.date_start BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppos.date_start BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('E')
            AND ppt.system_person_type IN ('EMP')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            UNION
           SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                ppos.actual_termination_date
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND ppos.actual_termination_date IS NOT NULL
            AND nvl(ppos.actual_termination_date,trunc(sysdate)+1) < trunc(sysdate)
            AND ppos.period_of_service_id = (select max(period_of_service_id)
                                             from per_periods_of_service ppos1
                                             where ppos1.person_id=papf.person_id
                                             and ppos1.date_start <=trunc(sysdate)
                                             )
            AND ppos.actual_termination_date BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND ppos.actual_termination_date BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppos.actual_termination_date BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('E')
            AND ppt.system_person_type IN ('EMP')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            UNION
            SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                TRUNC (SYSDATE)
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id=ppos.person_id
            AND ppos.date_start = (select max(date_start)
                                             from per_periods_of_placement ppos1
                                             where ppos1.person_id=papf.person_id
                                             and ppos1.date_start <= trunc(sysdate)
                                             )
            AND ppos.actual_termination_date is NULL
            AND papf.person_id = paaf.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('C')
            AND ppt.system_person_type IN ('CWK')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
          UNION
           SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                ppos.date_start
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND ppos.date_start > trunc(sysdate)
            AND ppos.date_start = (select max(date_start)
                                             from per_periods_of_placement ppos1
                                             where ppos1.person_id=papf.person_id
                                             )
            AND ppos.date_start BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND ppos.date_start BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppos.date_start BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('C')
            AND ppt.system_person_type IN ('CWK')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO'
            UNION
           SELECT system_person_type, papf.person_id,
                NVL (papf.employee_number, npw_number) emp_number,
                xxintg_hr_get_reporting_org.get_reporting_org
                                               (papf.person_id,
                                                ppos.actual_termination_date
                                               ) reporting_org,
                paaf.object_version_number, paaf.assignment_id
                ,paaf.effective_start_date
                ,paaf.effective_end_date
                ,ppos.date_start
                ,nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY')) date_end
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppos,
                per_person_types ppt,
                per_person_type_usages_f pptuf
          WHERE papf.person_id = pptuf.person_id
            AND papf.person_id = paaf.person_id
            AND papf.person_id=ppos.person_id
            AND ppt.person_type_id = pptuf.person_type_id
            AND ppos.actual_termination_date IS NOT NULL
            AND nvl(ppos.actual_termination_date,trunc(sysdate)+1) < trunc(sysdate)
            AND ppos.date_start = (select max(date_start)
                                             from per_periods_of_placement ppos1
                                             where ppos1.person_id=papf.person_id
                                             and ppos1.date_start <=trunc(sysdate)
                                             )
            AND ppos.actual_termination_date BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND ppos.actual_termination_date BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppos.actual_termination_date BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type IN ('C')
            AND ppt.system_person_type IN ('CWK')
            AND NVL (UPPER (papf.attribute5), 'YES') != 'NO';



   BEGIN

      DELETE FROM XXINTG.XXINTG_HR_REPORTING_ORG;

      FOR rec_get_report_org IN csr_get_report_org
      LOOP

           BEGIN

                INSERT INTO XXINTG.XXINTG_HR_REPORTING_ORG VALUES(rec_get_report_org.person_id
                ,rec_get_report_org.assignment_id
                ,rec_get_report_org.reporting_org
                ,rec_get_report_org.date_start
                ,rec_get_report_org.date_end
                );
           EXCEPTION
                WHEN OTHERS THEN
                   fnd_file.put_line
                           (fnd_file.LOG,
                               'Error in inserting reporting org for employee number'
                            || rec_get_report_org.emp_number
                            || SQLERRM
                           );
           END;
      END LOOP;

    COMMIT;

      FND_STATS.gather_table_stats(ownname => 'XXINTG',tabname => 'XXINTG_HR_REPORTING_ORG',percent =>99);

   END insert_reporting_org;
END xxintg_insert_report_org_pkg;
/
