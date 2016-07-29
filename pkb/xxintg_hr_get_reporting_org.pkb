DROP PACKAGE BODY APPS.XXINTG_HR_GET_REPORTING_ORG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_HR_GET_REPORTING_ORG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 17-SEP-2014
 File Name     : xxintg_hr_get_reporting_org.pkb
 Description   : This script creates the body of the package
                 xxintg_hr_get_reporting_org
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 17-Sep-2014 Jaya Maran Jayaraj       Initial Version
 13-Jan-2015 Jaya Maran Jayaraj       Modified for ticket#12273
*/
-------------------------------------------------------------------------
   FUNCTION get_reporting_org (p_person_id IN NUMBER, p_effective_date IN DATE)
      RETURN VARCHAR2
   AS
      CURSOR csr_get_sup_heirarchy
      IS
         SELECT     (SELECT person_id
                       FROM per_all_people_f
                      WHERE person_id = paf.person_id
                        AND trunc(p_effective_date) BETWEEN effective_start_date
                                        AND effective_end_date) tree
               FROM per_all_assignments_f paf
         START WITH paf.person_id = p_person_id                --17371--15258
                AND paf.primary_flag = 'Y'
                AND trunc(p_effective_date) BETWEEN paf.effective_start_date
                                AND paf.effective_end_date
         CONNECT BY paf.person_id = PRIOR paf.supervisor_id
                AND paf.primary_flag = 'Y'
                AND trunc(p_effective_date) BETWEEN paf.effective_start_date
                                AND paf.effective_end_date;

      CURSOR csr_udt_report_org (x_person_id IN VARCHAR2)
      IS
         SELECT pci.VALUE person_id, user_column_name reporting_org
           FROM pay_user_column_instances_f pci,
                pay_user_rows_f pur,
                pay_user_columns_v puc,
                pay_user_tables_v put
          WHERE pci.user_row_id = pur.user_row_id
            AND pci.user_column_id = puc.user_column_id
            AND puc.user_table_id = put.user_table_id
            AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
            AND trunc(p_effective_date) BETWEEN pci.effective_start_date
                                    AND pci.effective_end_date
            AND trunc(p_effective_date) BETWEEN pur.effective_start_date
                                    AND pur.effective_end_date
            AND pur.row_low_range_or_name LIKE 'Executive'
            AND pci.VALUE = x_person_id;

      l_reporting_org   VARCHAR2 (100);
      l_found_flag      VARCHAR2 (1)   := 'N';
   BEGIN
   
     BEGIN
      FOR rec_get_sup_heirarchy IN csr_get_sup_heirarchy
      LOOP
         IF rec_get_sup_heirarchy.tree <> p_person_id
         THEN
            IF l_found_flag = 'N'
            THEN
               FOR rec_udt_report_org IN
                  csr_udt_report_org (rec_get_sup_heirarchy.tree)
               LOOP
                  l_reporting_org := NULL;

                  IF rec_udt_report_org.person_id =
                                                   rec_get_sup_heirarchy.tree
                  THEN
                     l_reporting_org := rec_udt_report_org.reporting_org;
                     l_found_flag := 'Y';
                     /*DBMS_OUTPUT.put_line (   'First_Query:-'
                                           || rec_get_sup_heirarchy.tree
                                          );
                     DBMS_OUTPUT.put_line (   'second_Query:-'
                                           || rec_udt_report_org.person_id
                                          );*/
                     EXIT;
                  END IF;
               END LOOP;
            ELSE
               EXIT;
            END IF;
         END IF;
      END LOOP;
      EXCEPTION 
        WHEN OTHERS THEN
            l_reporting_org := 'ERR';
      END;      
      
   
 RETURN l_reporting_org;

end get_reporting_org;
END xxintg_hr_get_reporting_org; 
/


GRANT EXECUTE ON APPS.XXINTG_HR_GET_REPORTING_ORG TO XXAPPSHRRO;
