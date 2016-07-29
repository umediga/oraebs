DROP VIEW APPS.XX_XRTX_FORMS_COUNT_V;

/* Formatted on 6/6/2016 4:56:42 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_FORMS_COUNT_V
(
   FORM_NAME,
   FUNCTION_NAME,
   USER_FORM_NAME,
   DESCRIPTION,
   CNT_RESPONSIBILITY,
   CNT_USER,
   CNT_APPLICATION
)
AS
     SELECT /*- ================================================================================
            -- FILE NAME            :
            -- AUTHOR               : Wipro Technologies
            -- DATE CREATED         : 28-JAN-2012
            -- DESCRIPTION          :
            -- RICE COMPONENT ID    :
            -- R11i10 OBJECT NAME   :
            -- R12 OBJECT NAME      : XX_XRTX_FORMS_COUNT_V
            -- REVISION HISTORY     :
            -- =================================================================================
            --  Version  Person                 Date          Comments
            --  -------  --------------         -----------   ------------
            --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
            -- =================================================================================*/
           ffv.FORM_NAME,
            fff.FUNCTION_NAME,
            ffv.USER_FORM_NAME,
            ffv.DESCRIPTION,
            COUNT (frt.RESPONSIBILITY_NAME) CNT_RESPONSIBILITY,
            COUNT (user_name) CNT_USER,
            COUNT (fat.APPLICATION_NAME) CNT_APPLICATION
       FROM FND_FORM_VL ffv,
            fnd_application_tl fat,
            FND_FORM_FUNCTIONS fff,
            FND_RESPONSIBILITY_TL frt,
            FND_USER_RESP_GROUPS furg,
            fnd_user fu
      WHERE     FORM_NAME LIKE 'XX%'
            AND fat.APPLICATION_ID = ffv.APPLICATION_ID
            AND ffv.FORM_ID = fff.FORM_ID
            AND frt.APPLICATION_ID = ffv.APPLICATION_ID
            AND furg.RESPONSIBILITY_ID = frt.RESPONSIBILITY_ID
            AND furg.USER_ID = fu.USER_ID
            AND fat.language = 'US'
            AND frt.language = 'US'
   GROUP BY ffv.FORM_NAME,
            fff.FUNCTION_NAME,
            ffv.USER_FORM_NAME,
            ffv.DESCRIPTION;
