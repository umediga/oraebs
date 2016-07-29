DROP VIEW APPS.XX_EMP_ADLOGIN_V;

/* Formatted on 6/6/2016 4:58:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_EMP_ADLOGIN_V
(
   USER_NAME,
   EMPLOYEE_NUMBER,
   SYSTEM_PERSON_TYPE,
   POSITION,
   MANAGER_NAME,
   MANAGER_NUMBER,
   ADLOGIN_ID
)
AS
   SELECT fu.user_name,
          NVL (emp.employee_number, emp.npw_number) employee_number,
          ppt.system_person_type,
          ppd.SEGMENT1 POSITION,
          sup.full_name manager_name,
          NVL (sup.employee_number, sup.npw_number) manager_number,
          ad.adlogin_id
     FROM per_people_x emp,
          per_person_types ppt,
          per_people_x sup,
          per_assignments_x asg,
          --per_positions_kfv,
          fnd_user fu,
          per_position_definitions_kfv ppd,
          per_positions pp,
          per_jobs pj,
          per_job_definitions_kfv pjd,
          xx_aduser ad
    WHERE     emp.person_id = asg.person_id
          AND sup.person_id = asg.supervisor_id(+)
          AND emp.person_type_id = ppt.person_type_id
          AND emp.person_id = fu.employee_id(+)
          AND NVL (sup.employee_number, sup.npw_number) = ad.empnumber(+)
          AND asg.job_id = pj.job_id(+)
          AND pj.job_definition_id = pjd.job_definition_id(+)
          AND asg.position_id = pp.position_id(+)
          AND pp.position_definition_id = ppd.position_definition_id(+)
          AND ppt.system_person_type IN ('EMP_APL', 'EMP', 'OTHER');
