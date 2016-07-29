DROP PACKAGE BODY APPS.XXINTG_OTA_MANDATORY_ENROLL;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_OTA_MANDATORY_ENROLL" as
/* $Header: XXINTG_otmandatoryenr.pkb 120.4.12010000.3 2011/04/07 14:36:49 shwnayak ship $ */


g_package  varchar2(33) := 'xxintg_ota_mandatory_enroll.';  -- Global package name



PROCEDURE process_mandatory_event_assoc( ERRBUF OUT NOCOPY  VARCHAR2,
                                         RETCODE OUT NOCOPY VARCHAR2,
                                         p_event_id IN NUMBER,
                                         p_person_type in VARCHAR2) IS   -- p_person_type parameter added for Integra's requirement


 TYPE mandatory_event_assoc_rec IS RECORD(
      enr_prereq_type dbms_sql.varchar2_table,
    event_id dbms_sql.number_table,
    person_id dbms_sql.number_table,
    organization_id dbms_sql.number_table,
    job_id dbms_sql.number_table,
    position_id dbms_sql.varchar2_table,
    org_structure_version_id dbms_sql.number_table,
    user_group_id dbms_sql.number_table,
    requestor_id dbms_sql.number_table
    );

  l_rec mandatory_event_assoc_rec;
  l_date ota_events.course_end_date%type;
  l_conc_request_id ota_mandatory_enr_requests.conc_program_request_id%type;
  l_event_title ota_events_tl.title%type;
  l_person_type VARCHAR2(100); -- Added for Integra's requirement
  l_proc  varchar2(72) := g_package||'process_mandatory_event_assoc';


BEGIN
    l_person_type := p_person_type; -- Added for Integra's requirement
    l_conc_request_id := FND_GLOBAL.conc_request_id;
    hr_utility.set_location(' Entering:'||l_proc, 5);

    if p_event_id is NULL then
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Mandatory Enrollments are being processed for all classes');
    ELSE
    OPEN get_class_name(p_event_id);
    FETCH get_class_name into l_event_title;
    CLOSE get_class_name;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Mandatory Enrollments are being processed for Class -' || l_event_title);
    END IF;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request Id : ' || FND_GLOBAL.conc_request_id);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Start time is - '||TO_CHAR(SYSTIMESTAMP));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');

  SELECT
    oea.MANDATORY_ENROLLMENT_PREREQ enr_prereq_type,
    oea.EVENT_ID event_id,
    oea.PERSON_ID  person_id,
    oea.ORGANIZATION_ID organization_id,
    oea.JOB_ID job_id,
    oea.POSITION_ID position_id,
    oea.ORG_STRUCTURE_VERSION_ID org_structure_version_id,
    oea.USER_GROUP_ID user_group_id,
    evt.OWNER_ID requestor_id
  BULK COLLECT INTO
    l_rec.enr_prereq_type,l_rec.event_id,l_rec.person_id,l_rec.organization_id,l_rec.job_id,l_rec.position_id,
    l_rec.org_structure_version_id,l_rec.user_group_id,l_rec.requestor_id
           FROM
            ota_event_associations  oea ,
            ota_events evt
            WHERE oea.event_id = evt.event_id
            AND  oea.MANDATORY_ENROLLMENT_FLAG = 'Y'
            AND ota_timezone_util.convert_date(trunc(sysdate),to_char(sysdate,'HH24:MI'), ota_timezone_util.get_server_timezone_code , evt.timezone)
               BETWEEN decode(evt.enrolment_start_date, NULL, to_date('0001/01/01','YYYY/MM/DD'),
                           to_date( to_char(evt.enrolment_start_date, 'YYYY/MM/DD') || ' ' || '00:00', 'YYYY/MM/DD HH24:MI'))
               AND decode(evt.enrolment_end_date, NULL, to_date('4712/12/31','YYYY/MM/DD'),
                           to_date( to_char(evt.enrolment_end_date, 'YYYY/MM/DD') || ' ' || '23:59', 'YYYY/MM/DD HH24:MI'))
           AND evt.event_status IN ('P','N')
           AND nvl(p_event_id,-1)= decode(p_event_id,NULL,-1,evt.EVENT_ID)
           AND evt.business_group_id = OTA_GENERAL.get_business_group_id
           --AND oea.person_id=1231 -- added for testing
     ORDER BY evt.event_id;

 FORALL i IN 1 .. l_rec.event_id.COUNT

  INSERT INTO ota_mandatory_enr_requests(
    MANDATORY_ENR_REQUEST_ID ,
    REQUESTOR_ID,
    EVENT_ID,
    ENR_PREREQ_TYPE,
    PERSON_ID,
    ORGANIZATION_ID,
    ORG_STRUCTURE_VERSION_ID,
    JOB_ID,
    POSITION_ID,
    USERGROUP_ID,
    CONC_PROGRAM_REQUEST_ID,
    CREATION_DATE)
    VALUES(OTA_MANDATORY_ENR_REQUESTS_S.NEXTVAL,
    l_rec.requestor_id(i),
    l_rec.event_id(i),
    l_rec.enr_prereq_type(i),
    l_rec.person_id(i),
    l_rec.organization_id(i),
    l_rec.org_structure_version_id(i),
    l_rec.job_id(i),
    l_rec.position_id(i),
    l_rec.user_group_id(i),
    l_conc_request_id,
    sysdate);

    COMMIT;


  process_mandatory_enr_requests(l_conc_request_id,l_person_type);  -- l_person_type parameter added for Integra's requirement


 -- FND_FILE.PUT_LINE(FND_FILE.LOG,'End time is - '||TO_CHAR(SYSTIMESTAMP));
  hr_utility.set_location(' Leaving:'||l_proc, 10);

