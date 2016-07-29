DROP PROCEDURE APPS.XX_JTF_ISTORE_USER_DATA_PRC;

CREATE OR REPLACE PROCEDURE APPS."XX_JTF_ISTORE_USER_DATA_PRC" (
   p_acct_num                   IN       VARCHAR2,
   p_acc_name                   IN       VARCHAR2,
   p_first_name                 IN       VARCHAR2,
   p_last_name                  IN       VARCHAR2,
   p_email                      IN       VARCHAR2,
   p_business_ph_country_code   IN       VARCHAR2,
   p_business_ph_area_code      IN       VARCHAR2,
   p_business_ph_number         IN       VARCHAR2,
   p_business_ph_extn           IN       VARCHAR2,
   p_personal_ph_country_code   IN       VARCHAR2,
   p_personal_ph_area_code      IN       VARCHAR2,
   p_personal_ph_number         IN       VARCHAR2,
   p_personal_ph_extn           IN       VARCHAR2,
   p_password                   IN       VARCHAR2,
   p_comments                   IN       VARCHAR2,
   x_return                     OUT      VARCHAR2
)
----------------------------------------------------------------------
/* $Header: XXJTF_ISTORE_USER_DATA_PRC.prc 1.0 2012/07/20 12:00:00 pnarva noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Jul-2012
 File Name      : XXJTF_ISTORE_USER_DATA_PRC.prc
 Description    : This script creates the procedure of xx_jtf_istore_user_data_prc
                  which will insert data to the custom table from iStore Reg Page

 Change History:

 Version Date          Name                    Remarks
 ------- -----------   ----                    ----------------------
 1.0     20-Jul-2012   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
IS
   x_pwd_encrypt   VARCHAR2 (2000);
BEGIN
   x_pwd_encrypt :=
      UTL_RAW.cast_to_varchar2
                   (UTL_ENCODE.base64_encode (UTL_RAW.cast_to_raw (p_password))
                   );

   INSERT INTO xxintg.xxjtf_user_reg_tbl
               (seq_num, account_number, account_name,
                first_name, last_name, email,
                business_ph_country_code, business_ph_area_code,
                business_ph_number, business_ph_extn,
                personal_ph_country_code, personal_ph_area_code,
                personal_ph_number, personal_ph_extn, PASSWORD,
                comments, creation_date, created_by, last_update_date,
                last_updated_by, last_update_login
               )
        VALUES (xxjtf_user_reg_seq_gen_s.NEXTVAL, p_acct_num, p_acc_name,
                p_first_name, p_last_name, p_email,
                p_business_ph_country_code, p_business_ph_area_code,
                p_business_ph_number, p_business_ph_extn,
                p_personal_ph_country_code, p_personal_ph_area_code,
                p_personal_ph_number, p_personal_ph_extn, x_pwd_encrypt,
                p_comments, SYSDATE, fnd_profile.VALUE ('USER_ID'), SYSDATE,
                fnd_profile.VALUE ('USER_ID'), fnd_global.login_id
               );

   COMMIT;
   --Returning the Status
   x_return := 'S';
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      x_return := 'E';
      DBMS_OUTPUT.put_line ('Exception:NO_DATA_FOUND:' || SQLERRM);
   WHEN OTHERS
   THEN
      x_return := 'E';
      DBMS_OUTPUT.put_line ('Exception:When others :' || SQLERRM);
END xx_jtf_istore_user_data_prc;
/
