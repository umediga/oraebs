DROP FUNCTION APPS.XXOZF_VALIDATELOGINWEBLOGIC;

CREATE OR REPLACE FUNCTION APPS.XXOZF_ValidateLoginWeblogic(uname IN VARCHAR2)
      RETURN VARCHAR2
   AS
      res   VARCHAR2 (30);
   BEGIN
      SELECT   (SELECT   decrypt (
                            ( (SELECT   (SELECT   decrypt (
                                                     ( (SELECT   ('GUEST/ORACLE')
                                                          FROM   DUAL)),
                                                     usertable.encrypted_foundation_password
                                                  )
                                           FROM   DUAL)
                                           AS apps_password
                                 FROM   fnd_user usertable
                                WHERE   usertable.user_name =
                                           ( (SELECT   SUBSTR (
                                                          'GUEST/ORACLE',
                                                          1,
                                                          INSTR (
                                                             'GUEST/ORACLE',
                                                             '/'
                                                          )
                                                          - 1
                                                       )
                                                FROM   DUAL)))),
                            usertable.encrypted_user_password
                         )
                  FROM   DUAL)
                  AS encrypted_user_password
        INTO   res
        FROM   fnd_user usertable
       WHERE   usertable.user_name LIKE UPPER (uname);
      RETURN RES;
   END XXOZF_ValidateLoginWeblogic;
/
