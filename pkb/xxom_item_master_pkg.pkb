DROP PACKAGE BODY APPS.XXOM_ITEM_MASTER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_ITEM_MASTER_PKG" 
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_ITEM_MASTER_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     2.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
*  Is the Ascension Item # still needed.  Is it being converted in item master?
******************************************************************************************/
IS
   PROCEDURE intg_item_extract    (errbuf                 OUT VARCHAR2,
                                   retcode                OUT VARCHAR2,
                                   p_organization_id   IN     NUMBER)
   IS

CURSOR item_cur
IS
  SELECT   NULL Transaction_ID,
           NULL AS Transaction_Date,
           msi.segment1 AS Item_Number,
           msi.description AS Item_Description,
           msi.inventory_item_id AS Inventory_Item_Id,
           cic.item_cost AS Item_Cost,
           '0' AS Autorestock,
           /*
           (SELECT   DECODE (attribute1, 'Y', 1, 0)
              FROM   apps.bom_bill_of_materials bbm
             WHERE   bbm.organization_id = p_organization_id
              AND bbm.assembly_item_id = msi.inventory_item_id
            )  AS InstrumentSet,
            */
            DECODE (msi.item_type, 'K', 1, 0) AS InstrumentSet,
           (SELECT   meaning
              FROM   apps.fnd_lookup_values_vl flv
             WHERE       lookup_type = 'ITEM_TYPE'
                     AND enabled_flag = 'Y'
                     AND lookup_code = msi.item_type
                     AND view_application_id = 3
           )  AS Item_Type,
           msi.inventory_item_status_code AS Item_Status,
           (CASE
               WHEN lot_control_code = 2 OR serial_number_control_code = 5
               THEN
                  '1'
               ELSE
                  '0'
            END)
              AS Lot_Serial_Control,
           DECODE (msi.customer_order_flag, 'Y', 1, 0) AS Customer_Ordered_Flag,
           DECODE (msi.shelf_life_code, 'Y', 1, 0) AS Expiration_Control,
           DECODE (msi.stock_enabled_flag, 'Y', 1, 0) AS Inventory_Tracked,
           abc.abc_class_name,
           null default_loan_days,
           snm.concatenated_segments Sales_and_Marketing_Info,
           null, -- msi.attribute14,  -- Ascension item# no longer needed per Mike/MB
           snm.snm_division,
           snm.product_segment,
           snm.surgery_type,
           snm.brand,
           snm.product_class,
           snm.product_type           
    FROM   apps.mtl_system_items_b msi,
           -- Stadnik - Commented and moved into the subquery to prevent duplicate entries
           -- xxom_item_master_stg xims,
           apps.cst_item_costs cic,
           (SELECT   abc_class_name, last_update_date, inventory_item_id
              FROM   apps.mtl_abc_assignments_v
             WHERE   organization_id = p_organization_id) ABC,
           (SELECT   mck.concatenated_segments,
                     mic.inventory_item_id,
                     mic.last_update_date,
                     mck.segment4 snm_division,
                     mck.segment10 product_segment,
                     mck.segment6 surgery_type,
                     mck.segment7 brand,
                     mck.segment8 product_class,
                     mck.segment9 product_type
              FROM   mtl_item_categories mic,
                     mtl_categories_kfv mck,
                     mtl_category_sets mcs
             WHERE       mck.category_id = mic.category_id
                     AND mic.organization_id = p_organization_id
                     AND mic.category_set_id = mcs.category_set_id
                     AND UPPER (mcs.category_set_name) =
                           UPPER ('SALES AND MARKETING')
                     AND mck.category_id = mic.category_id) snm
   WHERE       msi.inventory_item_id = cic.inventory_item_id(+)
           AND msi.organization_id = cic.organization_id(+)
           -- Stadnik - Commented and moved into the subquery to prevent duplicate entries
           -- AND xims.inventory_item_id (+) = msi.inventory_item_id
           AND cic.cost_type_id(+) = 1
           AND abc.inventory_item_id(+) = msi.inventory_item_id
           AND msi.organization_id = p_organization_id
           AND cic.organization_id(+) = p_organization_id
           AND snm.inventory_item_id(+) = msi.inventory_item_id
           AND GREATEST (
                 msi.last_update_date,
                         NVL (cic.last_update_date, msi.last_update_date),
                         NVL (abc.last_update_date, msi.last_update_date),
                         NVL (snm.last_update_date, msi.last_update_date)
                        ) >
                    NVL ((SELECT MAX (TO_DATE (transaction_date,'DD-MON-RRRR HH24:MI:SS'))
                            FROM xxom_item_master_stg
                           WHERE inventory_item_id = msi.inventory_item_id),
                         GREATEST (msi.last_update_date,
                                   NVL (cic.last_update_date, msi.last_update_date),
                                   NVL (abc.last_update_date, msi.last_update_date),
                                   NVL (snm.last_update_date, msi.last_update_date)
                                   ) - 1)

