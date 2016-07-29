DROP FUNCTION APPS.XX_FND_ISITOK_2SENDEMAIL_FNC;

CREATE OR REPLACE FUNCTION APPS."XX_FND_ISITOK_2SENDEMAIL_FNC" (p_in_role IN varchar2)
   RETURN varchar2
/*===========================================================================+
 | Author:  Karthikeyan Mohan                                                |
 | Company: IBM Global Business Services                                     |
 | Contact: kmohan@us.ibm.com                                                |
 +===========================================================================+
 |                                                                           |
 | FILENAME                                                                  |
 |      xxfndisokemail.fnc                                                        |
 |                                                                           |
 | DESCRIPTION                                                               |
 |      Trigger body that overrides the recipient role based on the set up   |
 |      The following are the set-ups required for this trigger to work      |
 |             1. XX_FND_ALLOWED_EMAIL_ROLES  Lookup Setup                   |
 |             2. XX_FND_EMAIL_EXCEPTIONS     Excluded Email Addresses Table |
 |                                                                           |
 |  LOGIC  - Trigger invokes this function. Firstly,it checks if the role    |
 |           sent by trigger is existing in wf_local_roles. If it does,      |
 |           it checks if email address of that role is present in           |
 |           exceptions table. If it does, it returns FALSE. ELSE            |
 |           it will check if the person can be sent an email.               |
 |           If yes, returns TRUE, else false.                               |
 |                                                                           |
 | DEPENDENCIES                                                              |
 |---------------------------------------------------------------------------|
 | S.No.   | Object Name                                  | Type             |
 |         |                                              |                  |
 |---------------------------------------------------------------------------|
 |   1     | XX_FND_ALLOWED_EMAIL_ROLES                   | Lookup           |
 |   2     | XX_FND_EMAIL_EXCEPTIONS                      | Table            |
 |---------------------------------------------------------------------------|
 |                                                                           |
 | HISTORY                                                                   |
 |      kmohan             CREATION               10-Aug-10                  |
 |      Dinesh             INTEGRA MODIFICATION   18-Jul-12                  |
 +===========================================================================*/
IS
   x_ret_value    varchar2 (200) := 'FALSE';
   x_temp         number (15) := 0;
   x_allowed         number (15) := 0;
   x_email        wf_local_roles.email_address%TYPE;
   exp_block_email exception;


   CURSOR c_chk_dyn
   IS
       SELECT UPPER (email_address)
         FROM wf_local_roles
        WHERE  name = p_in_role
          AND orig_system IN ('PER', 'WF_LOCAL_USERS');


BEGIN
   OPEN c_chk_dyn;

   FETCH c_chk_dyn INTO x_email;

   CLOSE c_chk_dyn;

   IF x_email IS NULL THEN
   	RAISE exp_block_email;
   END IF;

   ---- Returns 1 when email should not be sent and 0 when it should be sent
   SELECT count(1)
   INTO x_temp
   FROM xx_fnd_email_exceptions
   WHERE UPPER(email_address) = x_email
   AND enabled_flag = 'Y';

   IF x_temp = 0 THEN

       SELECT COUNT (1)
         INTO x_allowed
         FROM fnd_lookup_values
        WHERE     lookup_type = 'XX_FND_ALLOWED_EMAIL_ROLES'
              AND enabled_flag = 'Y'
              AND TRUNC (SYSDATE) BETWEEN TRUNC (start_date_active) AND TRUNC (NVL (end_date_active, SYSDATE + 12))
              AND lookup_code = p_in_role
              AND language = USERENV('LANG');

      --- Should not get email as the person is not in allowed email list
      IF x_allowed = 0
      THEN
         RAISE exp_block_email;
      ELSE
      	 x_ret_value := 'TRUE';
      END IF;

    ---- Person is in exception list and hence no email should be sent
   ELSE
	RAISE exp_block_email;
   END IF;

   RETURN x_ret_value;

EXCEPTION
   WHEN exp_block_email
   THEN
      x_ret_value := 'FALSE';
      RETURN x_ret_value;
   WHEN OTHERS
   THEN
      x_ret_value := 'FALSE';
      RETURN x_ret_value;
END xx_fnd_isitok_2sendemail_fnc;
/


GRANT EXECUTE ON APPS.XX_FND_ISITOK_2SENDEMAIL_FNC TO INTG_XX_NONHR_RO;
