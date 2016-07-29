DROP PACKAGE BODY APPS.XXINTG_APPROVAL_GROUP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_APPROVAL_GROUP_PKG" 
AS
   PROCEDURE xxintg_approval_group_pro (
      p_errbuf    OUT   VARCHAR2,
      p_retcode   OUT   VARCHAR2
   )
   IS
      CURSOR c_emp_pos
      IS
         SELECT *
           FROM xxintg_pos_changes
          WHERE p_prev_pos != p_curr_pos
          and TRUNC (created_date) = TRUNC (SYSDATE);
      obj_emp_pos   c_emp_pos%ROWTYPE;
   BEGIN
   fnd_file.put_line (fnd_file.output,
                         '<?xml version="1.0" encoding="UTF-8"?>'
                        );
                fnd_file.put_line (fnd_file.output, '<PERDUMMY1>');
      OPEN c_emp_pos;
      
     
      LOOP
         FETCH c_emp_pos
          INTO obj_emp_pos;

         EXIT WHEN c_emp_pos%NOTFOUND;

         BEGIN
            DECLARE
               CURSOR app_group
               IS
                  SELECT hou.NAME, pcf.control_function_name,
                         pcga.control_group_name
                    FROM hr_all_positions_f hapf,
                         po_position_controls_all ppca,
                         hr_operating_units hou,
                         po_control_functions pcf,
                         po_control_groups_all pcga
                   WHERE     hapf.NAME = obj_emp_pos.p_prev_pos
                         AND hapf.effective_end_date >= SYSDATE
                         AND hapf.position_id = ppca.position_id
                         AND ppca.org_id = hou.organization_id
                         AND pcf.control_function_id =
                                                      ppca.control_function_id
                         AND ppca.control_group_id = pcga.control_group_id
                         AND ppca.end_date IS NULL
                      OR ppca.end_date >= SYSDATE;

               obj_app_grp   app_group%ROWTYPE;
            BEGIN
               OPEN app_group;
                

               LOOP
                  FETCH app_group
                   INTO obj_app_grp;

                  EXIT WHEN app_group%NOTFOUND;

                  BEGIN
                      fnd_file.put_line
                                (fnd_file.LOG,
                                    'prev pos:  '
                                 || obj_emp_pos.p_prev_pos
                                 || 'curr pos: '
                                 || obj_emp_pos.p_curr_pos
                                );
                     fnd_file.put_line (fnd_file.output, '<APPROVAL_GROUP>');
                       fnd_file.put_line (fnd_file.output,
                                              '<PREV_POS>'
                                           || REPLACE (obj_emp_pos.p_prev_pos,
                                                       '&',
                                                       '&'||'amp;'
                                                      )
                                           || '</PREV_POS>'
                                          );
                                       
                                      fnd_file.put_line (fnd_file.output,
                                              '<CURR_POS>'
                                           || REPLACE (obj_emp_pos.p_curr_pos,
                                                       '&',
                                                       '&'||'amp;'
                                                      )
                                           || '</CURR_POS>'
                                          );
                                       
                                       
                                       
                                        fnd_file.put_line (fnd_file.output,
                                              '<ORG>'
                                           || obj_app_grp.NAME
                                           || '</ORG>'
                                          );
                                                            
                                         fnd_file.put_line (fnd_file.output,
                                              '<DOC>'
                                           || obj_app_grp.control_function_name
                                           || '</DOC>'
                                          );
                                        
                                         fnd_file.put_line (fnd_file.output,
                                              '<APP_GRP>'
                                           || REPLACE (obj_app_grp.control_group_name,
                                                        '&',
                                                       '&'||'amp;'
                                                      )
                                           || '</APP_GRP>'
                                          );
                                      
                                       
                     fnd_file.put_line (fnd_file.output, '</APPROVAL_GROUP>');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                                (fnd_file.LOG,
                                    'No approval group found for prev pos:  '
                                 || obj_emp_pos.p_prev_pos
                                 || 'curr pos: '
                                 || obj_emp_pos.p_curr_pos
                                );
                  END;
               END LOOP;
                
               CLOSE app_group;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                                (fnd_file.LOG,
                                    'No approval group found for prev pos:  '
                                 || obj_emp_pos.p_prev_pos
                                 || 'curr pos: '
                                 || obj_emp_pos.p_curr_pos
                                );
            END;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                                (fnd_file.LOG,
                                    'No approval group found for prev pos:  '
                                 || obj_emp_pos.p_prev_pos
                                 || 'curr pos: '
                                 || obj_emp_pos.p_curr_pos
                                );
         END;
      END LOOP;

     
     
      CLOSE c_emp_pos;
      fnd_file.put_line (fnd_file.output, '</PERDUMMY1>');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error IN approval group:  ' || SQLERRM
                           );
   END xxintg_approval_group_pro;
END xxintg_approval_group_pkg; 
/