ORDER BY   msi.segment1;


   BEGIN
      BEGIN
         BEGIN
            SELECT   a.organization_code, b.name
              INTO   l_orgn_code, l_orgn_name
              FROM   apps.mtl_parameters_view a,
                     apps.hr_all_organization_units b
             WHERE   a.organization_id = b.organization_id
                     AND a.organization_id = p_organization_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (
                  fnd_file.LOG,
                  'Unable to fetch organization code and organization_name values for organization_id: '
                  || p_organization_id
               );
         END;

         apps.fnd_file.put_line (fnd_file.output,
                                 'Request Submission Date: ' || l_proc_date);
         apps.fnd_file.put_line (
            fnd_file.output, 'Interface Name: INTG Item Master Interface'
         );
         apps.fnd_file.put_line (fnd_file.output, ' ');
         apps.fnd_file.put_line (fnd_file.output, ' ');


         apps.fnd_file.put_line (
            fnd_file.output,
               'Organization Code: ' || l_orgn_code
            || ' And Organization Name: ' || l_orgn_name
         );

         FOR item_rec IN item_cur
         LOOP
            --inserting records into staging table XXOM_ITEM_MASTER_STG
            INSERT INTO XXOM_ITEM_MASTER_STG (
                                                             transaction_id,
                                                             transaction_date,
                                                             item_number,
                                                             item_description,
                                                             inventory_item_id,
                                                             item_cost,
                                                             autorestock,
                                                             instrumentset,
                                                             item_type,
                                                             item_status,
                                                             lot_serial_control,
                                                             customer_ordered_flag,
                                                             expiration_control,
                                                             inventory_tracked,
                                                             abc_cc_class,
                                                             default_loan_days,
                                                             division,
                                                             product_segment,
                                                             surgery_type,
                                                             brand,
                                                             product_class,
                                                             product_type,
                                                             sales_and_marketing_info,
                                                             exported_date,
                                                             status,
                                                             MESSAGE,
                                                             asc_item_number,
                                                             created_by,
                                                             last_updated_by,
                                                             creation_date,
                                                             last_update_date
                       )
              VALUES   
                       (
                        XXOM_ITEM_MASTER_STG_SEQ.NEXTVAL,   --transaction_id
                        l_proc_date,                        --transaction_date
                        item_rec.item_number,                      --item_number
                        item_rec.item_description,            --item_description
                        item_rec.inventory_item_id,          --inventory_item_id
                        item_rec.item_cost,                          --item_cost
                        item_rec.autorestock,                      --autorestock
                        item_rec.instrumentset,                  --instrumentset
                        item_rec.item_type,                          --item_type
                        item_rec.item_status,                      --item_status
                        item_rec.lot_serial_control,        --lot_serial_control
                        item_rec.customer_ordered_flag,  --customer_ordered_flag
                        item_rec.expiration_control,        --expiration_control
                        item_rec.inventory_tracked,          --inventory_tracked
                        item_rec.abc_class_name,                  --abc_cc_class
                        item_rec.default_loan_days,          --default_loan_days
                        item_rec.snm_division,                        --division
                        item_rec.product_segment,
                        item_rec.surgery_type,
                        item_rec.brand,
                        item_rec.product_class,
                        item_rec.product_type,
                        item_rec.sales_and_marketing_info,
                        trunc(sysdate),                     --exported_date
                        NULL,                               --status
                        NULL,                               --message
                        NULL, --item_rec.attribute14,               -- asc_item_number
                        NULL,                               --created_by
                        NULL,                               --last_updated_by
                        sysdate,                            --creation_date
                        sysdate                             --last_update_date
                            );
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            apps.fnd_file.put_line (
                 fnd_file.LOG, 'Unable to insert into Staging table: ' || SQLERRM
                 );
      END;


      BEGIN
         BEGIN
            SELECT   COUNT ( * )
              INTO   l_rec_cnt
              FROM   apps.XXOM_ITEM_MASTER_STG
             WHERE   NVL (status, 'New') = 'New';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_proc_status := 'E';
               fnd_file.put_line (
                  fnd_file.LOG,
                  'Unable to fetch l_rec_cnt value: ' || l_rec_cnt
               );
         END;

         apps.fnd_file.put_line (fnd_file.output, ' ');
         apps.fnd_file.put_line (fnd_file.output, ' ');

         apps.fnd_file.put_line (fnd_file.output,
                                 'Processed Date: ' || l_proc_date);
         apps.fnd_file.put_line (fnd_file.output,
                                 'Number of Exported Records: ' || l_rec_cnt);
      END;
      
      IF l_proc_status = 'P'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
          apps.fnd_file.put_line (
             fnd_file.LOG, 'Error Occured in Procedure: intg_item_extract: ' || SQLERRM
         );
   END intg_item_extract;

END XXOM_ITEM_MASTER_PKG; 
/
