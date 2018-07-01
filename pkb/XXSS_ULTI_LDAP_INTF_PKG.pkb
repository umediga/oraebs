/* Formatted on 3/23/2018 3:02:36 PM (QP5 v5.277) */
CREATE OR REPLACE PACKAGE BODY APPS.XXSS_ULTI_LDAP_INTF_PKG
IS
   /**
     * ========================================================================<br/>
     * Case:            31466<br/>
     * Description:     Ultipro to AD Report/Interface(SeaSpine Ulti Ldap Interface)<br/>
     * Commit inside:   YES<br/>
     * Rollback inside: NO<br/>
     * ------------------------------------------------------------------------<br/>
     * $Header: oraeb/pkb/XXSS_ULTI_LDAP_INTF_PKG,v 1.0 2018/03/12 Uma Ediga $<br/>
     * ========================================================================<br/>
     * @SeaSpine Inc
     *
     */

   x_request_id   NUMBER := FND_GLOBAL.CONC_REQUEST_ID;


   /**
      * Removes special characters from a string <br/>
      *
      * @param p_name           String
      * @return                 String <br/>
      */
   FUNCTION special_char_rep (p_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_name_char   VARCHAR2 (240);
   BEGIN
      SELECT TRANSLATE (
                REPLACE (REPLACE (p_name, CHR (50054), 'AE'),
                         CHR (50086),
                         'ae'),
                   CHR (50052)
                || CHR (50053)
                || CHR (50048)
                || CHR (50049)
                || CHR (50051)
                || CHR (50084)
                || CHR (50080)
                || CHR (50081)
                || CHR (50083)
                || CHR (50085)
                || CHR (50055)
                || CHR (50087)
                || CHR (50056)
                || CHR (50057)
                || CHR (50058)
                || CHR (50059)
                || CHR (50088)
                || CHR (50089)
                || CHR (50090)
                || CHR (50091)
                || CHR (50060)
                || CHR (50061)
                || CHR (50062)
                || CHR (50063)
                || CHR (50092)
                || CHR (50093)
                || CHR (50094)
                || CHR (50095)
                || CHR (50065)
                || CHR (50097)
                || CHR (50100)
                || CHR (49850)
                || CHR (50098)
                || CHR (50099)
                || CHR (50101)
                || CHR (50102)
                || CHR (50066)
                || CHR (50067)
                || CHR (50068)
                || CHR (50069)
                || CHR (50070)
                || CHR (50075)
                || CHR (50073)
                || CHR (50074)
                || CHR (50076)
                || CHR (50105)
                || CHR (50106)
                || CHR (50107)
                || CHR (50108),
                'AAAAAAaaaaCcEEEEeeeeIIIIiiiiNnooooooOOOOOUUUUuuuu')
        INTO x_name_char
        FROM DUAL;

      RETURN (x_name_char);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_name_char := NULL;
         RETURN (x_name_char);
   END special_char_rep;


   /**
      * Gets LDAP account for a given employee name
      *
      * @param p_emp_name           String
      * @return                     String <br/>
      */
   FUNCTION get_ldap_user_name (p_emp_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_ldap_message     DBMS_LDAP.MESSAGE;
      v_ldap_entry       DBMS_LDAP.MESSAGE;
      v_returnval        PLS_INTEGER;
      v_session          DBMS_LDAP.session;
      v_str_collection   DBMS_LDAP.string_collection;
      v_entry_index      PLS_INTEGER;
      v_ber_element      DBMS_LDAP.ber_element;
      v_attr_index       PLS_INTEGER;
      v_dn               VARCHAR2 (256);
      v_attrib_name      VARCHAR2 (256);
      i                  PLS_INTEGER;
      v_info             DBMS_LDAP.string_collection;
      v_ldap_base        VARCHAR2 (256);
      v_ldap_port        VARCHAR2 (256);
      v_ldap_host        VARCHAR2 (256);
      v_ldap_user        VARCHAR2 (256);
      v_ldap_passwd      VARCHAR2 (256);
      v_ldap_user_name   VARCHAR2 (1000);
   BEGIN
      DBMS_OUTPUT.put_line ('Employee Name:' || p_emp_name);
      v_ldap_host := 'uscaradc001.seaspine.com';
      v_ldap_port := '389';
      v_ldap_user := 'svcLDAPLook';
      v_ldap_passwd := 'LD533Up!';
      v_ldap_base := 'dc=seaspine,dc=com';

      v_returnval := -1;



      DBMS_LDAP.use_exception := TRUE;
      v_session :=
         DBMS_LDAP.init (hostname => v_ldap_host, portnum => v_ldap_port);


      -- Authenticate user in ldap server

      v_returnval :=
         DBMS_LDAP.simple_bind_s (ld       => v_session,
                                  dn       => v_ldap_user,
                                  passwd   => v_ldap_passwd);


      v_str_collection (1) := 'sAMAccountName';
      v_returnval :=
         DBMS_LDAP.search_s (ld         => v_session,
                             base       => v_ldap_base,
                             scope      => DBMS_LDAP.scope_subtree,
                             filter     => 'cn~=' || p_emp_name,
                             attrs      => v_str_collection,
                             attronly   => 0,
                             res        => v_ldap_message);

      --Use first_entry function to return the first entry in a result set
      v_ldap_entry :=
         DBMS_LDAP.first_entry (ld => v_session, msg => v_ldap_message);
      v_entry_index := 1;

      -- Get attributes of each entry found
      WHILE v_ldap_entry IS NOT NULL
      LOOP
         -- print the current entry
         v_dn := DBMS_LDAP.get_dn (ld => v_session, ldapentry => v_ldap_entry);

         v_attrib_name :=
            DBMS_LDAP.first_attribute (ld          => v_session,
                                       ldapentry   => v_ldap_entry,
                                       ber_elem    => v_ber_element);

         v_attr_index := 1;

         WHILE v_attrib_name IS NOT NULL
         LOOP
            v_info :=
               DBMS_LDAP.get_values (ld          => v_session,
                                     ldapentry   => v_ldap_entry,
                                     attr        => v_attrib_name);

            IF v_info.COUNT > 0
            THEN
               FOR i IN v_info.FIRST .. v_info.LAST
               LOOP
                  v_ldap_user_name := SUBSTR (v_info (i), 1, 200);
               END LOOP;
            END IF;


            --Function next_attribute return the next attribute of a given entry in the result set
            v_attrib_name :=
               DBMS_LDAP.next_attribute (ld          => v_session,
                                         ldapentry   => v_ldap_entry,
                                         ber_elem    => v_ber_element);
            v_attr_index := v_attr_index + 1;
         END LOOP;

         DBMS_LDAP.ber_free (ber => v_ber_element, freebuf => 0);

         v_ldap_entry :=
            DBMS_LDAP.next_entry (ld => v_session, msg => v_ldap_entry);


         v_entry_index := v_entry_index + 1;
      END LOOP;



      -- Use msgfree function to free up the chain of messages associated with the message handle returned by synchronous search functions


      v_returnval := DBMS_LDAP.msgfree (lm => v_ldap_message);


      v_returnval := DBMS_LDAP.unbind_s (ld => v_session);

      IF (v_ldap_user_name IS NULL)
      THEN
         BEGIN
            SELECT DISTINCT
                      REPLACE (first_name, ' ', '')
                   || '.'
                   || REPLACE (last_name, ' ', '')
              INTO v_ldap_user_name
              FROM per_all_people_f
             WHERE     full_name LIKE
                             SUBSTR (p_emp_name, 1, LENGTH (p_emp_name) - 5)
                          || '%'
                   AND p_emp_name LIKE '%.%';
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
               v_ldap_user_name := NULL;
         END;
      --DBMS_OUTPUT.PUT_LINE('Error'||substr(sqlerrm,1,200));

      END IF;



      IF v_ldap_user_name IS NULL
      THEN
         DBMS_OUTPUT.PUT_LINE (
               '1:p_emp_name='
            || p_emp_name
            || ', ldap_user_name='
            || v_ldap_user_name);

         BEGIN
            SELECT ldap_user_name
              INTO v_ldap_user_name
              FROM XXINTG.XXSS_LDAP_EXCEPTIONS
             WHERE     UPPER (special_char_rep (employee_name)) =
                          (SELECT UPPER (employee_name)
                             FROM XXINTG.XXSS_ULTI_EMP_DATA_STG a
                            WHERE     status = 'NEW'
                                  AND UPPER (
                                         special_char_rep (
                                               REPLACE (a.last_name, '"', '')
                                            || ', '
                                            || REPLACE (a.first_name,
                                                        '"',
                                                        ''))) =
                                         UPPER (
                                            special_char_rep (p_emp_name))
                                  AND ROWNUM <= 1)
                   AND ROWNUM <= 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.PUT_LINE ('eXC:' || SUBSTR (SQLERRM, 1, 200));
         END;
      END IF;

      DBMS_OUTPUT.PUT_LINE (
            '2.p_emp_name='
         || p_emp_name
         || ', ldap_user_name='
         || v_ldap_user_name);
      RETURN v_ldap_user_name;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE (
               'Error for p_emp_name['
            || p_emp_name
            || '] '
            || SUBSTR (SQLERRM, 1, 200));
         RETURN '';
   END get_ldap_user_name;

/**
* Uses data in XXSS_ULTI_EMP_DATA_STG and cross checks against LDAP to render final formatted output
* @param p_errbuf       return code, 0=ok, 1=warning, 2=error
* @param p_retcode      return message
*/
   PROCEDURE main (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2)
   IS
      CURSOR c_all_emp
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE status = 'NEW';

      CURSOR c_ldap_user_data_m
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE     status = 'NEW'
                AND mobile_phone_number IS NOT NULL
                AND ldap_user_name IS NOT NULL
                AND ldap_sup_user_name IS NOT NULL
                AND status <> 'PROCESSED';

      CURSOR c_ldap_user_data_nm
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE     status = 'NEW'
                AND mobile_phone_number IS NULL
                AND ldap_user_name IS NOT NULL
                AND ldap_sup_user_name IS NOT NULL
                AND status <> 'PROCESSED';

      CURSOR c_ldap_user_data_remote_m
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE     status = 'NEW'
                AND mobile_phone_number IS NOT NULL
                AND ldap_user_name IS NOT NULL
                AND ldap_sup_user_name IS NOT NULL
                AND city IS NULL
                AND status <> 'PROCESSED';

      CURSOR c_ldap_user_data_remote_nm
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE     status = 'NEW'
                AND mobile_phone_number IS NULL
                AND ldap_user_name IS NOT NULL
                AND ldap_sup_user_name IS NOT NULL
                AND city IS NULL
                AND status <> 'PROCESSED';

      CURSOR c_ldap_user_data_e
      IS
         SELECT *
           FROM XXINTG.XXSS_ULTI_EMP_DATA_STG
          WHERE     (ldap_user_name IS NULL OR ldap_sup_user_name IS NULL)
                AND status <> 'PROCESSED';

      x_ret_code         NUMBER := 0;
      x_err_msg          VARCHAR2 (3000);
      x_efile_error      EXCEPTION;
      x_shipment_error   EXCEPTION;
      x_file_name        VARCHAR2 (300);
      l_request_id       NUMBER;
      l_counter          NUMBER;
   BEGIN
      -- Initialize
      mo_global.init ('ONT');
      x_request_id := fnd_global.conc_request_id;
      fnd_file.put_line (fnd_file.LOG, x_request_id);

      -- Update user_name, supervisor name, mobile phone number
      FOR k IN c_all_emp
      LOOP
         BEGIN
            UPDATE XXINTG.XXSS_ULTI_EMP_DATA_STG a
               SET LDAP_USER_NAME =
                      get_ldap_user_name (
                         special_char_rep (
                               REPLACE (a.last_name, '"', '')
                            || ', '
                            || REPLACE (a.first_name, '"', ''))),
                   ldap_sup_user_name =
                      special_char_rep (
                         get_ldap_user_name (
                            REPLACE (a.supervisor_name, '"', '')))
             WHERE status = 'NEW' AND a.employee_name = k.employee_name;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,
                                  'Error while updating ldap user names');
         END;

         BEGIN
            UPDATE XXINTG.XXSS_ULTI_EMP_DATA_STG a
               SET mobile_phone_number =
                      (SELECT wireless_number
                         FROM XXINTG.XXSS_LDAP_MOBILE_PH_STG
                        WHERE     UPPER (user_name) =
                                     UPPER (
                                        a.FIRST_NAME || ' ' || A.LAST_NAME)
                              AND ROWNUM <= 1)
             WHERE     1 = 1                 -- NVL (ldap_user_name, '') <> ''
                   AND status = 'NEW'
                   AND a.employee_name = k.employee_name;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,
                                  'Error while updating mobile phone number');
         END;

         -- Update status for records that don't have all the required fields
         UPDATE XXINTG.XXSS_ULTI_EMP_DATA_STG a
            SET status = 'ERROR'
          WHERE     (ldap_user_name = '' OR ldap_sup_user_name = '')
                AND status = 'NEW'
                AND a.employee_name = k.employee_name;

         COMMIT;
      END LOOP;

      -- Retrieve ldap user data and generate output
      fnd_file.put_line (
         fnd_file.output,
         'List of employees with mobile phone number available');
      fnd_file.put_line (
         fnd_file.output,
         '====================================================');


      fnd_file.put_line (
         fnd_file.output,
         'SAM,Supervisor,Address,City,State,ZipCode,Country,Company,Office,Job_Title,Mobile');

      FOR k IN c_ldap_user_data_m
      LOOP
         fnd_file.put_line (
            fnd_file.output,
               k.ldap_user_name
            || ','
            || k.ldap_sup_user_name
            || ',"'
            || special_char_rep (k.address)
            || '",'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.state)
            || ','
            || special_char_rep (k.zip_code)
            || ','
            || special_char_rep (k.country)
            || ',Seaspine,'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.job_title)
            || ','
            || special_char_rep (k.mobile_phone_number));
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');

      fnd_file.put_line (
         fnd_file.output,
         'List of remote employees with mobile phone number available');
      fnd_file.put_line (
         fnd_file.output,
         '====================================================');


      fnd_file.put_line (
         fnd_file.output,
         'SAM,Supervisor,Address,State,Country,Company,Job_Title,Mobile');

      FOR k IN c_ldap_user_data_remote_m
      LOOP
         fnd_file.put_line (
            fnd_file.output,
               k.ldap_user_name
            || ','
            || k.ldap_sup_user_name
            || ',"'
            || special_char_rep (k.address)
            || '",'
            --|| special_char_rep (k.city)
            --|| ','
            || special_char_rep (k.state)
            || ','
            --|| special_char_rep (k.zip_code)
            --|| ','
            || special_char_rep (k.country)
            || ',Seaspine'
            --|| special_char_rep (k.city)
            || ','
            || special_char_rep (k.job_title)
            || ','
            || special_char_rep (k.mobile_phone_number));
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');


      fnd_file.put_line (
         fnd_file.output,
         'List of employees with no mobile phone number available');
      fnd_file.put_line (
         fnd_file.output,
         '====================================================');



      fnd_file.put_line (
         fnd_file.output,
         'SAM,Supervisor,Address,City,State,ZipCode,Country,Company,Office,Job_Title');

      FOR k IN c_ldap_user_data_nm
      LOOP
         fnd_file.put_line (
            fnd_file.output,
               k.ldap_user_name
            || ','
            || k.ldap_sup_user_name
            || ',"'
            || special_char_rep (k.address)
            || '",'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.state)
            || ','
            || special_char_rep (k.zip_code)
            || ','
            || special_char_rep (k.country)
            || ',Seaspine,'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.job_title));
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');

      fnd_file.put_line (
         fnd_file.output,
         'List of remote employees with mobile phone number not available');
      fnd_file.put_line (
         fnd_file.output,
         '====================================================');


      fnd_file.put_line (
         fnd_file.output,
         'SAM,Supervisor,Address,State,Country,Company,Job_Title');

      FOR k IN c_ldap_user_data_remote_nm
      LOOP
         fnd_file.put_line (
            fnd_file.output,
               k.ldap_user_name
            || ','
            || k.ldap_sup_user_name
            || ',"'
            || special_char_rep (k.address)
            || '",'
            --|| special_char_rep (k.city)
            --|| ','
            || special_char_rep (k.state)
            || ','
            --|| special_char_rep (k.zip_code)
            --|| ','
            || special_char_rep (k.country)
            || ',Seaspine'
            --|| special_char_rep (k.city)
            || ','
            || special_char_rep (k.job_title)                         --|| '"'
                                             );
      --|| special_char_rep (k.mobile_phone_number));
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');


      fnd_file.put_line (
         fnd_file.output,
         'List of employees for which ldap user name couldn''t be derived');
      fnd_file.put_line (
         fnd_file.output,
         '====================================================');



      fnd_file.put_line (
         fnd_file.output,
         'SAM,Supervisor,Address,City,State,ZipCode,Country,Company,Office,Job_Title,Mobile');

      FOR k IN c_ldap_user_data_e
      LOOP
         fnd_file.put_line (
            fnd_file.output,
               NVL (k.ldap_user_name, k.employee_name)
            || ','
            || NVL (k.ldap_sup_user_name, k.supervisor_name)
            || ',"'
            || special_char_rep (k.address)
            || '",'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.state)
            || ','
            || special_char_rep (k.zip_code)
            || ','
            || special_char_rep (k.country)
            || ',Seaspine,'
            || special_char_rep (k.city)
            || ','
            || special_char_rep (k.job_title)
            || ','
            || special_char_rep (k.mobile_phone_number));
      END LOOP;

      -- Update staging table with status PROCESSED

      UPDATE XXINTG.XXSS_ULTI_EMP_DATA_STG
         SET STATUS = 'PROCESSED'
       WHERE status = 'NEW';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         p_retcode := 2;
   END main;
----------------------------------------------------------------------
END XXSS_ULTI_LDAP_INTF_PKG;
/