END process_mandatory_event_assoc;


FUNCTION learner_can_enroll_in_class(p_event_id IN NUMBER
                                     ,p_learner_id IN NUMBER)
                                   RETURN varchar2 IS

 CURSOR get_learner_class_enr_status IS
     SELECT bst.type status_code,
              btt.name Status,
              bst.booking_status_type_id  status_id,
              decode(bst.type, 'C', 0,'R',1, 'W',2, 'P',3,'E',4, 'A',5) status_number,
               nvl(tdb.is_mandatory_enrollment,'N') mandatory_enrollment_flag
       FROM ota_delegate_bookings tdb,
                    ota_booking_status_types bst,
                      ota_booking_status_types_tl btt
       WHERE  tdb.delegate_person_id = p_learner_id
         AND  tdb.event_id = p_event_id
         AND tdb.booking_status_type_id = bst.booking_status_type_id
         AND bst.booking_status_type_id = btt.booking_status_type_id
         AND btt.LANGUAGE = USERENV('LANG')
         ORDER BY mandatory_enrollment_flag desc, status_number desc;


    l_status varchar2(100) := NULL;
    l_status_code varchar2(30);
    l_status_id NUMBER := NULL;
    l_status_number NUMBER;
    l_mandatory_enrollment_flag varchar2(1) := NULL;
    l_proc  varchar2(72) := g_package||'learner_can_enroll_in_class';
    BEGIN

         hr_utility.set_location(' Entering:'||l_proc, 5);

        OPEN get_learner_class_enr_status;
        FETCH get_learner_class_enr_status INTO l_status_code, l_status, l_status_id, l_status_number, l_mandatory_enrollment_flag ;
        CLOSE get_learner_class_enr_status;

        IF((l_status_code = 'C' AND l_mandatory_enrollment_flag = 'N') OR (l_status_code IS NULL))THEN
         hr_utility.set_location(' Leaving:'||l_proc, 10);
          RETURN 'Y';
        ELSE
         hr_utility.set_location(' Leaving:'||l_proc, 15);
          RETURN 'N';
        END IF;



END learner_can_enroll_in_class;




FUNCTION learner_is_notSelected(p_person_id IN per_all_people_f.person_id%type
                                ,p_assignment_id per_all_assignments_f.assignment_id%type
                                ,p_event_id IN ota_events.event_id%type)
                          RETURN Boolean IS

    CURSOR lrnr_already_selected IS
    SELECT assignment_id
    FROM ota_mandatory_enr_req_members
    WHERE
    person_id = p_person_id
    AND event_id = p_event_id
    AND create_enrollment = 'Y';

  l_lrnr_assignment_id per_all_assignments_f.assignment_id%type;
  l_person_name per_all_people_f.full_name%type;
  l_proc  varchar2(72) := g_package||'learner_is_notSelected';

BEGIN

    hr_utility.set_location(' Entering:'||l_proc, 5);

    OPEN lrnr_already_selected;
    FETCH lrnr_already_selected INTO l_lrnr_assignment_id;

    IF lrnr_already_selected%NOTFOUND THEN
       CLOSE lrnr_already_selected;
       RETURN TRUE;
    ELSE
       IF p_assignment_id = l_lrnr_assignment_id THEN
          CLOSE lrnr_already_selected;
           hr_utility.set_location(' Leaving:'||l_proc, 10);
          RETURN false;
       ELSE
          --Log an error mentioning learner has duplicate assignments
          OPEN csr_get_person_name(p_person_id);
          FETCH csr_get_person_name INTO l_person_name;
          CLOSE csr_get_person_name;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name - '|| l_person_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner has duplicate assignments.Error creating enrollment INTO class -' || p_event_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');
          CLOSE lrnr_already_selected;
           hr_utility.set_location(' Leaving:'||l_proc, 15);
          RETURN false;
       END IF;

    END IF;


END learner_is_notSelected;


FUNCTION learner_belongs_to_child_org(p_org_structure_version_id IN ota_event_associations. org_structure_version_id%type,
                                      p_organization_id IN ota_event_associations.organization_id%type,
                                      p_person_id IN per_people_f.person_id%type)
                                      RETURN VARCHAR2 IS

  CURSOR csr_lrnr_belongs_to_org IS
  SELECT  asg.assignment_id
  FROM    per_all_assignments_f asg,
          (
            SELECT  p_organization_id AS organization_id
            FROM  dual
            UNION ALL
            SELECT x.sub_organization_id AS organization_id
            FROM   per_org_hrchy_summary x,
                   per_org_structure_versions v,
                   per_org_structure_versions currv
            WHERE  v.org_structure_version_id = p_org_structure_version_id AND
                   v.organization_structure_id = currv.organization_structure_id AND
                   (currv.date_to IS NULL OR
                    sysdate BETWEEN currv.date_from AND currv.date_to) AND
                   x.organization_structure_id = currv.organization_structure_id AND
                   x.org_structure_version_id = currv.org_structure_version_id AND
                   x.organization_id = p_organization_id AND
                   x.sub_org_relative_level > 0
           ) orgs
  WHERE    asg.person_id = p_person_id  AND
           asg.organization_id = orgs.organization_id AND
           asg.assignment_type in ('E','A','C');

  l_assignment_id per_all_assignments_f.assignment_id%type;
  l_proc  varchar2(72) := g_package||'learner_belongs_to_child_org';
 BEGIN

  hr_utility.set_location(' Entering:'||l_proc, 5);

  OPEN csr_lrnr_belongs_to_org;
  FETCH csr_lrnr_belongs_to_org INTO l_assignment_id;
  CLOSE csr_lrnr_belongs_to_org;

  IF l_assignment_id IS NOT NULL THEN
   hr_utility.set_location(' Leaving:'||l_proc, 10);
    RETURN 'Y';
  ELSE
   hr_utility.set_location(' Leaving:'||l_proc, 15);
    RETURN 'N';
  END IF;

