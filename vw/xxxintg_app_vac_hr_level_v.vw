DROP VIEW APPS.XXXINTG_APP_VAC_HR_LEVEL_V;

/* Formatted on 6/6/2016 5:00:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXXINTG_APP_VAC_HR_LEVEL_V
(
   FULL_NAME,
   NAME,
   POSITION_ID,
   REF_TYPE
)
AS
   SELECT DISTINCT paf.full_name,
                   pap.name,
                   pap.position_id,
                   'LEVEL1' REF_TYPE
     FROM per_all_positions pap,
          per_all_assignments_f paaf,
          PER_ASSIGNMENT_STATUS_TYPES past,
          per_all_people_f paf
    WHERE     pap.attribute7 = 'Yes'
          AND paaf.position_id = pap.position_id
          AND past.Assignment_status_type_id = paaf.Assignment_status_type_id
          AND past.PER_SYSTEM_STATUS <> 'TERM_ASSIGN'
          AND paaf.ASSIGNMENT_TYPE = 'E'
          AND paaf.PRIMARY_FLAG = 'Y'
          AND paaf.person_id = paf.person_id
   --and  sysdate between paf.effective_start_date and paf.effective_end_date
   UNION
   SELECT DISTINCT paf.full_name,
                   pap.name,
                   pap.position_id,
                   'LEVEL2' REF_TYPE
     FROM per_all_positions pap,
          per_all_assignments_f paaf,
          PER_ASSIGNMENT_STATUS_TYPES past,
          per_all_people_f paf
    WHERE     pap.attribute8 = 'Yes'
          AND paaf.position_id = pap.position_id
          AND past.Assignment_status_type_id = paaf.Assignment_status_type_id
          AND past.PER_SYSTEM_STATUS <> 'TERM_ASSIGN'
          AND paaf.ASSIGNMENT_TYPE = 'E'
          AND paaf.PRIMARY_FLAG = 'Y'
          AND paaf.person_id = paf.person_id;
