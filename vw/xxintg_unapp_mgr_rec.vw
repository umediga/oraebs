DROP VIEW APPS.XXINTG_UNAPP_MGR_REC;

/* Formatted on 6/6/2016 5:00:09 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_UNAPP_MGR_REC
(
   PERSON_ID,
   FULL_NAME,
   TYPE
)
AS
   SELECT DISTINCT a.person_id, a.full_name, 'RECRUITER' TYPE
     FROM per_all_people_f a, hr_api_transactions t
    WHERE     a.person_id =
                 xmltype (t.TRANSACTION_DOCUMENT).EXTRACT (
                    '//TransCache/AM/TXN/EO/PerRequisitionsEORow/CEO/EO/PerAllVacanciesEORow/RecruiterId/text()').getStringVal ()
          AND t.TRANSACTION_IDENTIFIER = 'CREATE_VACANCY'
          AND t.status NOT IN ('E',
                               'D',
                               'W',
                               'S',
                               'N')
          AND t.transaction_ref_table = 'PER_ALL_VACANCIES'
   UNION ALL
   SELECT DISTINCT a.person_id, a.full_name, 'MANAGER' TYPE
     FROM per_all_people_f a, hr_api_transactions t
    WHERE     a.person_id =
                 xmltype (t.TRANSACTION_DOCUMENT).EXTRACT (
                    '//TransCache/AM/TXN/EO/PerRequisitionsEORow/CEO/EO/PerAllVacanciesEORow/ManagerId/text()').getStringVal ()
          AND t.TRANSACTION_IDENTIFIER = 'CREATE_VACANCY'
          AND t.status NOT IN ('E',
                               'D',
                               'W',
                               'S',
                               'N')
          AND t.transaction_ref_table = 'PER_ALL_VACANCIES';