END learner_belongs_to_child_org;



PROCEDURE create_request_member_record(l_person_id IN ota_mandatory_enr_req_members.person_id%type,
                                req_mandatory_enr_request_id IN ota_mandatory_enr_req_members.mandatory_enr_request_id%type,
                                req_event_id IN ota_events.event_id%type,
                                req_enr_prereq_type IN varchar2,
                                lrnr_completed_crs_prereq ota_mandatory_enr_req_members.completed_course_prereq%type,
                                lrnr_completed_comp_prereq ota_mandatory_enr_req_members.completed_competence_prereq%type,
                                l_person_type IN varchar2, -- l_person_type added for Integra's requirement
                                l_numberof_records_processed IN OUT NOCOPY NUMBER) IS

 CURSOR csr_get_assignment_info(l_person_id NUMBER) IS
    SELECT paf.organization_id,
    paf.business_group_id,
    paf.assignment_id
    FROM
    per_all_assignments_f paf,
    per_person_types ppt,
    per_all_people_f perp,
    per_person_type_usages_f ptu
    WHERE
    paf.person_id = l_person_id
    AND perp.person_id =paf.person_id
    AND perp.person_id = ptu.person_id
    AND ptu.person_type_id = ppt.person_type_id
    AND (paf.primary_flag = 'Y' AND ppt.system_person_type = l_person_type) -- Added for Integra's requirement
    AND paf.assignment_type IN ('E','C')
    AND trunc(sysdate) BETWEEN paf.effective_start_date AND paf.effective_end_date
    AND trunc(sysdate) BETWEEN ptu.effective_start_date AND ptu.effective_end_date;

   l_assignment_info csr_get_assignment_info%rowtype;
   l_org_id NUMBER;
   l_bg_id NUMBER;
   l_asg_id NUMBER;
   l_create_enrollment varchar2(1) :=null;
   l_completed_crs_prereq varchar2(1):= null;
   l_completed_comp_prereq varchar2(1) :=null;
   l_asg_count NUMBER := 0;
   l_proc  varchar2(72) := g_package||'create_request_member_record';

BEGIN

       hr_utility.set_location(' Entering:'||l_proc, 5);
    --As learners are selected based on primary or secondary assignment criteria,but enrollments must be created
    -- based on primary assignment we need to retreive the primary assignment before validations.
   BEGIN
    SELECT count(paf.assignment_id)
    into l_asg_count
    FROM
    per_all_assignments_f paf,
    per_person_types ppt,
    per_all_people_f perp,
    per_person_type_usages_f ptu
    WHERE
    paf.person_id = l_person_id
    AND perp.person_id =paf.person_id
    AND perp.person_id = ptu.person_id
    AND ptu.person_type_id = ppt.person_type_id
    AND (paf.primary_flag = 'Y' AND ppt.system_person_type = l_person_type)   -- Added for Integra's requirement
    AND paf.assignment_type IN ('E','C')
    AND trunc(sysdate) BETWEEN paf.effective_start_date AND paf.effective_end_date
    AND trunc(sysdate) BETWEEN ptu.effective_start_date AND ptu.effective_end_date;
  EXCEPTION
        when others then
         l_asg_count := 0;
   END;

   IF l_asg_count > 0 THEN

        /* OPEN csr_get_assignment_info(l_person_id);
         fnd_file.put_line (fnd_file.LOG, 'In Cursor-'||l_person_id);
           IF csr_get_assignment_info%FOUND THEN
           --fnd_file.put_line (fnd_file.LOG, 'In Cursor');
           FETCH csr_get_assignment_info INTO l_org_id,l_bg_id,l_asg_id;
           fnd_file.put_line (fnd_file.LOG,'Assignment ID-'||l_assignment_info.assignment_id);
           END IF;
           CLOSE csr_get_assignment_info;*/

           FOR rec_get_assignment_info IN csr_get_assignment_info(l_person_id)
           LOOP
                l_bg_id := rec_get_assignment_info.business_group_id;
                l_org_id := rec_get_assignment_info.organization_id;
                l_asg_id := rec_get_assignment_info.assignment_id;
           END LOOP;

          IF learner_is_notSelected(l_person_id,l_asg_id,req_event_id) THEN
    --perform the above check to avoid multiple entries for the same learner into same class AND duplicate assignments

                     IF req_enr_prereq_type = 'N' THEN --Prereq=None
                       l_create_enrollment := 'Y';

                     ELSIF req_enr_prereq_type = 'A' THEN --Prereq=Course
                       l_create_enrollment := lrnr_completed_crs_prereq;

                     ELSIF req_enr_prereq_type = 'C' THEN  --Prereq=Competence
                       l_create_enrollment := lrnr_completed_comp_prereq;

                     ELSIF req_enr_prereq_type = 'E' THEN  --Prereq=Course OR Competence
                       IF lrnr_completed_comp_prereq = 'Y' THEN
                          l_create_enrollment := 'Y';
                       ELSE
                          l_create_enrollment := lrnr_completed_crs_prereq;
                       END IF;

                     ELSE  --Prereq = Course AND Competence
                        IF lrnr_completed_comp_prereq = 'Y' THEN
                          l_create_enrollment := lrnr_completed_crs_prereq;
                        ELSE
                         l_create_enrollment := 'N';
                        END IF;

                       END IF;
                        l_completed_crs_prereq :=  lrnr_completed_crs_prereq;
                     l_completed_comp_prereq := lrnr_completed_comp_prereq;

                     fnd_file.put_line (fnd_file.LOG,'Assignment ID1-'||l_asg_id);

                    INSERT INTO ota_mandatory_enr_req_members(mandatory_enr_request_id,person_id,assignment_id,error_message,creation_date,completed_course_prereq,completed_competence_prereq,create_enrollment,event_id,organization_id,business_group_id)
                         VALUES(req_mandatory_enr_request_id,l_person_id,l_asg_id,NULL,sysdate,l_completed_crs_prereq,l_completed_comp_prereq,
                         l_create_enrollment,req_event_id,l_org_id,l_bg_id);
                      l_numberof_records_processed := l_numberof_records_processed + 1;
             END IF;--learner_is_notSelected

     END IF;

 hr_utility.set_location(' Leaving:'||l_proc, 10);

