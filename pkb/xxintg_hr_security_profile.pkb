DROP PACKAGE BODY APPS.XXINTG_HR_SECURITY_PROFILE;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_HR_SECURITY_PROFILE" 
AS
----------------------------------------------------------------------
/*
 Created By    : Kirthana Ramesh
 Creation Date : 25-JAN-2013
 File Name     : XXINTG_HR_SECURITY_PROFILE.pkb
 Description   : This script creates the body of the package
                XXINTG_HR_SECURITY_PROFILE which is used to build the
                custom HR Security framework for Integra
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 25-JAN-2013   Kirthana Ramesh       Initial Development
 18-Apr-2013   Vishal Rathore        Case # 2533. Changed all assignment type = 'E'
                                     to in('C', 'E')
 10-Jun-2013   Kirthana Ramesh       Modified queries to optimize performance.
 11-Jun-2013   Renjith               Optimize queries
 04-Nov-2013   Francis               Code has been modifed for ticket-3088
*/
----------------------------------------------------------------------
   FUNCTION xxintg_is_hr_person (p_person_id IN NUMBER)
      RETURN VARCHAR2
   IS
----------------------------------------------------------------------
/*
 Created By    : Kirthana Ramesh
 Creation Date : 25-JAN-2013
 Function Name  : xxintg_is_hr_person
 Description   : This function is used to determine if the record that
                 needs to be displayed belongs to an HR Person
                 i.e. a person who has been defined in the system as
                 one or more of the following
                 - HR Level 1 / HR Level 2 for a position
                 - HR Divisional Manager for a roll-up organization
                 - HR Admin for a location
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 25-JAN-2013   Kirthana Ramesh       Initial Development
*/
----------------------------------------------------------------------
      x_hr_person    VARCHAR2 (1) := 'N';
      x_position_id   VARCHAR2 (240) := NULL;
   BEGIN
/*   This code has been commented as per ticket-3088

     BEGIN
	SELECT paaf.position_id
	  INTO x_position_id
	  FROM per_all_assignments_f paaf
	 WHERE paaf.primary_flag = 'Y'
	   AND paaf.assignment_type IN ('C', 'E')
	   AND SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
	   AND paaf.person_id = p_person_id;
     EXCEPTION
            WHEN OTHERS
            THEN
               x_hr_person := 'N';
      END;

--Checking if HR Level1 or HR Level2
      BEGIN
         SELECT 'Y'
           INTO x_hr_person
           FROM DUAL
          WHERE EXISTS (
                   SELECT 1
                     FROM hr_all_positions_f hpos1
                    WHERE hpos1.attribute5 = x_position_id
                      AND SYSDATE BETWEEN hpos1.effective_start_date AND hpos1.effective_end_date
                   UNION ALL
                   SELECT 1
                     FROM hr_all_positions_f hpos1
                    WHERE hpos1.attribute6 = x_position_id
                      AND SYSDATE BETWEEN hpos1.effective_start_date AND hpos1.effective_end_date
);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_hr_person := 'N';
      END;

      IF x_hr_person = 'N'
      THEN
         --Checking if HR Divisional Manager
         BEGIN
            SELECT 'Y'
              INTO x_hr_person
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM hr_organization_information hoi
                       WHERE hoi.org_information_context = 'Organization Name Alias'
                         AND SYSDATE BETWEEN NVL (TO_DATE (hoi.org_information3,'RRRR/MM/DD HH24:MI:SS'),SYSDATE - 1)
                                    AND NVL (TO_DATE (hoi.org_information4,'RRRR/MM/DD HH24:MI:SS'),SYSDATE + 1)
                         AND hoi.org_information2 = p_person_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_hr_person := 'N';
         END;

         IF x_hr_person = 'N'
         THEN
            --Checking if HR Admin
            BEGIN
               SELECT 'Y'
                 INTO x_hr_person
                 FROM DUAL
                WHERE EXISTS (
                         SELECT  1
                           FROM  hr_location_extra_info hlei
                          WHERE hlei.information_type         = 'HRAdmin_Locations'
                            AND hlei.lei_information_category = 'HRAdmin_Locations'
                            AND hlei.lei_information1 = x_position_id
                            );
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_hr_person := 'N';
            END;
         ELSE
            RETURN x_hr_person;
         END IF;
      ELSE
         RETURN x_hr_person;
      END IF;

      RETURN x_hr_person;
This code has been commented as per ticket-3088
*/
--The following code has been added for ticket-3088
BEGIN

SELECT 'Y' INTO x_hr_person
FROM DUAL
WHERE EXISTS
(SELECT ass.person_id
FROM per_all_assignments_f ass,
hr_all_organization_units org,
pay_cost_allocation_keyflex pay
WHERE ass.organization_id = org.organization_id
AND pay.cost_allocation_keyflex_id = org.cost_allocation_keyflex_id
And pay.segment2='1201'
AND pay.enabled_flag='Y'
AND trunc(sysdate)  BETWEEN trunc(NVL(pay.START_DATE_ACTIVE,sysdate))
AND trunc(nvl(pay.END_DATE_ACTIVE,sysdate))
AND trunc(x_effective_date) BETWEEN trunc(NVL(ass.effective_start_date,sysdate))
AND trunc(NVL(ass.effective_end_date,sysdate))
AND ass.person_id=p_person_id
);
--Code Ends for ticket-3088
EXCEPTION
               WHEN OTHERS
               THEN
                  x_hr_person := 'N';
            END;

