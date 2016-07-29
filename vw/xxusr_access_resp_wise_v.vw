DROP VIEW APPS.XXUSR_ACCESS_RESP_WISE_V;

/* Formatted on 6/6/2016 5:00:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXUSR_ACCESS_RESP_WISE_V
(
   RESPONSIBILITY_NAME,
   DESCRIPTION,
   USER_COUNT
)
AS
     SELECT /*- ================================================================================
            -- FILE NAME            :
            -- AUTHOR               : Wipro Technologies
            -- DATE CREATED         : 08-NOV-2012
            -- DESCRIPTION          :
            -- RICE COMPONENT ID    :
            -- R11i10 OBJECT NAME   :
            -- R12 OBJECT NAME      : XXUSR_ACCESS_RESP_WISE_V
            -- REVISION HISTORY     :
            -- =================================================================================
            --  Version  Person                 Date          Comments
            --  -------  --------------         -----------   ------------
            --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
            -- =================================================================================*/
           frt.responsibility_name, frt.description, a.cnt "USER_COUNT"
       FROM (  SELECT furg.responsibility_id "RESPONSIBILITY_ID", COUNT (*) "CNT"
                 FROM fnd_user_resp_groups furg,
                      fnd_user fu,
                      fnd_responsibility fr
                WHERE     TRUNC (SYSDATE) BETWEEN TRUNC (
                                                     NVL (furg.start_date,
                                                          SYSDATE - 1))
                                              AND TRUNC (
                                                     NVL (furg.end_date,
                                                          SYSDATE + 1))
                      AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                     NVL (fu.start_date,
                                                          SYSDATE - 1))
                                              AND NVL (fu.end_date, SYSDATE + 1)
                      AND (fu.start_date + NVL (fu.password_lifespan_days, 0)) <
                             SYSDATE
                      AND furg.user_id = fu.user_id
                      AND fr.responsibility_id = furg.responsibility_id
                      AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                     NVL (fr.start_date,
                                                          SYSDATE - 1))
                                              AND TRUNC (
                                                     NVL (fr.end_date,
                                                          SYSDATE + 1))
             GROUP BY furg.responsibility_id) a,
            fnd_responsibility_tl frt
      WHERE frt.responsibility_id = a.responsibility_id AND frt.LANGUAGE = 'US'
   ORDER BY 3 DESC;
