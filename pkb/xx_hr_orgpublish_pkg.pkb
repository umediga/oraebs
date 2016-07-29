DROP PACKAGE BODY APPS.XX_HR_ORGPUBLISH_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_ORGPUBLISH_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 17-Dec-2012
 File Name     : XXHRORGPUBLISH.pks

 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 17-Dec-2012 Renjith               Initial Version
*/
----------------------------------------------------------------------

FUNCTION record_type (  p_emp_id            IN    NUMBER
                       ,p_job_title         IN    VARCHAR2
                       ,p_per_type          IN    VARCHAR2
                       ,p_position          IN    VARCHAR2)
RETURN VARCHAR2
IS
       x_sup_count      NUMBER :=0;
       x_intern_count   NUMBER :=0;
       x_admin_count    NUMBER :=0;
       x_position_count NUMBER :=0;
BEGIN
    SELECT  COUNT(*)
      INTO  x_sup_count
      FROM  per_all_assignments_f
     WHERE  supervisor_id = p_emp_id
       AND  SYSDATE BETWEEN effective_start_date AND effective_end_date;

     IF NVL(x_sup_count,0) > 0 THEN
        RETURN('M');
     ELSE
        SELECT  INSTR(p_job_title,'Admin Services')
          INTO  x_admin_count
          FROM  DUAL;
        IF NVL(x_admin_count,0) > 0 THEN
           RETURN('A');
        ELSE
           SELECT  INSTR(p_job_title,'Intern')
             INTO  x_intern_count
             FROM  DUAL;
           IF NVL(x_intern_count,0) > 0 THEN
              RETURN('U');
           ELSE
              SELECT  INSTR(p_position,'Intern')
                INTO  x_position_count
                FROM  DUAL;
              IF NVL(x_position_count,0) > 0 THEN
                 RETURN('U');
              ELSE
                 IF p_per_type = 'CWK' THEN
                   RETURN('C');
                 ELSE
                   RETURN(' ');
                 END IF;
              END IF;
           END IF;
        END IF;
     END IF;
EXCEPTION
     WHEN OTHERS THEN
         RETURN(' ');
END record_type;
----------------------------------------------------------------------
END xx_hr_orgpublish_pkg;
/
