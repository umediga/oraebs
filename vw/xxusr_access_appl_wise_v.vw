DROP VIEW APPS.XXUSR_ACCESS_APPL_WISE_V;

/* Formatted on 6/6/2016 5:00:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXUSR_ACCESS_APPL_WISE_V
(
   MODULE_CLASSIFICATION,
   APPLICATION_NAME,
   APPLICATION_SHORT_NAME,
   USER_COUNT,
   CLASSIFICATION_B,
   CLASSIFICATION_C
)
AS
     SELECT /*- ================================================================================
            -- FILE NAME            :
            -- AUTHOR               : Wipro Technologies
            -- DATE CREATED         : 08-NOV-2012
            -- DESCRIPTION          :
            -- RICE COMPONENT ID    :
            -- R11i10 OBJECT NAME   :
            -- R12 OBJECT NAME      : XXUSR_ACCESS_APPL_WISE_V
            -- REVISION HISTORY     :
            -- =================================================================================
            --  Version  Person                 Date          Comments
            --  -------  --------------         -----------   ------------
            --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
            -- =================================================================================*/
           xxct.module_classification,
            fat.application_name,
            fa.application_short_name,
            a.cnt "USER_COUNT",
            xxct.CLASSIFICATION_B,
            xxct.CLASSIFICATION_C
       FROM (  SELECT furg.responsibility_application_id "APPLICATION_ID",
                      COUNT (*) "CNT"
                 FROM fnd_user_resp_groups furg, fnd_user fu
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
             GROUP BY furg.responsibility_application_id) a,
            fnd_application_tl fat,
            fnd_application fa,
            XX_XRTX_CLASSIFICATION_T xxct
      WHERE     fat.application_id = a.application_id
            AND fat.LANGUAGE = 'US'
            AND fa.application_id = a.application_id
            AND fa.application_id = xxct.app_id
   ORDER BY 2 DESC;
