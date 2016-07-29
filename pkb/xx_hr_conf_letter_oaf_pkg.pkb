DROP PACKAGE BODY APPS.XX_HR_CONF_LETTER_OAF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_CONF_LETTER_OAF_PKG" 
AS
   FUNCTION gethrrepname (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_name   VARCHAR2 (500);
   BEGIN
      SELECT ppf.first_name || ' ' || ppf.last_name
        INTO x_name
        FROM per_all_people_f ppf,
             per_all_positions pap,
             per_all_assignments_f paa,
             per_all_vacancies pav
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.position_id = pap.position_id
         AND pap.attribute5 = paa.position_id
         AND paa.person_id = ppf.person_id
         AND SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date
         AND SYSDATE BETWEEN paa.effective_start_date AND paa.effective_end_date;

      RETURN (x_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;

   FUNCTION getdirname (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_name   VARCHAR2 (500);
   BEGIN
      SELECT ppf.first_name || ' ' || ppf.last_name
        INTO x_name
        FROM per_all_people_f ppf,
             per_all_positions pap,
             per_all_assignments_f paa,
             per_all_vacancies pav
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.position_id = pap.position_id
         AND pap.attribute6 = paa.position_id
         AND paa.person_id = ppf.person_id
         AND SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date
         AND SYSDATE BETWEEN paa.effective_start_date AND paa.effective_end_date;

      RETURN (x_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;

   FUNCTION getdirtitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_title   VARCHAR2 (500);
   BEGIN
      SELECT SUBSTR (pap1.NAME, 1, INSTR (pap1.NAME, '.') - 1)
        INTO x_title
        FROM per_all_positions pap,
             per_all_positions pap1,
             per_all_vacancies pav
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.position_id = pap.position_id
         AND pap.attribute6 = pap1.position_id;

      RETURN (x_title);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;

   FUNCTION gethrreptitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_title   VARCHAR2 (500);
   BEGIN
      SELECT SUBSTR (pap1.NAME, 1, INSTR (pap1.NAME, '.') - 1)
        INTO x_title
        FROM per_all_positions pap,
             per_all_positions pap1,
             per_all_vacancies pav
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.position_id = pap.position_id
         AND pap.attribute5 = pap1.position_id;

      RETURN (x_title);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;

   FUNCTION gethiringmngtitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_title   VARCHAR2 (500);
   BEGIN
      SELECT SUBSTR (pap.NAME, 1, INSTR (pap.NAME, '.') - 1)
        INTO x_title
        FROM per_all_positions pap,
             per_all_vacancies pav,
             per_all_assignments_f paa
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.manager_id = paa.person_id
         AND paa.position_id = pap.position_id
         AND paa.primary_flag = 'Y'
         AND SYSDATE BETWEEN paa.effective_start_date AND paa.effective_end_date;

      RETURN (x_title);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;

   FUNCTION getrectitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_title   VARCHAR2 (500);
   BEGIN
      SELECT SUBSTR (pap.NAME, 1, INSTR (pap.NAME, '.') - 1)
        INTO x_title
        FROM per_all_positions pap,
             per_all_vacancies pav,
             per_all_assignments_f paa
       WHERE 1 = 1
         AND pav.vacancy_id = x_vacancy_id
         AND pav.recruiter_id = paa.person_id
         AND paa.position_id = pap.position_id
         AND paa.primary_flag = 'Y'
         AND SYSDATE BETWEEN paa.effective_start_date AND paa.effective_end_date;

      RETURN (x_title);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
   END;
END;
/
