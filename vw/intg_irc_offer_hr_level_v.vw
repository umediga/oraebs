DROP VIEW APPS.INTG_IRC_OFFER_HR_LEVEL_V;

/* Formatted on 6/6/2016 5:00:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.INTG_IRC_OFFER_HR_LEVEL_V
(
   FULL_NAME,
   NAME,
   POSITION_ID,
   REF_TYPE
)
AS
   SELECT DISTINCT paf.full_name,
                   hap.NAME,
                   hap.position_id,
                   'LEVEL1' ref_type
     FROM hr_all_positions_f hap,
          per_all_assignments_f paaf,
          per_assignment_status_types past,
          per_all_people_f paf
    WHERE     hap.attribute7 = 'Yes'
          AND paaf.position_id = hap.position_id
          AND past.assignment_status_type_id = paaf.assignment_status_type_id
          AND past.per_system_status <> 'TERM_ASSIGN'
          AND paaf.assignment_type = 'E'
          AND paaf.primary_flag = 'Y'
          AND paaf.person_id = paf.person_id
   UNION
   SELECT DISTINCT paf.full_name,
                   hap.NAME,
                   hap.position_id,
                   'LEVEL2' ref_type
     FROM hr_all_positions_f hap,
          per_all_assignments_f paaf,
          per_assignment_status_types past,
          per_all_people_f paf
    WHERE     hap.attribute8 = 'Yes'
          AND paaf.position_id = hap.position_id
          AND past.assignment_status_type_id = paaf.assignment_status_type_id
          AND past.per_system_status <> 'TERM_ASSIGN'
          AND paaf.assignment_type = 'E'
          AND paaf.primary_flag = 'Y'
          AND paaf.person_id = paf.person_id;
