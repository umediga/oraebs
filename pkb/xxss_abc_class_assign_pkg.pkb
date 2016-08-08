CREATE OR REPLACE PACKAGE BODY APPS.XXSS_ABC_CLASS_ASSIGN_PKG
AS
   /**************************************************************************************
   *   Copyright (c) SeaSpine
   *   All rights reserved
   ***************************************************************************************
   *
   *   HEADER
   *   Package Body
   *
   *   PROGRAM NAME
   *   XXSS_ABC_CLASS_ASSIGN_PKG.pkb
   *
   *   DESCRIPTION
   *   Concurrent program to auto assign Class C to all new items that are transactable, stockable and cycle count enabled in a specfic org and assignment group
   *
   *   USAGE
   *   Enable new items to be included in Cycle Count
   *
   *   PARAMETERS
   *   ==========
   *   NAME                DESCRIPTION
   *   ----------------- ------------------------------------------------------------------
   *   (1). p_inv_org_id     Inventory Organization ID
   *   (2). p_abc_grp_id     ABC assignment group id
   *
   *
   *   CALLED BY
   *   Sea Spine Auto Item Addition to ABC Assignment Group Concurrent Program
   *
   *   HISTORY
   *   =======
   *
   *   VERSION  DATE          AUTHOR(S)                 DESCRIPTION
   *   -------  -----------   ----------------------    ---------------------------------------------
   *   1.0      24-MAY-2016   Uma Ediga                 Initially created (Ticket# 00008241)
   *
   ***************************************************************************************/
   PROCEDURE ss_derive_inv_name (p_inv_org_id     IN     NUMBER,
                                 p_abc_grp_id     IN     NUMBER,
                                 x_inv_org_code      OUT VARCHAR2,
                                 x_abc_grp_name      OUT VARCHAR2)
   AS
   BEGIN
      SELECT mp.organization_code, masg.assignment_group_name
        INTO x_inv_org_code, x_abc_grp_name
        FROM mtl_parameters mp, mtl_abc_assignment_groups masg
       WHERE     mp.organization_id = masg.organization_id
             AND mp.organization_id = p_inv_org_id
             AND masg.assignment_group_id = p_abc_grp_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
               'Error while deriving Org code and ABC Group Name'
            || SQLCODE
            || ':'
            || SUBSTR (SQLERRM, 1, 200));
   END ss_derive_inv_name;

   PROCEDURE exec_main_pr (p_errbuf          OUT VARCHAR2,
                           p_retcode         OUT NUMBER,
                           p_inv_org_id   IN     NUMBER,
                           p_abc_grp_id   IN     NUMBER)
   AS
      l_cnt_items          NUMBER := 0;
      l_cnt_recs           NUMBER := 0;
      l_abc_grp_name       mtl_abc_assignment_groups.assignment_group_name%TYPE;
      l_inv_org_code       mtl_parameters.organization_code%TYPE;
      l_abc_class_c_id     mtl_abc_classes.abc_class_id%TYPE;
      l_abc_class_c_name   mtl_abc_classes.abc_class_name%TYPE;
      l_abc_class_desc     mtl_abc_classes.description%TYPE;
      l_user_name          NUMBER DEFAULT fnd_global.user_id;
      
      /**
      * Select items that are are stock enabled, transactable, cycle count enabled
      */
      CURSOR csr_abc_items (
         cp_inv_org_id    NUMBER,
         cp_abc_grp_id    NUMBER)
      IS
         SELECT msi.segment1, msi.inventory_item_id
           FROM mtl_system_items_b msi
          WHERE     msi.organization_id = cp_inv_org_id
                AND NVL (msi.stock_enabled_flag, 'N') = 'Y'
                AND NVL (msi.mtl_transactions_enabled_flag, 'N') = 'Y'
                AND NVL (msi.cycle_count_enabled_flag, 'N') = 'Y'
                AND NOT EXISTS
                       (SELECT mas.inventory_item_id
                          FROM mtl_abc_assignment_groups mbsg,
                               mtl_abc_assignments mas
                         WHERE     mas.inventory_item_id =
                                      msi.inventory_item_id
                               AND mbsg.organization_id = msi.organization_id
                               AND mas.assignment_group_id =
                                      mbsg.assignment_group_id
                               AND mbsg.assignment_group_id = cp_abc_grp_id);
   BEGIN
      BEGIN
         fnd_file.put_line (fnd_file.LOG,
                            'Inventory Org ID:  ' || p_inv_org_id);
         fnd_file.put_line (fnd_file.LOG,
                            'ABC Assigment Group ID:  ' || p_abc_grp_id);

         IF (p_inv_org_id IS NULL OR p_abc_grp_id IS NULL)
         THEN
            fnd_file.put_line (fnd_file.output, 'Parameters:      ');
            fnd_file.put_line (fnd_file.output, LPAD (' ', 35, '*'));
            fnd_file.put_line (fnd_file.output,
                               'Org Code             :    ' || p_inv_org_id);
            fnd_file.put_line (fnd_file.output,
                               'ABC Group Name       :    ' || p_abc_grp_id);
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (fnd_file.output, LPAD (' ', 120, '-'));
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (
               fnd_file.output,
               'Please provide Inventory Org and ABC Assignment group to assign new items if any to Class C of the specified ABC group.');
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (fnd_file.output, LPAD (' ', 120, '-'));
         ELSE
            ss_derive_inv_name (p_inv_org_id,
                                p_abc_grp_id,
                                l_inv_org_code,
                                l_abc_grp_name);
            fnd_file.put_line (fnd_file.LOG,
                               'Inventory Org code:  ' || l_inv_org_code);
            fnd_file.put_line (
               fnd_file.LOG,
               'ABC Assigment Group Name:  ' || l_abc_grp_name);
            fnd_file.put_line (fnd_file.output, 'Parameters:      ');
            fnd_file.put_line (fnd_file.output, LPAD (' ', 35, '*'));
            fnd_file.put_line (fnd_file.output,
                               'Org Code          	:    ' || l_inv_org_code);
            fnd_file.put_line (
               fnd_file.output,
               'ABC Group Name	        :    ' || l_abc_grp_name);
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (fnd_file.output, '      ');
            fnd_file.put_line (fnd_file.output, LPAD (' ', 140, '-'));
            fnd_file.put_line (
               fnd_file.output,
                  RPAD ('S.NO', 11, '  ')
               || RPAD ('Item Number', 51, '  ')
               || RPAD ('ABC Group Name', 50, '   ')
               || RPAD ('Status Message', 30, '   '));
            fnd_file.put_line (fnd_file.output, LPAD (' ', 140, '-'));

            ---Check if there are any items in the given Inv org which are
            ---STOCK_ENABLED_FLAG,MTL_TRANSACTIONS_ENABLED_FLAG and CYCLE_COUNT_ENABLED_FLAG are not
            --- assigned to any class of this ABC group
            SELECT COUNT (*)
              INTO l_cnt_items
              FROM mtl_system_items_b msi
             WHERE     msi.organization_id = p_inv_org_id
                   AND NVL (msi.stock_enabled_flag, 'N') = 'Y'
                   AND NVL (msi.mtl_transactions_enabled_flag, 'N') = 'Y'
                   AND NVL (msi.cycle_count_enabled_flag, 'N') = 'Y'
                   AND NOT EXISTS
                          (SELECT mas.inventory_item_id
                             FROM mtl_abc_assignment_groups mbsg,
                                  mtl_abc_assignments mas
                            WHERE     mas.inventory_item_id =
                                         msi.inventory_item_id
                                  AND mbsg.organization_id =
                                         msi.organization_id
                                  AND mas.assignment_group_id =
                                         mbsg.assignment_group_id
                                  AND mbsg.assignment_group_id = p_abc_grp_id);

            fnd_file.put_line (
               fnd_file.LOG,
                  'No of Items: '
               || l_cnt_items
               || ' of  Inv Org:'
               || l_inv_org_code
               || ' are to been assigned to ABC Group:'
               || l_abc_grp_name);

            IF l_cnt_items > 0
            THEN
               --Derive the Group Name of ABC
               BEGIN
                  SELECT assignment_group_name,
                         abc_class_id,
                         abc_class_name,
                         abc_class_description
                    INTO l_abc_grp_name,
                         l_abc_class_c_id,
                         l_abc_class_c_name,
                         l_abc_class_desc
                    FROM mtl_abc_assgn_group_classes_v
                   WHERE     assignment_group_id = p_abc_grp_id
                         AND abc_class_name = 'C';

                  fnd_file.put_line (fnd_file.LOG,
                                     'ABC Group Name: ' || l_abc_grp_name);
                  fnd_file.put_line (
                     fnd_file.LOG,
                     'ABC class Name: ' || l_abc_class_c_name);
                  fnd_file.put_line (fnd_file.LOG,
                                     'ABC Class C ID: ' || l_abc_class_c_id);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     fnd_file.put_line (
                        fnd_file.LOG,
                        'Error:CLASS C of ABC group is not setup in the instance');
                     p_retcode := 1;
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line (
                        fnd_file.LOG,
                           'Error while derving for the CLASS C of ABC group:'
                        || SUBSTR (SQLERRM, 1, 200));
               END;

               l_cnt_recs := 0;

               IF l_abc_class_c_id > 0              --If CLASS C is setup then
               THEN
                  FOR csr_rec_abc
                     IN csr_abc_items (p_inv_org_id, p_abc_grp_id)
                  LOOP
                     --Insert directly in to the base table to Assign the class C of th4 ABC group
                     INSERT INTO mtl_abc_assignments (inventory_item_id,
                                                      assignment_group_id,
                                                      abc_class_id,
                                                      last_update_date,
                                                      last_updated_by,
                                                      creation_date,
                                                      created_by)
                          VALUES (csr_rec_abc.inventory_item_id,
                                  p_abc_grp_id,
                                  l_abc_class_c_id,
                                  SYSDATE,
                                  l_user_name,
                                  SYSDATE,
                                  l_user_name);

                     COMMIT;
                     --ROLLBACK;
                     l_cnt_recs := NVL (l_cnt_recs, 0) + 1;
                     fnd_file.put_line (
                        fnd_file.output,
                           RPAD (l_cnt_recs || '.', 10)
                        || ' '
                        || RPAD (csr_rec_abc.segment1, 50)
                        || ' '
                        || RPAD (l_abc_grp_name, 50)
                        || ' '
                        || 'Success');
                  END LOOP;                             --end of loop of items

                  fnd_file.put_line (fnd_file.output, LPAD (' ', 140, '-'));
                  --Number of items to be assignedle
                  fnd_file.put_line (
                     fnd_file.output,
                        'No of Items : '
                     || l_cnt_recs
                     || ' assigned to the Class C of ABC group: '
                     || l_abc_grp_name);
               ELSE
                  fnd_file.put_line (
                     fnd_file.output,
                     'Error:CLASS C of ABC group is not setup in the instance');
                  fnd_file.put_line (fnd_file.output, LPAD (' ', 140, '-'));
               END IF;
            ELSE
               fnd_file.put_line (
                  fnd_file.output,
                  'No new item meeting selection criteria found.');
               fnd_file.put_line (fnd_file.output, LPAD (' ', 140, '-'));
            END IF;                                        --no of items check
         END IF;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'Exception in main block , ' || SQLCODE || SUBSTR (SQLERRM, 1, 200));
   END exec_main_pr;
END XXSS_ABC_CLASS_ASSIGN_PKG;
/