exception
        when others then
       fnd_file.put_line (fnd_file.LOG,'Error for-'||l_person_id||SQLERRM);

              --hr_utility.set_location(' Leaving:'||l_proc, 10);

end create_request_member_record;





PROCEDURE process_mandatory_enr_requests(p_conc_request_id IN NUMBER, p_person_type IN VARCHAR2) IS


 TYPE learners_in_usergroup IS REF CURSOR;
 csr_get_lrnr_in_ug learners_in_usergroup;

 TYPE learner_rec IS RECORD(
      person_id per_all_people_f.person_id%type,
    job_id per_jobs_tl.job_id%type,
    position_id per_all_positions.position_id%type,
    completed_crs_prereq varchar2(1),
    completed_comp_prereq varchar2(1),
    organization_id per_all_assignments_f.organization_id%type,
    assignment_id per_all_assignments_f.assignment_id%type
     );
 lrnr_rec learner_rec;

 CURSOR csr_get_learners(
    p_person_id ota_event_associations.person_id%type,
    p_organization_id ota_event_associations.organization_id%type,
    p_job_id ota_event_associations.job_id%type,
    p_position_id ota_event_associations.position_id%type,
    p_org_structure_version_id ota_event_associations. org_structure_version_id%type,
    p_event_id ota_event_associations.event_id%type,
    p_enr_prereq_type ota_event_associations.mandatory_enrollment_prereq%type,
    p_event_start_date date
    ) IS
    SELECT ppf.person_id
         , pjt.job_id Job_Id
         , pps.position_id
         ,ota_cpr_utility.is_mand_crs_prereqs_comp_evt(ppf.person_id,NULL, ppf.person_id,'E',p_event_id ) completed_crs_prereq
         ,ota_cpr_utility.is_mand_comp_prereqs_comp_evt(ppf.person_id,p_event_id) completed_comp_prereq
           , paf.organization_id
        , paf.assignment_id
        FROM per_all_people_f ppf
        ,per_all_assignments_f paf
        ,per_jobs_tl pjt
        ,per_all_positions pps
        ,per_person_type_usages_f ptu
        ,per_person_types pts
        ,per_person_types_tl ptt
        ,hr_all_organization_units_tl orgTl
        ,per_business_groups pbg
    WHERE  ppf.person_id = paf.person_id
       AND (pts.system_person_type IN ('EMP','CWK') OR (paf.assignment_type = 'A' AND pts.system_person_type ='APL'))
       AND trunc(sysdate) BETWEEN ppf.effective_start_date AND ppf.effective_end_date
       AND ( (nvl(fnd_profile.value('OTA_ALLOW_FUTURE_ENDDATED_EMP_ENROLLMENTS'),'N') = 'Y'
               AND trunc(sysdate) BETWEEN paf.effective_start_date and paf.effective_end_date)
           OR  nvl(p_event_start_date, trunc(sysdate)) between paf.effective_start_date and paf.effective_end_date )
       AND ( (nvl(fnd_profile.value('OTA_ALLOW_FUTURE_ENDDATED_EMP_ENROLLMENTS'),'N') = 'Y'
               AND trunc(sysdate) BETWEEN ptu.effective_start_date and ptu.effective_end_date)
           OR  nvl(p_event_start_date, trunc(sysdate)) between ptu.effective_start_date and ptu.effective_end_date )
       AND paf.job_id = pjt.job_id(+)
       AND pjt.language(+) = USERENV('LANG')
       AND pps.position_id(+) = paf.position_id
       AND pts.person_type_id = ptt.person_type_id
       AND ptt.language = USERENV('LANG')
       AND pts.person_type_id = ptu.person_type_id
       AND ptu.person_id = ppf.person_id
       AND paf.organization_id = orgtl.organization_id
       AND pts.system_person_type IN ('EMP', 'CWK', 'APL')
       AND paf.assignment_type IN ('A','E','C')
       AND orgtl.language = USERENV('LANG')
    AND (fnd_profile.value('OTA_HR_GLOBAL_BUSINESS_GROUP_ID') IS NOT NULL OR pbg.business_group_id = fnd_profile.value('PER_BUSINESS_GROUP_ID'))
    AND paf.business_group_id = pbg.business_group_id
    AND
    ((pts.system_person_type = 'APL'
    AND NOT EXISTS (SELECT person_id
     FROM per_person_type_usages_f ptf,
    per_person_types ptp WHERE trunc(sysdate) BETWEEN trunc(ptf.effective_start_date) AND trunc(ptf.effective_end_date)
    AND ptf.person_type_id = ptp.person_type_id
    AND ptp.system_person_type IN ('EMP', 'CWK')
    AND ptf.person_id = ppf.PERSON_ID)
    )
    OR pts.system_person_type IN ('EMP', 'CWK'))
    AND learner_can_enroll_in_class(p_event_id,ppf.person_id) = 'Y'
    AND
    (
    ( nvl(p_organization_id, -1) = decode(p_organization_id, NULL, -1, nvl(paf.organization_id,-1))) OR

    ( p_org_structure_version_id IS NOT NULL AND learner_belongs_to_child_org(p_org_structure_version_id,p_organization_id,ppf.person_id)='Y')
    )
    AND nvl(p_job_id, -1) = decode(p_job_id, NULL, -1, nvl(paf.job_id, -1))
    AND nvl(p_position_id,-1) = decode(p_position_id, NULL, -1, nvl(paf.position_id, -1))

    AND nvl(p_person_id,-1) = decode(p_person_id,NULL,-1,paf.person_id);
    --AND ppf.person_id=1231; -- Added for testing


 l_numberof_records_processed NUMBER:= 0;
 l_create_enrollment varchar2(1);
 l_completed_crs_prereq varchar2(1);
 l_completed_comp_prereq varchar2(1);
 l_person_name per_all_people_f.full_name%type;
 l_event_start_date date;


 sql_stmnt varchar2(32000);
 usergroup_whereclause varchar2(32000);
 l_proc  varchar2(72) := g_package||'process_mandatory_enr_requests';
 BEGIN

   hr_utility.set_location(' Entering:'||l_proc, 5);

  FOR request IN get_all_mandatory_enr_requests(p_conc_request_id) LOOP
  l_event_start_date := trunc(ota_learner_access_util.get_event_start_date(request.event_id,sysdate));
    IF request.usergroup_id IS NULL THEN
       FOR learner IN csr_get_learners (request.person_id, request.organization_id, request.job_id, request.position_id, request.org_structure_version_id, request.event_id, request.enr_prereq_type,l_event_start_date) LOOP
          create_request_member_record(learner.person_id,request.mandatory_enr_request_id,request.event_id,request.enr_prereq_type,learner.completed_crs_prereq,learner.completed_comp_prereq,p_person_type,l_numberof_records_processed);-- Added per_person_type parameter for Integra
       END LOOP;--END FOR learner IN csr_get_learners
    ELSE
         --resolve the members FOR the user group AND them to ota_mandatory_enr_request_members
         usergroup_whereclause :=TO_CHAR(ota_learner_access_util.get_ug_whereclause(request.usergroup_id, -1));
         --FND_FILE.PUT_LINE(FND_FILE.LOG,'usergroup_whereclause : '||usergroup_whereclause);
         sql_stmnt :='SELECT * FROM(
          SELECT
          ppf.person_id person_id
         , pjt.job_id job_id
         , pps.position_id position_id
         ,ota_cpr_utility.is_mand_crs_prereqs_comp_evt(ppf.person_id,NULL, ppf.person_id,''E'',:1 ) completed_crs_prereq
         ,ota_cpr_utility.is_mand_comp_prereqs_comp_evt(ppf.person_id,:2) completed_comp_prereq
        , paf.organization_id organization_id
    , paf.assignment_id assignment_id
    FROM per_all_people_f ppf
        ,per_all_assignments_f paf
        ,per_jobs_tl pjt
        ,per_all_positions pps
        ,per_person_type_usages_f ptu
        ,per_person_types pts
        ,per_person_types_tl ptt
        ,hr_all_organization_units_tl orgTl
        ,per_business_groups pbg
    WHERE  ppf.person_id = paf.person_id
       AND (pts.system_person_type IN (''EMP'',''CWK'') OR (paf.assignment_type = ''A'' AND pts.system_person_type =''APL''))
       AND trunc(sysdate) BETWEEN ppf.effective_start_date AND ppf.effective_end_date
       AND ( (nvl(fnd_profile.value(''OTA_ALLOW_FUTURE_ENDDATED_EMP_ENROLLMENTS''),''N'') = ''Y''
               AND trunc(sysdate) BETWEEN paf.effective_start_date and paf.effective_end_date)
           OR  nvl(:3, trunc(sysdate)) between paf.effective_start_date and paf.effective_end_date )
       AND ( (nvl(fnd_profile.value(''OTA_ALLOW_FUTURE_ENDDATED_EMP_ENROLLMENTS''),''N'') = ''Y''
               AND trunc(sysdate) BETWEEN ptu.effective_start_date and ptu.effective_end_date)
           OR  nvl(:4, trunc(sysdate)) between ptu.effective_start_date and ptu.effective_end_date )
       AND paf.job_id = pjt.job_id(+)
       AND pjt.language(+) = USERENV(''LANG'')
       AND pps.position_id(+) = paf.position_id
       AND pts.person_type_id = ptt.person_type_id
       AND ptt.language = USERENV(''LANG'')
       AND pts.person_type_id = ptu.person_type_id
       AND ptu.person_id = ppf.person_id
       AND paf.organization_id = orgtl.organization_id
       AND pts.system_person_type IN (''EMP'', ''CWK'', ''APL'')
       AND paf.assignment_type IN (''A'',''E'',''C'')
       AND orgtl.language = USERENV(''LANG'')
    AND (fnd_profile.value(''OTA_HR_GLOBAL_BUSINESS_GROUP_ID'') IS NOT NULL OR pbg.business_group_id = fnd_profile.value(''PER_BUSINESS_GROUP_ID''))
    AND paf.business_group_id = pbg.business_group_id
    AND
    ((pts.system_person_type = ''APL''
    AND NOT EXISTS (SELECT person_id
     FROM per_person_type_usages_f ptf,
    per_person_types ptp WHERE trunc(sysdate) BETWEEN trunc(ptf.effective_start_date) AND trunc(ptf.effective_end_date)
    AND ptf.person_type_id = ptp.person_type_id
    AND ptp.system_person_type IN (''EMP'', ''CWK'')
    AND ptf.person_id = ppf.PERSON_ID)
    )
    OR pts.system_person_type IN (''EMP'', ''CWK''))
    AND OTA_MANDATORY_ENROLL_UTIL.learner_can_enroll_in_class(:5,ppf.person_id) = ''Y''
    )QRSLT WHERE'|| usergroup_whereclause;

    OPEN csr_get_lrnr_in_ug FOR sql_stmnt USING request.event_id,request.event_id,l_event_start_date,l_event_start_date,request.event_id;
       LOOP
          FETCH csr_get_lrnr_in_ug into lrnr_rec;
          EXIT WHEN csr_get_lrnr_in_ug%NOTFOUND;
            create_request_member_record(lrnr_rec.person_id,request.mandatory_enr_request_id,request.event_id,request.enr_prereq_type,lrnr_rec.completed_crs_prereq,lrnr_rec.completed_comp_prereq,p_person_type,l_numberof_records_processed);-- Added p_person_type parameter for Integra
       END LOOP;
    CLOSE csr_get_lrnr_in_ug;

   END IF;--END IF request.usergroup_id IS NULL

       IF l_numberof_records_processed > 1000 THEN
        COMMIT;
        l_numberof_records_processed :=0;
       END IF;

  END LOOP;

 COMMIT;