RETURN x_hr_person;

   EXCEPTION
      WHEN OTHERS
      then
         /*DBMS_OUTPUT.put_line
            (   'Exception encountered in function xxintg_is_hr_person due to '
             || SQLERRM
            );*/
         RETURN 'N';
   END xxintg_is_hr_person;

   FUNCTION xxintg_is_subordinate (p_person_id IN NUMBER)
      RETURN VARCHAR2
   IS
----------------------------------------------------------------------
/*
 Created By    : Kirthana Ramesh
 Creation Date : 25-JAN-2013
 Function Name  : xxintg_is_subordinate
 Description   : This function is used to check if the record that
                 needs to be displayed belongs to an HR person, and
                 if so, whether that person is a subordinate in the
                 supervisor hierarchy of the person who has logged in.
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 25-JAN-2013   Kirthana Ramesh       Initial Development
*/
----------------------------------------------------------------------
      x_login_person_id   NUMBER       := NULL;
      x_hr_person         VARCHAR2 (1) := NULL;
      x_subordinate       VARCHAR2 (1) := NULL;
   BEGIN
      x_hr_person := xxintg_is_hr_person (p_person_id);

      IF NVL (x_hr_person, 'N') = 'Y'
      THEN
         --Checking if the person is a subordinate in the supervisor hierarchy of the person who has logged in
         BEGIN
            SELECT 'Y'
              INTO x_subordinate
              FROM DUAL
             WHERE p_person_id IN (
                          SELECT person_id
                            FROM per_all_assignments_f
                           WHERE LEVEL > 1
                      START WITH person_id = FND_GLOBAL.employee_id
                             AND trunc(x_effective_date) BETWEEN trunc(effective_start_date) AND trunc(effective_end_date)
                             AND primary_flag = 'Y'
                             AND assignment_type IN ('C', 'E')
                      CONNECT BY PRIOR person_id = supervisor_id
                             AND trunc(x_effective_date) BETWEEN trunc(effective_start_date) AND trunc(effective_end_date)
                             AND primary_flag = 'Y'
                             AND assignment_type IN ('C', 'E'));
         EXCEPTION
            WHEN OTHERS
            THEN
               x_subordinate := 'N';
         END;
      ELSE
         x_subordinate := 'Y';
      END IF;

      RETURN x_subordinate;
   EXCEPTION
      WHEN OTHERS
      then
         /*DBMS_OUTPUT.put_line
            (   'Exception encountered in function xxintg_is_subordinate due to '
             || SQLERRM
            );*/
         RETURN 'N';
   END xxintg_is_subordinate;

   FUNCTION xxintg_is_record_allowed (p_person_id IN NUMBER)
      RETURN VARCHAR2
   IS
------------------------------------------------------------------------------------------------------------
/*
 Created By    : Kirthana Ramesh
 Creation Date : 25-JAN-2013
 Function Name  : xxintg_is_record_allowed
 Description   : This is the main function that is called from the Custom Security profile setup.
                It determines all the records that should be visible to an HR Person based on Position,
                Roll-up organization and Location. In addition it also applies Peer Security logic to restrict
                records as per the business requirement. If all conditions are met, it returns 'TRUE',
                else it returns 'FALSE'.
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 25-JAN-2013   Kirthana Ramesh       Initial Development
*/
-------------------------------------------------------------------------------------------------------------
      X_IS_RECORD_ALLOWED   VARCHAR2 (1) := NULL;
      X_LOGIN_PERSON_ID   number       ; -- added for  Case # 2533
       X_POSITION_ID        number := null;
         X_LOCATION_ID        number := null;
      X_ORGANIZATION_ID     number := null;
      x_record_status number ;
   begin
--The following code has been added for ticket-3088
BEGIN
SELECT effective_date
INTO x_effective_date
FROM FND_SESSIONS
WHERE session_id = (select userenv('SESSIONID') from dual);
EXCEPTION
               WHEN OTHERS
               THEN
