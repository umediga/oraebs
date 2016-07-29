DROP PACKAGE BODY APPS.XX_HR_COMMON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_COMMON_PKG" 
AS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-12
 File Name     : XXHRCOMMON.pkb
 Description   : This script creates the body of the package body xx_hr_common_pkg

 Change History:

 Date        Name          Remarks
 ----------- -----------   ---------------------------------------
 07-MAR-12   IBM Development    Initial development
 */
--------------------------------------------------------------------------------------
        PROCEDURE write_dbg (a VARCHAR2)
        IS
        BEGIN
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, a);
        END write_dbg;


        PROCEDURE derive_manager_details (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
        IS
                CURSOR c_get_employee_number (
                        cp_person_id   per_all_people_f.person_id%TYPE
                )
                IS
                        SELECT   employee_number, GLOBAL_NAME
                            FROM per_all_people_f
                           WHERE person_id = cp_person_id
                             AND employee_number IS NOT NULL
                        ORDER BY effective_start_date DESC;
        BEGIN
                g_employee_pid := p_person_id;
                g_manager_id := get_active_manager (g_employee_pid);

                OPEN c_get_employee_number (g_manager_id);

                FETCH c_get_employee_number
                 INTO g_manager_number, g_manager_name;

                IF c_get_employee_number%ISOPEN
                THEN
                        CLOSE c_get_employee_number;
                END IF;
        END derive_manager_details;

        PROCEDURE derive_employee_details (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
        IS
                CURSOR c_get_employee_number (
                        cp_person_id   per_all_people_f.person_id%TYPE
                )
                IS
                        SELECT   employee_number, GLOBAL_NAME
                            FROM per_all_people_f
                           WHERE person_id = cp_person_id
                             AND employee_number IS NOT NULL
                        ORDER BY effective_start_date DESC;
        BEGIN
                g_employee_pid := p_person_id;

                OPEN c_get_employee_number (g_employee_pid);

                FETCH c_get_employee_number
                 INTO g_employee_number, g_employee_name;

                IF c_get_employee_number%ISOPEN
                THEN
                        CLOSE c_get_employee_number;
                END IF;
        END derive_employee_details;

--------------- END OF LOCAL FUNCTIONS ---------------------------------------
        FUNCTION get_active_manager (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN NUMBER
        IS
                l_person_id               per_all_people_f.person_id%TYPE;
                l_supervisor_id           per_all_people_f.person_id%TYPE;
                l_supervisor_id_new       per_all_people_f.person_id%TYPE;
                l_supervisor_user_name1   fnd_user.user_name%TYPE;
                l_supervisor_new_name1    per_people_f.full_name%TYPE;
                l_manager_level_01        per_people_f.person_id%TYPE;
                l_process_flag            BOOLEAN;
                x_return_value            NUMBER;

                CURSOR sup_cur (p_person_id per_all_people_f.person_id%TYPE)
                IS
                        SELECT     supervisor_id, job_id job_id,
                                   LEVEL mgr_level_up,
                                   assignment_status_type_id
                              FROM per_all_assignments_f
                        START WITH person_id = p_person_id
                               AND TRUNC ( SYSDATE) BETWEEN effective_start_date
                                                        AND effective_end_date
                        CONNECT BY PRIOR supervisor_id = person_id
                               AND TRUNC ( SYSDATE) BETWEEN effective_start_date
                                                        AND effective_end_date;

                CURSOR mgr_active (
                        p_supervisor_id   per_all_people_f.person_id%TYPE
                )
                IS
                        SELECT paaf.person_id
                          FROM per_all_assignments_f paaf,
                               per_person_types ppt,
                               per_person_type_usages_f pptu
                         WHERE TRUNC ( SYSDATE)
                                       BETWEEN paaf.effective_start_date
                                           AND paaf.effective_end_date
                           AND TRUNC ( SYSDATE)
                                       BETWEEN pptu.effective_start_date
                                           AND pptu.effective_end_date
                           AND pptu.person_type_id = ppt.person_type_id
                           AND paaf.person_id = pptu.person_id
                           AND ppt.person_type_id = pptu.person_type_id
                           AND UPPER ( ppt.user_person_type) NOT LIKE ('EX%')
                           AND UPPER ( ppt.user_person_type) NOT LIKE
                                                                     ('END%'
                                                                     )
                           AND UPPER ( ppt.user_person_type) NOT LIKE
                                                                ('INACTIVE%'
                                                                )
                           AND paaf.primary_flag = 'Y'
                           AND paaf.person_id = p_supervisor_id;

                CURSOR mgr_active1 (
                        p_supervisor_id   per_all_people_f.person_id%TYPE
                )
                IS
                        SELECT paaf.person_id
                          FROM per_all_assignments_f paaf,
                               per_person_types ppt,
                               per_person_type_usages_f pptu
                         WHERE TRUNC ( SYSDATE)
                                       BETWEEN paaf.effective_start_date
                                           AND paaf.effective_end_date
                           AND TRUNC ( SYSDATE)
                                       BETWEEN pptu.effective_start_date
                                           AND pptu.effective_end_date
                           AND pptu.person_type_id = ppt.person_type_id
                           AND paaf.person_id = pptu.person_id
                           --AND   pptu.object_version_number = (select min(a.object_version_number) from per_person_type_usages_f a
                           --                                    where a.person_id = paaf.person_id)
                           AND ppt.person_type_id = pptu.person_type_id
                           AND UPPER ( ppt.user_person_type) NOT LIKE ('EX%')
                           AND UPPER ( ppt.user_person_type) NOT LIKE
                                                                     ('END%'
                                                                     )
                           AND UPPER ( ppt.user_person_type) NOT LIKE
                                                                ('INACTIVE%'
                                                                )
                           AND paaf.primary_flag = 'Y'
                           AND paaf.person_id = p_supervisor_id;
        BEGIN
                l_person_id := p_person_id;

                      /*
                      OPEN mgr_active(l_person_id);
                      FETCH mgr_active INTO l_manager_level_01;

                      IF mgr_active%NOTFOUND THEN

                          IF l_person_id IS NOT NULL THEN
                */
                FOR sup_rec IN sup_cur (l_person_id)
                LOOP
                        OPEN mgr_active1 (sup_rec.supervisor_id);

                        FETCH mgr_active1
                         INTO l_manager_level_01;

                        IF mgr_active1%FOUND
                        THEN
                                IF l_supervisor_id_new IS NULL
                                THEN
                                        l_supervisor_id_new :=
                                                           l_manager_level_01;
                                END IF;
                        END IF;

                        CLOSE mgr_active1;
                END LOOP;

                x_return_value := l_supervisor_id_new;
/*
           END IF;
      ELSE
           x_return_value:= l_person_id;

      END IF;
      CLOSE mgr_active;
*/
                RETURN x_return_value;
        END get_active_manager;

        FUNCTION get_employee_number (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.employee_number%TYPE
        IS
        BEGIN
                IF    NVL (   p_person_id, 0) <> NVL (  g_employee_pid, 0)
                   OR g_employee_number IS NULL
                THEN
                        derive_employee_details (p_person_id);
                END IF;

                RETURN g_employee_number;
        END get_employee_number;

        FUNCTION get_employee_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.full_name%TYPE
        IS
        BEGIN
                IF    NVL (   p_person_id, 0) <> NVL (  g_employee_pid, 0)
                   OR g_employee_name IS NULL
                THEN
                        derive_employee_details (p_person_id);
                END IF;

                RETURN g_employee_name;
        END get_employee_name;

        FUNCTION get_manager_number (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.employee_number%TYPE
        IS
        BEGIN
                IF    NVL (   p_person_id, 0) <> NVL (  g_employee_pid, 0)
                   OR g_manager_number IS NULL
                THEN
                        derive_manager_details (p_person_id);
                END IF;

                RETURN g_manager_number;
        END get_manager_number;

        FUNCTION get_manager_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.full_name%TYPE
        IS
        BEGIN
                IF    NVL (   p_person_id, 0) <> NVL (  g_employee_pid, 0)
                   OR g_manager_name IS NULL
                THEN
                        derive_manager_details (p_person_id);
                END IF;

                RETURN g_manager_name;
        END get_manager_name;

        FUNCTION get_organization_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN VARCHAR2
        IS
                CURSOR c_get_org_name
                IS
                        SELECT otl.NAME
                          FROM hr_all_organization_units o,
                               apps.hr_all_organization_units_tl otl
                         WHERE o.organization_id = otl.organization_id
                           AND o.organization_id IN (
                                       SELECT organization_id
                                         FROM per_all_assignments_f
                                        WHERE person_id = p_person_id
                                          AND TRUNC ( SYSDATE)
                                                      BETWEEN TRUNC
                                                                     (effective_start_date
                                                                     )
                                                          AND TRUNC
                                                                     (effective_end_date
                                                                     ));

                x_return_value   VARCHAR2 (2000);
        BEGIN
                OPEN c_get_org_name;

                FETCH c_get_org_name
                 INTO x_return_value;

                CLOSE c_get_org_name;

                RETURN x_return_value;
        EXCEPTION
                WHEN OTHERS
                THEN
                        RETURN NULL;
        END get_organization_name;

        FUNCTION get_organization_id (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN VARCHAR2
        IS
                CURSOR c_get_org_id
                IS
                        SELECT otl.organization_id
                          FROM hr_all_organization_units o,
                               apps.hr_all_organization_units_tl otl
                         WHERE o.organization_id = otl.organization_id
                           AND o.organization_id IN (
                                       SELECT organization_id
                                         FROM per_all_assignments_f
                                        WHERE person_id = p_person_id
                                          AND TRUNC ( SYSDATE)
                                                      BETWEEN TRUNC
                                                                     (effective_start_date
                                                                     )
                                                          AND TRUNC
                                                                     (effective_end_date
                                                                     ));

                x_return_value   NUMBER;
        BEGIN
                OPEN c_get_org_id;

                FETCH c_get_org_id
                 INTO x_return_value;

                CLOSE c_get_org_id;

                RETURN x_return_value;
        EXCEPTION
                WHEN OTHERS
                THEN
                        RETURN NULL;
        END get_organization_id;


FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_old_value    IN VARCHAR2
                          )   RETURN VARCHAR2 AS
---------------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-12
 File Name     : XXHRMAPING.fn
 Description   : This script creates the standalone function GET_MAPPING_VALUE
                 This function will be used widely from various Person/ employee conversion packages

 Change History:
 Date           Name               Remarks
------------   ---------------     -----------------------------------
07-MAR-12      IBM Development    Initial development
*/
----------------------------------------------------------------------------------------------

   x_new_value   VARCHAR2 (200);

BEGIN
   SELECT DISTINCT new_value1
     INTO x_new_value
     FROM xx_hr_mapping
    WHERE mapping_type = p_mapping_type
      AND old_value1    = p_old_value
      AND ROWNUM       = 1;

   RETURN x_new_value;

EXCEPTION
   WHEN NO_DATA_FOUND   THEN
      RETURN p_old_value;
   WHEN OTHERS   THEN
      RETURN p_old_value;

END GET_MAPPING_VALUE;

PROCEDURE get_ids(    p_first_name            IN           VARCHAR2
                    , p_last_name             IN           VARCHAR2
                    , p_employee_number       IN           VARCHAR2-- unique_id value is passed to p_employee_number to fetch the ids.
                    , p_npw_number            IN           VARCHAR2-- p_npw_number is not used. unique id will be passed in p_employee_number
                    , p_business_group_name   IN           VARCHAR2
		    , p_person_type           IN           VARCHAR2
                    , p_date_of_birth         IN           DATE
                    , p_source_prog           IN           VARCHAR2
                    , p_person_id             OUT NOCOPY   NUMBER
                    , p_party_id              OUT NOCOPY   NUMBER
                    , p_error_code            OUT NOCOPY   NUMBER
                   )


   AS

    x_error_code           NUMBER        := xx_emf_cn_pkg.cn_success;

  CURSOR c_hr_ids( p_business_group_name  IN   VARCHAR2,
                   p_npw_number          IN   VARCHAR2,
                   p_first_name          IN   VARCHAR2,
                   p_last_name           IN   VARCHAR2,
                   p_employee_number     IN   VARCHAR2,
                   p_date_of_birth       IN   DATE,
                   p_person_type         IN   VARCHAR2
                  ) IS
       SELECT ppf.person_id,
                     ppf.party_id
                FROM per_all_people_f ppf
                     ,per_business_groups pbg
                     ,per_person_types ppt
                 where PPF.BUSINESS_GROUP_ID = PBG.BUSINESS_GROUP_ID
                   and (P_BUSINESS_GROUP_NAME is null or UPPER(PBG.name)= UPPER(P_BUSINESS_GROUP_NAME))--UPPER (XX_HR_COMMON_PKG.GET_MAPPING_VALUE ('BUSINESS_GROUP',P_BUSINESS_GROUP_NAME)))
                   AND (p_employee_number IS NULL OR ppf.attribute1 = TO_CHAR(p_employee_number))-- Modified for Integra
                   AND ppt.user_person_type = NVL(p_person_type,ppt.user_person_type)
                   AND ppt.person_type_id = ppf.person_type_id
            AND trunc(sysdate) BETWEEN ppf.effective_start_date AND ppf.effective_end_date;
  BEGIN
     p_person_id := NULL;
     p_party_id  := NULL;
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'    p_employee_number '|| p_employee_number||' FName '||p_first_name||' Lname '||p_last_name);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'    p_npw_number '|| p_npw_number);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'    p_business_group_name '|| p_business_group_name||' p_date_of_birth '||p_date_of_birth);


     FOR c_hr_ids_rec IN c_hr_ids( p_business_group_name,
                                   p_npw_number,
     				   p_first_name,
                                   p_last_name,
                                   p_employee_number,
                                   p_date_of_birth,
                                   p_person_type
                                  )
     LOOP
      p_person_id := c_hr_ids_rec.person_id;
      p_party_id  := c_hr_ids_rec.party_id;
     END LOOP;

        IF (p_party_id IS NULL and p_person_id IS NULL) THEN

             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Person id and Party ID could not be fetched');
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                              ,p_category            => xx_emf_cn_pkg.cn_valid
                              ,P_ERROR_TEXT          => 'Person ID not found For '||P_SOURCE_PROG
			      ,P_RECORD_IDENTIFIER_1 => '            '-- Spaces because employee number is not being passed here
			      ,P_RECORD_IDENTIFIER_2 => P_EMPLOYEE_NUMBER   -- unique id
			      ,p_record_identifier_3 => (p_first_name||' '||p_last_name)
                               );
        ELSIF x_error_code = xx_emf_cn_pkg.cn_success THEN

             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Name: '||p_last_name||', '||p_first_name||' Date Of Birth '||p_date_of_birth);
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Person id '|| p_person_id||' Party ID '|| p_party_id);

       END IF;
     p_error_code := x_error_code;
  END get_ids;

END xx_hr_common_pkg;
/
