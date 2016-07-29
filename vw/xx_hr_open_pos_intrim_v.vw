DROP VIEW APPS.XX_HR_OPEN_POS_INTRIM_V;

/* Formatted on 6/6/2016 4:58:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_OPEN_POS_INTRIM_V
(
   "Parent Box Unique Identifier",
   "Box Unique Identifier",
   "Box Title",
   "Position Name",
   "Position Unique Identifier",
   END
)
AS
   SELECT papf.employee_number "Parent Box Unique Identifier",
          pav.name "Box Unique Identifier",
          SUBSTR (haou.name,
                    INSTR (haou.name,
                           '-',
                           1,
                           2)
                  + 1,
                  (  INSTR (haou.name,
                            '-',
                            1,
                            3)
                   - INSTR (haou.name,
                            '-',
                            1,
                            2)
                   - 1))
             "Box Title",
          hapf.name "Position Name",
          pav.position_id "Position Unique Identifier",
          'END' "END"
     FROM apps.per_all_vacancies pav,
          apps.hr_all_positions_f hapf,
          apps.hr_all_organization_units haou,
          apps.per_all_people_f papf
    WHERE     pav.position_id = hapf.position_id
          AND papf.person_id(+) = pav.manager_id
          AND papf.attribute6 = 'Yes'
          AND pav.organization_id = haou.organization_id
          AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                  AND hapf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date(+)
                                  AND papf.effective_end_date(+)
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.per_all_assignments_f
                   WHERE     assignment_type IN ('E', 'C')
                         AND position_id = pav.position_id
                         AND TRUNC (SYSDATE) BETWEEN effective_start_date
                                                 AND effective_end_date)
          AND pav.status IN ('APPROVED');


GRANT SELECT ON APPS.XX_HR_OPEN_POS_INTRIM_V TO XXAPPSREAD;