--All the records to be processed are now present IN ota_mandatory_enr_req_members with create_enrollment = 'Y'.
--The records which cannot be created due to unfulfilled course/competence prereq have the respective flags set to 'N'
--and create_enrollment IS set to 'N'


  create_enrollments(p_conc_request_id);



--Write the error messages to log
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unsuccessful Learners');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name                  Class           Reason');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------');
  FOR unsuccessful_learner IN unprocessed_enrollments LOOP
     OPEN csr_get_person_name(unsuccessful_learner.person_id);
     FETCH csr_get_person_name INTO l_person_name;
     CLOSE csr_get_person_name;
     IF unsuccessful_learner.create_enrollment = 'N' THEN
          IF unsuccessful_learner.completed_course_prereq = 'N' THEN
          --The learner has NOT completed the course perquisites FOR the event
           /*FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name - ' || l_person_name);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'The learner has NOT completed the course perquisites for the class -'||unsuccessful_learner.title);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');*/
           FND_FILE.PUT_LINE(FND_FILE.LOG, l_person_name||'        | '||unsuccessful_learner.title||'        | '||'Incomplete course prerequisites');
          END IF;
          IF unsuccessful_learner.completed_competence_prereq = 'N' THEN
       --The learner has NOT completed the competence perquisites FOR the event
          /*FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name - ' || l_person_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'The learner has NOT completed the competence perquisites for the class -'||unsuccessful_learner.title);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');*/
          FND_FILE.PUT_LINE(FND_FILE.LOG, l_person_name||'        | '||unsuccessful_learner.title||'        | '||'Incomplete competence prerequisites');
          END IF;
    END IF;

     IF unsuccessful_learner.error_message IS NOT NULL THEN
          /* FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name - ' || l_person_name);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message - '||unsuccessful_learner.error_message);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');*/
           FND_FILE.PUT_LINE(FND_FILE.LOG, l_person_name||'        | '||unsuccessful_learner.title||'        | '||unsuccessful_learner.error_message);
     END IF;


 END LOOP;

  hr_utility.set_location(' Leaving:'||l_proc, 10);


