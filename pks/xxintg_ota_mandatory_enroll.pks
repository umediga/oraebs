DROP PACKAGE APPS.XXINTG_OTA_MANDATORY_ENROLL;

CREATE OR REPLACE PACKAGE APPS."XXINTG_OTA_MANDATORY_ENROLL" AUTHID CURRENT_USER as
/* $Header: XXINTG_otmandatoryenr.pkh 120.3 2008/01/25 11:48:11 shwnayak noship $ */


CURSOR csr_get_person_name(p_person_id NUMBER) IS
    SELECT full_name
    FROM per_all_people_f
    WHERE trunc(sysdate) between effective_start_date and effective_end_date
    AND person_id = p_person_id;

CURSOR get_class_name(p_event_id IN NUMBER) IS
    SELECT title
    FROM OTA_EVENTS_TL
    WHERE event_id = p_event_id
    AND language=userenv('LANG');

CURSOR get_all_mandatory_enr_requests(p_conc_request_id IN NUMBER) IS
    SELECT
    MANDATORY_ENR_REQUEST_ID,
    REQUESTOR_ID,
    EVENT_ID,
    ENR_PREREQ_TYPE,
    PERSON_ID,
    ORGANIZATION_ID,
    ORG_STRUCTURE_VERSION_ID,
    JOB_ID,
    POSITION_ID,
    USERGROUP_ID
    FROM ota_mandatory_enr_requests
    WHERE conc_program_request_id = p_conc_request_id;

CURSOR unprocessed_enrollments is
     SELECT distinct
     evt_tl.event_id event_id,
     evt_tl.title title,
     reqm.person_id person_id,
     reqm.completed_course_prereq completed_course_prereq,
     reqm.completed_competence_prereq completed_competence_prereq,
     reqm.create_enrollment create_enrollment,
     reqm.error_message error_message
     FROM
     ota_mandatory_enr_req_members  reqm,
     ota_events_tl evt_tl
    WHERE
    evt_tl.event_id = reqm.event_id
    AND(reqm.create_enrollment  = 'N' or reqm.error_message IS NOT NULL)
    AND evt_tl.language=userenv('LANG');

FUNCTION learner_can_enroll_in_class(p_event_id IN NUMBER
                                     ,p_learner_id IN NUMBER
                                     )RETURN VARCHAR2;


FUNCTION learner_belongs_to_child_org(p_org_structure_version_id IN ota_event_associations. org_structure_version_id%type,
                                      p_organization_id IN ota_event_associations.organization_id%type,
                                      p_person_id IN per_people_f.person_id%type)
                                      RETURN VARCHAR2;

FUNCTION learner_is_notSelected(p_person_id IN per_all_people_f.person_id%type
                                ,p_assignment_id per_all_assignments_f.assignment_id%type
                                ,p_event_id IN ota_events.event_id%type)
                          RETURN Boolean;

PROCEDURE process_mandatory_event_assoc(ERRBUF OUT NOCOPY  VARCHAR2
                                        ,RETCODE OUT NOCOPY VARCHAR2
                                        ,p_event_id in NUMBER
                                        ,p_person_type in VARCHAR2);


PROCEDURE process_mandatory_enr_requests(p_conc_request_id IN NUMBER,p_person_type in VARCHAR2);

PROCEDURE create_enrollments(p_conc_reqId IN NUMBER);

PROCEDURE notify_mandatory_request(p_person_id in NUMBER,
                                   p_conc_program_request_id in NUMBER,
                                   p_object_type in VARCHAR2,
                                   p_object_id in NUMBER,
                                   p_error_learners in NUMBER,
                                   p_success_learners in NUMBER);


PROCEDURE notify_class_owners(p_conc_reqId IN NUMBER);


END xxintg_ota_mandatory_enroll;
/
