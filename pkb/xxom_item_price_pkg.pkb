DROP PACKAGE BODY APPS.XXOM_ITEM_PRICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_ITEM_PRICE_PKG" 
/*************************************************************************************
*   PROGRAM NAME
* 	XXOM_ITEM_PRICE_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME 	               DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)  	DESCRIPTION
* ------- ----------- --------------- 	---------------------------------------------------
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
* Inventory_item_id is not always populated on this view
* Reevaluate logic where it is looking at only updated items, not updated prices?
******************************************************************************************/
IS
PROCEDURE intg_item_price_extract (errbuf              OUT VARCHAR2,
                                   retcode             OUT VARCHAR2,
                                   p_price_list        IN VARCHAR2,
                                   p_organization_id   IN NUMBER)
IS

l_record_count NUMBER := 0;

CURSOR   item_price_cur IS
SELECT   NULL AS transaction_id,
         NULL AS transaction_date,
         qph.name price_list_name,
         -- qpl.inventory_item_id,
         msib.inventory_item_id,
         qpl.product_uom_code,
         qpl.product_attr_val_disp AS item_name,
         (CASE
            WHEN qpl.operand IS NULL
            THEN
            (SELECT   MAX (operand)
             FROM   apps.qp_price_breaks_v
             WHERE   parent_list_line_id = qpl.list_line_id
             -- BXS reevaluate this logic
             -- AND     last_update_date >= NVL (TO_DATE (xips.transaction_date,'DD-MON-RRRR HH24:MI:SS'),last_update_date - 1)
             )
             ELSE
                qpl.operand
             END) AS list_price,
          to_char(qpl.start_date_active, 'DD-MON-RRRR') AS start_date,
          to_char(qpl.end_date_active, 'DD-MON-RRRR') AS end_date,
          qph.list_header_id,
          qpl.list_line_id
FROM   apps.qp_secu_list_headers_v qph, apps.qp_list_lines_v qpl, mtl_system_items_b msib--, XXOM_ITEM_PRICE_STG xips
WHERE  qph.list_header_id = qpl.list_header_id
AND    qph.active_flag = 'Y'
AND    qph.list_header_id = p_price_list
AND    qpl.product_attr_val_disp IN
                             (SELECT   msi.segment1
                                FROM   apps.mtl_system_items_b msi
                               WHERE   msi.organization_id = p_organization_id
                            --BXS - reevaluate this logic, I don't think it is accurate
                            --AND msi.last_update_date >= NVL (TO_DATE (xips.transaction_date,'DD-MON-RRRR HH24:MI:SS'),msi.last_update_date - 1)
                            )
AND    msib.segment1 = qpl.product_attr_val_disp
AND    msib.organization_id = p_organization_id
--AND    xips.list_header_id (+) = qpl.list_header_id
--AND    xips.list_line_id (+) = qpl.list_line_id
AND    GREATEST (qph.last_update_date, qpl.last_update_date) >= NVL (
                         (SELECT MAX (to_date(transaction_date,'DD-MON-RRRR HH24:MI:SS'))
                                             FROM XXOM_ITEM_PRICE_STG
                                            WHERE list_header_id = qpl.list_header_id
                                              AND list_line_id = qpl.list_line_id),
                         GREATEST (qph.last_update_date,
                                   qpl.last_update_date)- 1)
ORDER BY   list_line_id;


   BEGIN
      BEGIN
         BEGIN
            SELECT   a.organization_code, b.name
              INTO   l_organization_code, l_organization_name
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

         apps.fnd_file.put_line (fnd_file.LOG,
                                 'Request Submission Date: ' || l_proc_date);
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'Interface Name: INTG Item Price Stage from Oraclex'
         );
         apps.fnd_file.put_line (fnd_file.LOG, ' ');
         apps.fnd_file.put_line (fnd_file.LOG, ' ');


         apps.fnd_file.put_line (
            fnd_file.LOG, 'Organization Code: ' || l_organization_code || ' And Organization Name: ' || l_organization_name );
            
         apps.fnd_file.put_line (fnd_file.LOG,
                                 'Price List: ' || p_price_list);
                                 

         FOR item_price_rec IN item_price_cur
         LOOP
            --inserting records into staging table XXOM_ITEM_PRICE_STG
           INSERT INTO XXOM_ITEM_PRICE_STG (
                       transaction_id,
                       transaction_date,
                       price_list_name,
                       inventory_item_id,
                       item_name,
                       list_price,
                       product_uom_code,
                       start_date,
                       end_date,
                       exported_date,
                       list_header_id,
                       list_line_id,
                       status,
                       message,
                       created_by,
                       last_updated_by,
                       creation_date,
                       last_update_date
                       )
              VALUES   
                       (
                        XXOM_ITEM_PRICE_STG_SEQ.NEXTVAL,    --transaction_id
                        l_proc_date,                        --transaction_date
                        item_price_rec.price_list_name,     --price_list_name
                        item_price_rec.inventory_item_id,   --inventory_item_id
                        item_price_rec.item_name,           --item_name
                        item_price_rec.list_price,          --list_price
                        item_price_rec.product_uom_code,    --product_uom_code
                        item_price_rec.start_date,          --start_date
                        item_price_rec.end_date,            --end_date
                        sysdate,                            --exported_date
                        item_price_rec.list_header_id,      --list_header_id,
                        item_price_rec.list_line_id,        --list_line_id,
                        NULL,                               --status
                        NULL,                               --message
                        NULL,                               --created_by
                        NULL,                               --last_updated_by
                        sysdate,                            --creation_date
                        sysdate                             --last_update_date
                        );
                            
              l_record_count := l_record_count + 1;
              
              
         END LOOP;
         
         apps.fnd_file.put_line (
                  fnd_file.LOG,
               'Number of records inserted into staging table: ' || l_record_count
            );
            
      EXCEPTION
      WHEN OTHERS THEN
          apps.fnd_file.put_line (
               fnd_file.LOG,
               'Unable to insert into Staging table: ' || SQLERRM
            );
      END;

      BEGIN
         BEGIN
            SELECT   COUNT ( * )
              INTO   l_rec_cnt
              FROM   XXOM_ITEM_PRICE_STG
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
            fnd_file.LOG,
            'Error Occured in Procedure: intg_item_price_extract: ' || SQLERRM
         );
   END intg_item_price_extract;

END XXOM_ITEM_PRICE_PKG;
/