END process_mandatory_enr_requests;


PROCEDURE create_enrollments(p_conc_reqId IN NUMBER) IS


  CURSOR csr_get_request_members(l_conc_reqID NUMBER) IS
    SELECT
    reqmembers.MANDATORY_ENR_REQUEST_ID,
    reqmembers.PERSON_ID,
    reqmembers.ASSIGNMENT_ID,
    reqmembers.EVENT_ID,
    reqmembers.ERROR_MESSAGE,
    reqmembers.ORGANIZATION_ID,
    reqmembers.BUSINESS_GROUP_ID
    FROM
    ota_mandatory_enr_req_members reqmembers,
    ota_mandatory_enr_requests  requests
    WHERE
    requests.conc_program_request_id = l_conc_reqId
    AND requests.mandatory_enr_request_id = reqmembers.mandatory_enr_request_id
    AND reqmembers.create_enrollment = 'Y'
    ORDER BY event_id;



  CURSOR csr_get_cost_center_info(l_assignment_id NUMBER) IS
    SELECT pcak.cost_allocation_keyflex_id
    FROM per_all_assignments_f assg,
    pay_cost_allocations_f pcaf,
    pay_cost_allocation_keyflex pcak
    WHERE assg.assignment_id = pcaf.assignment_id
    AND assg.assignment_id = l_assignment_id
    AND assg.Primary_flag = 'Y'
    AND pcaf.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id
    AND pcak.enabled_flag = 'Y'
    AND sysdate BETWEEN nvl(pcaf.effective_start_date,sysdate)
    AND nvl(pcaf.effective_end_date,sysdate+1)
    AND trunc(sysdate) BETWEEN nvl(assg.effective_start_date,trunc(sysdate))
    AND nvl(assg.effective_end_date,trunc(sysdate+1));

 l_error_message ota_mandatory_enr_req_members.error_message%type;
 l_mandaotory_enr_request_id ota_mandatory_enr_req_members.mandatory_enr_request_id%type;
 l_booking_status_type_id ota_booking_status_types.booking_status_type_id%type;
 l_booking_status ota_booking_status_types_tl.name%type;

 l_request_rec get_all_mandatory_enr_requests%rowtype;
 l_req_member_rec csr_get_request_members%rowtype;
 l_booking_id ota_delegate_bookings.booking_id%type;


 l_cost_center_info csr_get_cost_center_info%rowtype;

 l_person_name per_all_people_f.full_name%type;
 l_class_name ota_events_tl.title%type;
 l_proc  varchar2(72) := g_package||'create_enrollments';

