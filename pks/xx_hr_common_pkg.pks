DROP PACKAGE APPS.XX_HR_COMMON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_COMMON_PKG" 
AS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-12
 File Name     : XXHRCOMMON.pks
 Description   : This script creates the body of the package xx_hr_common_pkg

 Change History:

 Date        Name          Remarks
 ----------- -----------   ---------------------------------------
 07-MAR-12   IBM Development    Initial development
 */
--------------------------------------------------------------------------------------
        cn_per_system           CONSTANT VARCHAR2 (200)              := 'PER';
        cn_open_end_date        CONSTANT DATE
                              := TRUNC (TO_DATE ('31-12-4712', 'DD-MM-YYYY'));

        g_employee_pid                   per_all_people_f.person_id%TYPE;
        g_employee_number                per_all_people_f.employee_number%TYPE;
        g_employee_name                  per_all_people_f.full_name%TYPE;
        g_manager_id                     per_all_people_f.person_id%TYPE;
        g_manager_number                 per_all_people_f.employee_number%TYPE;
        g_manager_name                   per_all_people_f.full_name%TYPE;
        --
 -------------------------
        FUNCTION get_active_manager (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN NUMBER;

        FUNCTION get_employee_number (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.employee_number%TYPE;

        FUNCTION get_employee_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.full_name%TYPE;

        FUNCTION get_manager_number (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.employee_number%TYPE;

        FUNCTION get_manager_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN per_all_people_f.full_name%TYPE;

        FUNCTION get_organization_name (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN VARCHAR2;

        FUNCTION get_organization_id (
                p_person_id   IN   per_all_people_f.person_id%TYPE
        )
                RETURN VARCHAR2;

FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_old_value    IN VARCHAR2
                          )   RETURN VARCHAR2 ;
-- used to get the person id of employee / contingent workers
PROCEDURE get_ids(
	          p_first_name            IN           VARCHAR2
		, p_last_name             IN           VARCHAR2
		, p_employee_number       IN           VARCHAR2
		, p_npw_number            IN           VARCHAR2
		, p_business_group_name   IN           VARCHAR2
		, p_person_type           IN           VARCHAR2
		, p_date_of_birth         IN           DATE
		, p_source_prog           IN           VARCHAR2
		, p_person_id             OUT NOCOPY   NUMBER
		, p_party_id              OUT NOCOPY   NUMBER
		, p_error_code            OUT NOCOPY   NUMBER
                 );

END xx_hr_common_pkg;
/
