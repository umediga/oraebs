DROP VIEW APPS.XX_OLM_PERSON_TRNG_DTL_VW;

/* Formatted on 6/6/2016 4:58:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OLM_PERSON_TRNG_DTL_VW
(
   PERSON_TYPE,
   SHORT_PERSON_TYPE,
   EMPLOYEE_NUMBER,
   FIRST_NAME,
   LAST_NAME,
   JOB_NAME,
   EMAIL_ADDRESS,
   POSITION,
   DEPARTMENT,
   ORGANIZATION_ID,
   LOCATION,
   LOCATION_ID,
   ASSIGNMENT_CATEGORY,
   DELEGATE_PERSON_ID,
   SUPERVISOR_NAME,
   SUPERVISOR_EMAIL_ADDRESS,
   SUPERVISOR_EE_NUMBER,
   LEARNER_NAME,
   LEARNER_GROUP_NAME,
   CATEGORY,
   COURSE_NAME,
   ACTIVITY_VERSION_ID,
   COURSE_CODE,
   MANDATORY_ENROLLMENT,
   SELF_ENROLLMENT_FLAG,
   MANDATORY_ENROLLMENT_FLAG,
   ELECTRONIC_SIGNATURE_ENABLED,
   CLASS_NAME,
   OFFERING_NAME,
   OFFERING_LANGUAGE,
   OFFERING_ID,
   EVENT_ID,
   ENROLLMENT_NUMBER,
   ENROLLMENT_DATE,
   ENROLLMENT_DATE_DIS,
   STATUS,
   DURATION,
   TRAINING_CENTER,
   SUCCESSFUL_ATTENDANCE,
   FAILURE_REASON,
   COMPLETION_DATE,
   COMPLETION_DATE_DIS,
   DELIVERY_MODE,
   START_DATE,
   START_DATE_DIS,
   END_DATE,
   END_DATE_DIS,
   START_TIME,
   END_TIME,
   TIMEZONE_NAME,
   SUPPLIED_RESOURCE_ID,
   RESOURSE_NAME,
   RESOURCETYPE,
   LEARNING_PATH_NAME,
   SOURCE,
   LEARNING_PATH_STATUS,
   LEARNING_DUE_DATE,
   LEARNING_DUE_DATE_DIS,
   PROGRESS,
   NO_OF_COURSES_COMPLETED,
   LEARNING_START_DATE,
   CERT_ENROLLMENT_ID,
   CERTIFICATION_NAME,
   CERTIFICATION_STATUS_CODE,
   CERTIFICATION_STATUS_MEANING,
   CERT_PERIOD_START_DATE,
   CERT_PERIOD_END_DATE,
   CERT_PERIOD_END_DATE_DIS,
   CRE_COMPLETION_DATE,
   CRE_COMPLETION_DATE_DIS,
   START_DATE_ACTIVE,
   END_DATE_ACTIVE,
   TRNG_TITLE,
   TRNG_COMPLETION_DATE,
   TRNG_COMPLETION_DATE_DIS,
   CATEGORY_USAGE_ID,
   PARENT_CAT_USAGE_ID,
   TRNG_EQUIVALENT_COURSE,
   DURATION_WITH_UNITS,
   TRNG_COST,
   TRNG_SUPPLIER,
   TRNG_TYPE_MEANING,
   TRNG_STATUS_MEANING,
   TRNG_SCORE,
   TRNG_LEARNER_NAME,
   TRNG_CUST_ORG_NAME,
   TRNG_CONTACT_PERSON
)
AS
   SELECT "PERSON_TYPE",
          "SHORT_PERSON_TYPE",
          "EMPLOYEE_NUMBER",
          "FIRST_NAME",
          "LAST_NAME",
          "JOB_NAME",
          "EMAIL_ADDRESS",
          "POSITION",
          "DEPARTMENT",
          "ORGANIZATION_ID",
          "LOCATION",
          "LOCATION_ID",
          "ASSIGNMENT_CATEGORY",
          "DELEGATE_PERSON_ID",
          "SUPERVISOR_NAME",
          "SUPERVISOR_EMAIL_ADDRESS",
          "SUPERVISOR_EE_NUMBER",
          "LEARNER_NAME",
          "LEARNER_GROUP_NAME",
          "CATEGORY",
          "COURSE_NAME",
          "ACTIVITY_VERSION_ID",
          "COURSE_CODE",
          "MANDATORY_ENROLLMENT",
          "SELF_ENROLLMENT_FLAG",
          "MANDATORY_ENROLLMENT_FLAG",
          "ELECTRONIC_SIGNATURE_ENABLED",
          "CLASS_NAME",
          "OFFERING_NAME",
          "OFFERING_LANGUAGE",
          "OFFERING_ID",
          "EVENT_ID",
          "ENROLLMENT_NUMBER",
          "ENROLLMENT_DATE",
          "ENROLLMENT_DATE_DIS",
          "STATUS",
          "DURATION",
          "TRAINING_CENTER",
          "SUCCESSFUL_ATTENDANCE",
          "FAILURE_REASON",
          "COMPLETION_DATE",
          "COMPLETION_DATE_DIS",
          "DELIVERY_MODE",
          "START_DATE",
          "START_DATE_DIS",
          "END_DATE",
          "END_DATE_DIS",
          "START_TIME",
          "END_TIME",
          "TIMEZONE_NAME",
          "SUPPLIED_RESOURCE_ID",
          "RESOURSE_NAME",
          "RESOURCETYPE",
          "LEARNING_PATH_NAME",
          "SOURCE",
          "LEARNING_PATH_STATUS",
          "LEARNING_DUE_DATE",
          "LEARNING_DUE_DATE_DIS",
          "PROGRESS",
          "NO_OF_COURSES_COMPLETED",
          "LEARNING_START_DATE",
          "CERT_ENROLLMENT_ID",
          "CERTIFICATION_NAME",
          "CERTIFICATION_STATUS_CODE",
          "CERTIFICATION_STATUS_MEANING",
          "CERT_PERIOD_START_DATE",
          "CERT_PERIOD_END_DATE",
          "CERT_PERIOD_END_DATE_DIS",
          "CRE_COMPLETION_DATE",
          "CRE_COMPLETION_DATE_DIS",
          "START_DATE_ACTIVE",
          "END_DATE_ACTIVE",
          "TRNG_TITLE",
          "TRNG_COMPLETION_DATE",
          "TRNG_COMPLETION_DATE_DIS",
          "CATEGORY_USAGE_ID",
          "PARENT_CAT_USAGE_ID",
          "TRNG_EQUIVALENT_COURSE",
          "DURATION_WITH_UNITS",
          "TRNG_COST",
          "TRNG_SUPPLIER",
          "TRNG_TYPE_MEANING",
          "TRNG_STATUS_MEANING",
          "TRNG_SCORE",
          "TRNG_LEARNER_NAME",
          "TRNG_CUST_ORG_NAME",
          "TRNG_CONTACT_PERSON"
     FROM (SELECT ppt.user_person_type person_type,
                  paaf.assignment_type short_person_type,
                  papf.employee_number,
                  papf.first_name,
                  papf.last_name,
                  pjt.NAME job_name,
                  papf.email_address,
                  pap.NAME POSITION,
                  haou.NAME department,
                  haou.organization_id,
                  hl.location_code LOCATION,
                  hl.location_id,
                  (SELECT meaning
                     FROM fnd_lookup_values
                    WHERE     lookup_type = 'EMP_CAT'
                          AND lookup_code = paaf.employment_category
                          AND LANGUAGE(+) = USERENV ('LANG')
                          AND enabled_flag = 'Y')
                     assignment_category,
                  odb.delegate_person_id,
                  papf1.full_name supervisor_name,
                  papf1.email_address supervisor_email_address,
                  papf1.employee_number supervisor_ee_number,
                  ota_utility.get_learner_name (odb.delegate_person_id,
                                                odb.customer_id,
                                                odb.delegate_contact_id)
                     learner_name,
                  --ougvtl.user_group_name
                  NULL learner_group_name,
                  act.CATEGORY,
                  oavtl.version_name course_name,
                  oavtl.activity_version_id,
                  oav.version_code course_code,
                  ota_utility.get_lookup_meaning (
                     'YES_NO',
                     NVL (odb.is_mandatory_enrollment, 'N'),
                     800)
                     mandatory_enrollment,
                  ---oea.self_enrollment_flag, oea.mandatory_enrollment_flag,
                  NULL self_enrollment_flag,
                  NULL mandatory_enrollment_flag,
                  oav.eres_enabled electronic_signature_enabled,
                  oevtl.title class_name,
                  offtl.NAME offering_name,
                  onl.NAME offering_language,
                  OFF.offering_id,
                  oev.event_id,
                  odb.booking_id enrollment_number,
                  TRUNC (odb.date_booking_placed) enrollment_date,
                  TO_CHAR (TRUNC (odb.date_booking_placed), 'DD/MM/YYYY')
                     enrollment_date_dis,
                  ota_lo_utility.get_enroll_lo_status (
                     papf.person_id,
                     paaf.assignment_type,
                     oev.event_id,
                     odb.booking_status_type_id,
                     odb.booking_id,
                     1)
                     status,
                     oev.DURATION
                  || ' '
                  || ota_utility.get_lookup_meaning ('OTA_DURATION_UNITS',
                                                     oev.duration_units,
                                                     '810')
                     DURATION,
                  hao.NAME training_center,
                  ota_utility.get_lookup_meaning (
                     'YES_NO',
                     odb.successful_attendance_flag,
                     '810')
                     successful_attendance,
                  ota_utility.get_lookup_meaning ('DELEGATE_FAILURE_REASON',
                                                  odb.failure_reason,
                                                  '810')
                     failure_reason,
                  ota_lo_utility.get_lo_completion_date (
                     oev.event_id,
                     papf.person_id,
                     paaf.assignment_type)
                     completion_date,
                  DECODE (
                     USERENV ('LANG'),
                     'D', ota_lo_utility.get_lo_completion_date (
                             oev.event_id,
                             papf.person_id,
                             paaf.assignment_type),
                     TO_CHAR (
                        TO_DATE (
                           ota_lo_utility.get_lo_completion_date (
                              oev.event_id,
                              papf.person_id,
                              paaf.assignment_type),
                           'DD-MM-YY HH24:MI:SS'),
                        'DD/MM/YYYY'))
                     completion_date_dis,
                  /*  DECODE
                        (c.synchronous_flag,
                         'Y', (DECODE (c.online_flag,
                                       'Y', 'eStudyScheduled',
                                       'N', 'inClassScheduled'
                                      )
                          ),
                         'N', (DECODE (c.online_flag,
                                       'Y', 'eStudySelfpaced',
                                       'N', 'inClassSelfpaced'
                                      )
                          )
                        ) */
                  c1.CATEGORY AS delivery_mode,
                  oev.course_start_date start_date,
                  TO_CHAR (TRUNC (oev.course_start_date), 'DD/MM/YYYY')
                     start_date_dis,
                  DECODE (
                     oev.course_end_date,
                     TO_DATE ('4712/12/31', 'YYYY/MM/DD'), TO_DATE (NULL),
                     oev.course_end_date)
                     end_date,
                  TO_CHAR (
                     DECODE (
                        oev.course_end_date,
                        TO_DATE ('4712/12/31', 'YYYY/MM/DD'), TO_DATE (NULL),
                        oev.course_end_date),
                     'DD/MM/YYYY')
                     end_date_dis,
                  oev.course_start_time start_time,
                  oev.course_end_time end_time,
                  ftt.NAME timezone_name,
                  osr.supplied_resource_id,
                  osrtl.NAME resourse_name,
                  lkp.meaning resourcetype,
                  --lptl.NAME AS learning_path_name,
                  (SELECT name
                     FROM ota_learning_paths_tl a,
                          OTA_LEARNING_PATH_MEMBERS b
                    WHERE     language = USERENV ('LANG')
                          AND a.learning_path_id = b.learning_path_id
                          AND b.activity_version_id = oev.activity_version_id
                          AND a.learning_path_id = lpe.learning_path_id)
                     learning_path_name,
                  hrlookup.meaning SOURCE,
                  hrlookups.meaning learning_path_status,
                  lpe.completion_target_date learning_due_date,
                  TO_CHAR (TRUNC (lpe.completion_target_date), 'DD/MM/YYYY')
                     learning_due_date_dis,
                  DECODE (
                     NVL (TO_CHAR (completion_target_date, 'YYYY/MM/DD'),
                          '4712/12/31'),
                     '4712/12/31', NULL,
                     DECODE (
                        GREATEST (completion_target_date, TRUNC (SYSDATE)),
                        completion_target_date, (SELECT lkp1.meaning
                                                   FROM hr_lookups lkp1
                                                  WHERE     lkp1.lookup_code =
                                                               'ONSCHED'
                                                        AND lkp1.lookup_type =
                                                               'OTA_LPE_TARGET_PROGRESS'),
                        (SELECT lkp1.meaning
                           FROM hr_lookups lkp1
                          WHERE     lkp1.lookup_code = 'BESCHED'
                                AND lkp1.lookup_type =
                                       'OTA_LPE_TARGET_PROGRESS')))
                     progress,
                  DECODE (
                     NVL (lpe.no_of_mandatory_courses, -1),
                     -1, NULL,
                     ota_lrng_path_util.get_lpe_crse_compl_status_msg (
                        ota_lrng_path_util.get_no_of_mand_compl_courses (
                           lpe.lp_enrollment_id),
                        lpe.no_of_mandatory_courses))
                     no_of_courses_completed,
                  --lp.start_date_active learning_start_date,
                  (SELECT start_date_active
                     FROM ota_learning_paths_vl
                    WHERE learning_path_id = lpe.learning_path_id)
                     learning_start_date,
                  (SELECT cert_enrollment_id
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cert_enrollment_id,
                  --cre.cert_enrollment_id,
                  (SELECT ctl.NAME
                     FROM ota_certifications_tl ctl,
                          ota_certification_members ocm
                    WHERE     ctl.certification_id = crt.certification_id
                          AND ocm.certification_id = ctl.certification_id
                          AND ocm.object_id = oav.activity_version_id
                          AND ctl.LANGUAGE(+) = USERENV ('LANG'))
                     certification_name,
                  /*ota_cpe_util.get_cre_status
                           (cre.cert_enrollment_id,
                            'c'
                           ) certification_status_code, */
                  --cre.certification_status_code certification_status_code,
                  (SELECT certification_status_code
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     certification_status_code,
                  --ota_cpe_util.get_cre_status (cre.cert_enrollment_id,'m') certification_status_meaning,
                  --cre.certification_status_code  certification_status_meaning,
                  (SELECT certification_status_code
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     certification_status_meaning,
                  (SELECT CERT_PERIOD_START_DATE
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cert_period_start_date,
                  --cpe.cert_period_start_date cert_period_start_date,
                  (SELECT CERT_PERIOD_END_DATE
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cert_period_end_date,
                  --cpe.cert_period_end_date cert_period_end_date,
                  (SELECT TO_CHAR (TRUNC (cert_period_end_date),
                                   'DD/MM/YYYY')
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cert_period_end_date_dis,
                  --TO_CHAR (TRUNC (cpe.cert_period_end_date),'DD/MM/YYYY')  cert_period_end_date_dis,
                  (SELECT completion_date
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cre_completion_date,
                  --cre.completion_date cre_completion_date,
                  (SELECT TO_CHAR (TRUNC (completion_date), 'DD/MM/YYYY')
                     FROM OTA_CERT_ENROLLMENTS
                    WHERE     certification_id =
                                 (SELECT ctl.certification_id
                                    FROM ota_certifications_tl ctl,
                                         ota_certification_members ocm
                                   WHERE     ctl.certification_id =
                                                crt.certification_id
                                         AND ocm.certification_id =
                                                ctl.certification_id
                                         AND ocm.object_id =
                                                oav.activity_version_id
                                         AND ctl.LANGUAGE(+) =
                                                USERENV ('LANG'))
                          AND person_id = papf.person_id)
                     cre_completion_date_dis,
                  --TO_CHAR (TRUNC (cre.completion_date), 'DD/MM/YYYY') cre_completion_date_dis,
                  (SELECT START_DATE_ACTIVE
                     FROM ota_certifications_b
                    WHERE certification_id =
                             (SELECT ctl.certification_id
                                FROM ota_certifications_tl ctl,
                                     ota_certification_members ocm
                               WHERE     ctl.certification_id =
                                            crt.certification_id
                                     AND ocm.certification_id =
                                            ctl.certification_id
                                     AND ocm.object_id =
                                            oav.activity_version_id
                                     AND ctl.LANGUAGE(+) = USERENV ('LANG')))
                     start_date_active,
                  --crt.start_date_active,
                  (SELECT end_date_active
                     FROM ota_certifications_b
                    WHERE certification_id =
                             (SELECT ctl.certification_id
                                FROM ota_certifications_tl ctl,
                                     ota_certification_members ocm
                               WHERE     ctl.certification_id =
                                            crt.certification_id
                                     AND ocm.certification_id =
                                            ctl.certification_id
                                     AND ocm.object_id =
                                            oav.activity_version_id
                                     AND ctl.LANGUAGE(+) = USERENV ('LANG')))
                     end_date_active,
                  --crt.end_date_active,
                  ont.trng_title,
                  ont.completion_date trng_completion_date,
                  TO_CHAR (TRUNC (ont.completion_date), 'DD/MM/YYYY')
                     trng_completion_date_dis,
                  act.category_usage_id, --c1.category_usage_id,  Fixed on 27-MAR-2013
                  act.parent_cat_usage_id,                --Added on 28-MAR-13
                  oav1.version_name trng_equivalent_course,
                     ont.DURATION
                  || ' '
                  || hr_general.decode_lookup ('OTA_DURATION_UNITS',
                                               ont.duration_units)
                     duration_with_units,
                  ont.nth_information1 trng_cost,
                  ont.provider trng_supplier,
                  hr_general.decode_lookup ('OTA_TRAINING_TYPES', ont.TYPE)
                     trng_type_meaning,
                  hr_general.decode_lookup ('OTA_TRAINING_STATUSES',
                                            ont.status)
                     trng_status_meaning,
                  ont.rating trng_score,
                  ota_add_training_ss.get_learner_name (ont.person_id,
                                                        ont.organization_id)
                     trng_learner_name,
                  ota_add_training_ss.get_custorg_name (ont.customer_id,
                                                        ont.organization_id)
                     trng_cust_org_name,
                  ota_add_training_ss.get_learner_name (ont.contact_id,
                                                        ont.organization_id)
                     trng_contact_person
             FROM ota_activity_versions_vl oav,
                  ota_activity_versions_tl oavtl,
                  ota_offerings_vl OFF,
                  ota_offerings_tl offtl,
                  ota_events_vl oev,
                  ota_events_tl oevtl,
                  ota_delegate_bookings odb,
                  hr_all_organization_units_vl hao,
                  --ota_category_usages c,          Modified on 29-MAR-13
                  fnd_timezones_tl ftt,
                  ota_resource_bookings orb,
                  ota_suppliable_resources osr,
                  ota_suppliable_resources_tl osrtl,
                  hr_lookups lkp,
                  per_all_people_f papf,
                  per_person_types ppt,
                  Per_person_type_usages_f pptu,          --Added on 29-MAR-13
                  per_all_assignments_f paaf,
                  per_jobs_tl pjt,
                  per_all_positions pap,
                  hr_all_organization_units haou,
                  hr_locations hl,
                  per_all_people_f papf1,
                  ota_lp_enrollments lpe,
                  --ota_learning_paths_vl lp,
                  --ota_learning_paths_tl lptl,
                  hr_lookups hrlookup,
                  hr_lookups hrlookups,
                  ota_cert_enrollments cre,
                  ota_certifications_b crt,
                  --ota_certifications_tl ctl,
                  ota_cert_prd_enrollments cpe,
                  hr_lookups cpe_lkp,
                  ota_notrng_histories ont,
                  ota_activity_versions_tl oav1,
                  /*
                  ota_event_associations oea,
                  ota_user_groups_vl ougv,
                  ota_user_groups_tl ougvtl,
                  */
                  ota_category_usages_tl c1,
                  ota_natural_languages_v onl,
                  ota_act_cat_inclusions aci,
                  ota_category_usages act --ota_category_usages_vl act, Modified on 28-MAR-13
            --ota_category_usages_tl par  Modified on 29-MAR-13
            WHERE     1 = 1
                  AND oev.event_id = odb.event_id
                  AND oevtl.event_id = odb.event_id
                  AND oevtl.LANGUAGE(+) = USERENV ('LANG')
                  AND OFF.offering_id = oev.parent_offering_id
                  AND offtl.offering_id = oev.parent_offering_id
                  AND offtl.LANGUAGE(+) = USERENV ('LANG')
                  AND DECODE (
                         hr_security.view_all,
                         'Y', 'TRUE',
                         hr_security.show_record (
                            'HR_ALL_ORGANIZATION_UNITS',
                            hao.organization_id,
                            'Y')) = 'TRUE'
                  AND DECODE (hr_security.view_all,
                              'Y', 'TRUE',
                              hr_security.show_record (
                                 'PER_ALL_ASSIGNMENTS_F',
                                 paaf.assignment_id,
                                 papf.person_id,
                                 paaf.assignment_type,
                                 'Y')) = 'TRUE'
                  AND oev.activity_version_id = oav.activity_version_id
                  AND oev.activity_version_id = oavtl.activity_version_id
                  AND oavtl.LANGUAGE(+) = USERENV ('LANG')
                  AND oev.training_center_id = hao.organization_id(+)
                  --AND OFF.delivery_mode_id = c.category_usage_id   Modified on 29-MAR-13
                  AND OFF.delivery_mode_id = c1.category_usage_id
                  AND c1.LANGUAGE(+) = USERENV ('LANG')
                  AND ftt.timezone_code = oev.TIMEZONE
                  AND ftt.LANGUAGE = USERENV ('LANG')
                  AND odb.delegate_contact_id IS NULL
                  AND orb.event_id(+) = oev.event_id
                  AND orb.supplied_resource_id = osr.supplied_resource_id(+)
                  AND orb.supplied_resource_id =
                         osrtl.supplied_resource_id(+)
                  AND osrtl.LANGUAGE(+) = USERENV ('LANG')
                  AND lkp.lookup_type(+) = 'RESOURCE_TYPE'
                  AND lkp.lookup_code(+) = osr.resource_type
                  AND SYSDATE BETWEEN papf.effective_start_date
                                  AND papf.effective_end_date
                  AND papf.person_id = odb.delegate_person_id
                  AND SYSDATE BETWEEN pptu.effective_start_date
                                  AND pptu.effective_end_date
                  AND pptu.person_type_id = ppt.person_type_id --Added on 29-MAR-13
                  AND pptu.person_id = papf.person_id
                  --AND papf.person_type_id = ppt.person_type_id    Modified on 29-MAR-13
                  AND papf.business_group_id = ppt.business_group_id
                  AND paaf.job_id = pjt.job_id(+)      --Modified on 29-MAR-13
                  AND pjt.LANGUAGE(+) = USERENV ('LANG')
                  AND ppt.active_flag = 'Y'
                  AND paaf.person_id = odb.delegate_person_id
                  AND SYSDATE BETWEEN paaf.effective_start_date
                                  AND paaf.effective_end_date
                  AND papf.business_group_id = paaf.business_group_id
                  AND paaf.position_id = pap.position_id(+)
                  AND pap.date_end(+) IS NULL
                  AND paaf.business_group_id = pap.business_group_id(+)
                  AND haou.organization_id = paaf.organization_id
                  AND hl.location_id = paaf.location_id
                  AND SYSDATE BETWEEN papf1.effective_start_date(+)
                                  AND papf1.effective_end_date(+)
                  AND papf1.person_id(+) = paaf.supervisor_id
                  AND odb.delegate_person_id = lpe.person_id(+)
                  --AND lp.learning_path_id(+) = lpe.learning_path_id
                  --AND lptl.learning_path_id(+) = lpe.learning_path_id
                  --AND lptl.LANGUAGE(+) = USERENV ('LANG')
                  AND lpe.business_group_id(+) =
                         ota_general.get_business_group_id
                  AND hrlookup.lookup_type(+) = 'OTA_TRAINING_PLAN_SOURCE'
                  AND hrlookups.lookup_type(+) = 'OTA_LEARNING_PATH_STATUS'
                  AND hrlookups.lookup_code(+) = lpe.path_status_code
                  AND hrlookup.lookup_code(+) = lpe.enrollment_source_code
                  AND cre.person_id(+) = odb.delegate_person_id
                  AND crt.certification_id(+) = cre.certification_id
                  AND cre.business_group_id(+) =
                         ota_general.get_business_group_id
                  --AND crt.certification_id = ctl.certification_id(+)
                  --AND ctl.LANGUAGE(+) = USERENV ('LANG')
                  AND cpe_lkp.lookup_code(+) = cpe.period_status_code
                  AND cpe_lkp.lookup_type(+) = 'OTA_CERT_PRD_ENROLL_STATUS'
                  AND cre.cert_enrollment_id = cpe.cert_enrollment_id(+)
                  AND ppt.system_person_type IN ('EMP', 'CWK')
                  AND ont.person_id(+) = odb.delegate_person_id
                  AND ont.activity_version_id = oav1.activity_version_id(+)
                  AND oav1.LANGUAGE(+) = USERENV ('LANG')
                  AND ont.business_group_id(+) =
                         ota_general.get_business_group_id
                  /*
                  AND oea.activity_version_id(+) = oav.activity_version_id
                  AND ougv.user_group_id(+) = oea.user_group_id
                  AND ougvtl.user_group_id(+) = oea.user_group_id
                  AND ougvtl.LANGUAGE(+) = USERENV ('LANG')
                  AND NVL (ougv.user_group_type, 'L') = 'L'
                  AND ougv.business_group_id(+) =
                                                 ota_general.get_business_group_id
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (ougv.start_date_active,
                                                          SYSDATE
                                                         )
                                                    )
                                          AND TRUNC (NVL (ougv.end_date_active,
                                                          SYSDATE + 1
                                                         )
                                                    )
                   */
                  AND onl.language_code = OFF.language_code
                  AND onl.enabled_flag = 'Y'
                  AND aci.activity_version_id = oav.activity_version_id
                  AND act.category_usage_id = aci.category_usage_id
                  --AND act.parent_cat_usage_id = par.category_usage_id  Modified on 29-MAR-13
                  --AND par.LANGUAGE(+) = USERENV ('LANG')               Modified on 29-MAR-13
                  AND act.TYPE = 'C'
                  --AND odb.delegate_person_id = 1199                 -- odb.delegate_person_id
                  AND ota_admin_access_util.admin_can_access_object (
                         'H',
                         oav.activity_version_id) = 'Y'
                  AND ota_admin_access_util.admin_can_access_object (
                         'CLP',
                         lpe.learning_path_id) = 'Y'
                  AND ota_admin_access_util.admin_can_access_object (
                         'CER',
                         crt.certification_id) = 'Y');