BEGIN

  hr_utility.set_location(' Entering:'||l_proc, 5);

 OPEN get_all_mandatory_enr_requests(p_conc_reqId);
 FETCH get_all_mandatory_enr_requests INTO l_request_rec;
 IF get_all_mandatory_enr_requests%NOTFOUND THEN
   -- Raise error that no request found
   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR-No requests found FOR concurrent program- '||p_conc_reqId);
   CLOSE get_all_mandatory_enr_requests;
   RETURN;
 ELSE
   CLOSE get_all_mandatory_enr_requests;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful Learners');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name                Class           ');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------');

   FOR l_req_member_rec IN csr_get_request_members(p_conc_reqId) LOOP

      l_booking_id    := NULL;
      l_error_message := NULL;

      OPEN csr_get_person_name(l_req_member_rec.person_id);
      FETCH csr_get_person_name INTO l_person_name;
      CLOSE csr_get_person_name;
    --  FND_FILE.PUT_LINE(FND_FILE.LOG,'Learner Name - ' || l_person_name);


      OPEN csr_get_cost_center_info(l_req_member_rec.assignment_id);
      FETCH csr_get_cost_center_info INTO l_cost_center_info;
      CLOSE csr_get_cost_center_info;

     BEGIN

       ota_bulk_enroll_util.Create_Enrollment_And_Finance(
             p_event_id => l_req_member_rec.event_id
            ,p_cost_centers        => l_cost_center_info.cost_allocation_keyflex_id
            ,p_assignment_id => l_req_member_rec.assignment_id
            ,p_delegate_contact_id => NULL
            ,p_business_group_id_from => l_req_member_rec.business_group_id
            ,p_organization_id     => l_req_member_rec.organization_id
            ,p_person_id  => l_req_member_rec.person_id
            ,p_booking_id => l_booking_id
            ,p_message_name => l_error_message
            ,p_override_prerequisites => 'Y'
            ,p_is_mandatory_enrollment => 'Y');
     EXCEPTION
     WHEN OTHERS THEN
        l_error_message  := nvl(substr(SQLERRM,1,2000),'Error When creating Enrollment ');
       UPDATE ota_mandatory_enr_req_members
       SET error_message = l_error_message
       WHERE person_id = l_req_member_rec.person_id
       AND event_id = l_req_member_rec.event_id
       AND mandatory_enr_request_id = l_req_member_rec.mandatory_enr_request_id;
     END;

     OPEN get_class_name(l_req_member_rec.event_id);
     FETCH get_class_name into l_class_name;
     CLOSE get_class_name;

     IF l_booking_id IS NOT NULL THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,l_person_name||'        | '||l_class_name);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');
       UPDATE ota_mandatory_enr_req_members
       SET  error_message = NULL
       WHERE person_id = l_req_member_rec.person_id
       AND assignment_id = l_req_member_rec.assignment_id
       AND event_id = l_req_member_rec.event_id
       AND mandatory_enr_request_id = l_req_member_rec.mandatory_enr_request_id;
    ELSE
      l_error_message  := nvl(substr(l_error_message,1,2000),'Booking_id IS NULL');
     -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Error when creating enrollment into class- '||l_class_name);
     --FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - ' || l_error_message);
     --FND_FILE.PUT_LINE(FND_FILE.LOG,'---------------------------------------------');

       UPDATE ota_mandatory_enr_req_members
       SET error_message = l_error_message
       WHERE person_id = l_req_member_rec.person_id
       AND event_id = l_req_member_rec.event_id
       AND mandatory_enr_request_id = l_req_member_rec.mandatory_enr_request_id;
    END IF;

   END LOOP;
        -- Start workflow AND send a notification to the requestor
     notify_class_owners(p_conc_reqId);
   END IF;

    hr_utility.set_location(' Leaving:'||l_proc, 10);