x_effective_date:=SYSDATE;
END;
--Code Ends for ticket-3088

      X_LOGIN_PERSON_ID          := FND_GLOBAL.EMPLOYEE_ID;
      -- begin added for  Case # 2533
      IF p_person_id = x_login_person_id
      then
         RETURN 'TRUE';
      END IF;
            -- end added for  Case # 2533
     x_record_status := 0;
      SELECT paaf.position_id,
	       PAAF.ORGANIZATION_ID,
         location_id
	  INTO x_position_id,
	       X_ORGANIZATION_ID,
         X_LOCATION_ID
	  FROM per_all_assignments_f paaf
	 WHERE paaf.primary_flag = 'Y'
	   AND paaf.assignment_type IN ('C', 'E')
	   and trunc(x_effective_date) between trunc(PAAF.EFFECTIVE_START_DATE) and trunc(PAAF.EFFECTIVE_END_DATE)
	   AND paaf.person_id = p_person_id;



      SELECT decode(count(1),0,0,1)
        INTO x_record_status
        FROM DUAL
       where exists (
                  SELECT  1
                          FROM  hr_all_positions_f hpos
                               ,per_all_assignments_f paaf_hr_rep
                         WHERE hpos.position_id=x_position_id
                           AND trunc(sysdate) BETWEEN trunc(hpos.effective_start_date) AND trunc(hpos.effective_end_date)
                           AND paaf_hr_rep.person_id = X_LOGIN_PERSON_ID
                           AND paaf_hr_rep.primary_flag = 'Y'
                           AND paaf_hr_rep.assignment_type IN ('C', 'E')
                           and trunc(x_effective_date) between trunc(PAAF_HR_REP.EFFECTIVE_START_DATE) and trunc(PAAF_HR_REP.EFFECTIVE_END_DATE)
                           and HPOS.ATTRIBUTE5 = PAAF_HR_REP.POSITION_ID);


      if X_RECORD_STATUS = 0 then

       SELECT decode(count(1),0,0,1)
        INTO x_record_status
        FROM DUAL
       where exists (SELECT  1
                          FROM  hr_all_positions_f hpos
                               ,per_all_assignments_f paaf_hr_rep
                         WHERE hpos.position_id=x_position_id
                           AND trunc(sysdate) BETWEEN trunc(hpos.effective_start_date) AND trunc(hpos.effective_end_date)
                           AND paaf_hr_rep.person_id = X_LOGIN_PERSON_ID
                           AND paaf_hr_rep.primary_flag = 'Y'
                           AND paaf_hr_rep.assignment_type IN ('C', 'E')
                           and trunc(x_effective_date) between trunc(PAAF_HR_REP.EFFECTIVE_START_DATE) and trunc(PAAF_HR_REP.EFFECTIVE_END_DATE)
                           and HPOS.ATTRIBUTE6 = PAAF_HR_REP.POSITION_ID);
      end if;

      if X_RECORD_STATUS = 0 then

      SELECT  decode(count(1),0,0,1) into x_record_status
                          FROM  DUAL
                         WHERE x_organization_id IN (
                                      SELECT t.organization_id_child
                                        FROM (SELECT pose.organization_id_parent
                                                    ,pose.organization_id_child
                                                FROM per_org_structure_elements pose,
                                                     per_organization_structures pos
                                               WHERE pose.org_structure_version_id = pos.organization_structure_id
                                                 AND pos.primary_structure_flag = 'Y') t
                                       WHERE CONNECT_BY_ISLEAF = 1
                                  START WITH t.organization_id_parent IN (
                                                SELECT  hoi.organization_id
                                                  FROM  hr_organization_information hoi
                                                       ,hr_all_organization_units haou
                                                 WHERE hoi.org_information_context = 'Organization Name Alias'
                                                   AND hoi.organization_id  = haou.organization_id
                                                   AND hoi.org_information2 =X_LOGIN_PERSON_ID
                                                   AND SYSDATE BETWEEN NVL(TO_DATE(hoi.org_information3,'RRRR/MM/DD HH24:MI:SS'),SYSDATE - 1)
                                                                   AND NVL(TO_DATE(hoi.org_information4,'RRRR/MM/DD HH24:MI:SS'),SYSDATE + 1)
                                                   )
                                  CONNECT BY PRIOR t.organization_id_child = T.ORGANIZATION_ID_PARENT);
      end if;

        if X_RECORD_STATUS = 0 then

      select  DECODE(COUNT(1),0,0,1) into X_RECORD_STATUS
                          FROM  hr_location_extra_info hlei
                               ,per_all_assignments_f paaf_hr_admin
                         WHERE hlei.location_id = X_LOCATION_ID
                           AND hlei.information_type         = 'HRAdmin_Locations'
                           AND hlei.lei_information_category = 'HRAdmin_Locations'
                           AND hlei.lei_information1         =  paaf_hr_admin.position_id
                           AND paaf_hr_admin.primary_flag = 'Y'
                           AND paaf_hr_admin.assignment_type IN ('C', 'E')
                           and trunc(x_effective_date) between trunc(PAAF_HR_ADMIN.EFFECTIVE_START_DATE) and trunc(PAAF_HR_ADMIN.EFFECTIVE_END_DATE)
                           AND paaf_hr_admin.person_id = X_LOGIN_PERSON_ID;
      end if;

      if X_RECORD_STATUS = 1 and XXINTG_IS_SUBORDINATE (P_PERSON_ID) = 'Y'
      then
        return 'TRUE';
      else
       RETURN 'FALSE';
      end if;

   EXCEPTION
      WHEN OTHERS
      then
         /*DBMS_OUTPUT.put_line
            (   'Exception encountered in function xxintg_is_record_allowed due to '
             || SQLERRM
            );*/
         RETURN 'FALSE';
   END xxintg_is_record_allowed;
end XXINTG_HR_SECURITY_PROFILE;
/
