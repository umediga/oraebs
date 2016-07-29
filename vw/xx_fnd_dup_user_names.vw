DROP VIEW APPS.XX_FND_DUP_USER_NAMES;

/* Formatted on 6/6/2016 4:58:40 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_DUP_USER_NAMES
(
   USER_NAME_COUNT,
   FULL_NAME,
   SYSTEM_PERSON_TYPE,
   USER_PERSON_TYPE
)
AS
     SELECT COUNT (a.User_name) User_name_count,
            full_name,
            system_person_type,
            user_person_type
       FROM fnd_user a, per_people_x b, per_person_types c
      WHERE     1 = 1                     --nvl(end_date,sysdate+1) >= sysdate
            AND b.person_type_id = 1120
            AND b.person_type_id = c.person_type_id
            AND employee_id = b.person_id
     HAVING COUNT (user_name) > 1
   GROUP BY full_name, system_person_type, user_person_type;