END create_enrollments;






PROCEDURE notify_mandatory_request(p_person_id in NUMBER,
                                   p_conc_program_request_id in NUMBER,
                                   p_object_type in VARCHAR2,
                                   p_object_id in NUMBER,
                                   p_error_learners in NUMBER,
                                   p_success_learners in NUMBER)
IS
    l_proc  varchar2(72) := g_package||'notify_mandatory_request';
    l_process              wf_activities.name%type :='OTA_BLK_MANDATORY_ENR_NTF_PRC';
    l_item_type    wf_items.item_type%type := 'OTWF';
    l_item_key     wf_items.item_key%type;

    l_user_name  varchar2(80);
    l_person_full_name per_all_people_f.FULL_NAME%TYPE;
    l_role_name wf_roles.name%type;
    l_role_display_name wf_roles.display_name%type;

    l_process_display_name varchar2(240);

CURSOR csr_get_user_name(p_person_id IN VARCHAR2) IS
SELECT user_name FROM fnd_user WHERE employee_id=p_person_id
and trunc(sysdate) between trunc(start_date) and trunc(nvl(end_date, sysdate+1));


CURSOR csr_get_person_name(p_person_id IN number) IS
SELECT ppf.full_name FROM per_all_people_f ppf WHERE person_id = p_person_id;

BEGIN
 hr_utility.set_location('Entering:'||l_proc, 5);

  -- Get the next item key from the sequence
  select hr_workflow_item_key_s.nextval into l_item_key from sys.dual;

    WF_ENGINE.CREATEPROCESS(l_item_type, l_item_key, l_process);

    WF_ENGINE.setitemattrnumber(l_item_type,l_item_key,'CONC_REQUEST_ID',p_conc_program_request_id);
    WF_ENGINE.setitemattrtext(l_item_type,l_item_key,'OBJECT_NAME',p_object_id);
    WF_ENGINE.setitemattrtext(l_item_type, l_item_key, 'OBJECT_TYPE' ,p_object_type);
    WF_ENGINE.setitemattrnumber(l_item_type,l_item_key,'ERROR_NUMBER',p_error_learners);
    WF_ENGINE.setitemattrnumber(l_item_type,l_item_key,'SUCCESS_NUMBER',p_success_learners);

 IF p_person_id IS NOT NULL THEN
       OPEN csr_get_person_name(p_person_id);
       FETCH csr_get_person_name INTO l_person_full_name;
       CLOSE csr_get_person_name;

       OPEN csr_get_user_name(p_person_id);
       FETCH csr_get_user_name INTO l_user_name;
       CLOSE csr_get_user_name;

     --fnd_file.put_line(FND_FILE.LOG,'Requestor Name ' ||l_person_full_name);

     IF l_person_full_name IS NOT NULL then
        WF_ENGINE.setitemattrtext(l_item_type,l_item_key,'EVENT_OWNER',l_user_name);
     END IF;
 END IF;

-- Get and set owner role

    hr_utility.set_location('Before Getting Owner'||l_proc, 10);

    WF_DIRECTORY.GetRoleName(p_orig_system =>'PER',
                      p_orig_system_id => p_person_id,
                      p_name  =>l_role_name,
                      p_display_name  =>l_role_display_name);


    WF_ENGINE.SetItemOwner(itemtype => l_item_type,
                       itemkey =>l_item_key,
                       owner =>l_role_name);

 hr_utility.set_location('After Setting Owner'||l_proc, 10);


 WF_ENGINE.STARTPROCESS(l_item_type,l_item_key);

 hr_utility.set_location('leaving:'||l_proc, 20);

EXCEPTION
WHEN OTHERS THEN
 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END notify_mandatory_request;




PROCEDURE notify_class_owners(p_conc_reqId IN NUMBER)
IS

CURSOR csr_get_all_event_owners IS
SELECT distinct event_id,requestor_id
from ota_mandatory_enr_requests
where requestor_id IS NOT NULL
and conc_program_request_id = p_conc_reqId ;

CURSOR csr_get_error_learners(p_event_id IN number) IS
SELECT COUNT(distinct person_id)
FROM ota_mandatory_enr_req_members reqm
WHERE reqm.event_id = p_event_id
AND(reqm.create_enrollment  = 'N' or reqm.error_message IS NOT NULL);


CURSOR csr_get_successful_learners(p_event_id IN number) IS
SELECT COUNT( distinct person_id)
FROM ota_mandatory_enr_req_members reqm
WHERE reqm.event_id = p_event_id
AND(reqm.create_enrollment  = 'Y' and reqm.error_message IS NULL);

l_error_learners NUMBER := 0;
l_success_learners NUMBER := 0;

 l_proc     varchar2(72) := g_package||'notify_class_owners';

BEGIN
    hr_utility.set_location('Entering:'||l_proc, 5);
 for owner in csr_get_all_event_owners loop

    OPEN csr_get_error_learners(owner.event_id);
    FETCH csr_get_error_learners INTO l_error_learners;
    CLOSE csr_get_error_learners;

    OPEN csr_get_successful_learners(owner.event_id);
    FETCH csr_get_successful_learners INTO l_success_learners;
    CLOSE csr_get_successful_learners;

  notify_mandatory_request(owner.requestor_id,p_conc_reqId,'CL',owner.event_id,l_error_learners,l_success_learners);

 end loop;


END notify_class_owners;


END xxintg_ota_mandatory_enroll;
/
