DROP PACKAGE BODY APPS.XX_TRX_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_TRX_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 24-FEB-2012
 File Name     : XXARTRXCNV.pkb
 Description   : This script creates the body of the package
                 xx_trx_conversion_pkg

 Change History:

 Date        Name                Remarks
 ----------- ------------        -------------------------------------
 24-FEB-2012 Sharath Babu        Initial Development  
 20-MAR-2012 Sharath Babu        Modified to add sales credit details
 27-APR-2012 Sharath Babu        Added NVL to default currency to USD if null
 18-MAY-2012 Sharath Babu        Added operating_unit_name in update procedure and 
                                 Commented condition in update_record_count to 
                                 display sucess cnt with validate only mode
 04-JUL-2012 Sharath Babu        Modified code to insert p_gl_date into pre interface tbl 
                                 and added line type derivation logic for freight line
 10-JUL-2012 Sharath Babu        Added uom_code pre interface update
 09-MAY-2013 Sharath Babu        Modified as per Wave1 to process all records in Load mode
*/
----------------------------------------------------------------------

   -- Do not change anything in these procedures mark_records_for_processing and set_cnv_env
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard interface tables
            DELETE FROM xx_ar_inv_line_pre_int
                  WHERE batch_id = g_batch_id;

            UPDATE xx_ar_inv_trx_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_ar_inv_line_pre_int
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE FROM ra_interface_lines_all
               WHERE attribute11 = g_batch_id;
               
         DELETE FROM ra_interface_salescredits_all
               WHERE attribute11 = g_batch_id;
               
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_ar_inv_trx_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (   process_code = xx_emf_cn_pkg.cn_new
                    OR (    process_code = xx_emf_cn_pkg.cn_preval
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                               (xx_emf_cn_pkg.cn_rec_warn,
                                xx_emf_cn_pkg.cn_rec_err
                               )
                       )
                   );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_ar_inv_trx_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_ar_inv_line_pre_int
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_ar_inv_line_pre_int
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_ar_inv_line_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_ar_inv_line_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_valid
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_ar_inv_line_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_ar_inv_line_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'Error in mark_records_for_processing ... '
                               || SQLERRM
                              );
         ROLLBACK;
   END mark_records_for_processing;

   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (
      p_error_code      IN   VARCHAR2,
      p_record_number   IN   NUMBER
   )
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      x_error_code           NUMBER := xx_emf_cn_pkg.cn_success;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside Update Staging Records error_code'
                            || p_error_code
                           );

      UPDATE xx_ar_inv_trx_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_update_by,
             last_update_login = x_last_updated_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new
         AND record_number = p_record_number;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error While Updating Staging table = '
                               || SQLERRM
                              );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand
                          );
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         ROLLBACK;
   END update_staging_records;
  
   PROCEDURE update_pre_interface_records (
      p_trx_pre_iface_tab   IN   g_xx_ar_cnv_pre_std_tab_type
   )
   IS
      x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inside update_pre_interface_records'
                           );

      FOR indx IN 1 .. p_trx_pre_iface_tab.COUNT
      LOOP
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_trx_pre_iface_tab(indx).process_code '
                               || p_trx_pre_iface_tab (indx).process_code
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_trx_pre_iface_tab(indx).error_code '
                               || p_trx_pre_iface_tab (indx).ERROR_CODE
                              );

         UPDATE  xx_ar_inv_line_pre_int
            SET  batch_source_name              = p_trx_pre_iface_tab(indx).batch_source_name              
                ,set_of_books_id                = p_trx_pre_iface_tab(indx).set_of_books_id                
                ,line_type                      = p_trx_pre_iface_tab(indx).line_type                      
                ,description                    = p_trx_pre_iface_tab(indx).description                    
                ,currency_code                  = p_trx_pre_iface_tab(indx).currency_code                                          
                ,cust_trx_type_name             = p_trx_pre_iface_tab(indx).cust_trx_type_name             
                ,cust_trx_type_id               = p_trx_pre_iface_tab(indx).cust_trx_type_id               
                ,term_name                      = p_trx_pre_iface_tab(indx).term_name                      
                ,term_id                        = p_trx_pre_iface_tab(indx).term_id                               
                ,orig_system_bill_customer_ref  = p_trx_pre_iface_tab(indx).orig_system_bill_customer_ref  
                ,orig_system_bill_customer_id   = p_trx_pre_iface_tab(indx).orig_system_bill_customer_id   
                ,orig_system_bill_address_ref   = p_trx_pre_iface_tab(indx).orig_system_bill_address_ref   
                ,orig_system_bill_address_id    = p_trx_pre_iface_tab(indx).orig_system_bill_address_id    
                ,orig_system_bill_contact_ref   = p_trx_pre_iface_tab(indx).orig_system_bill_contact_ref   
                ,orig_system_bill_contact_id    = p_trx_pre_iface_tab(indx).orig_system_bill_contact_id    
                ,orig_system_ship_customer_ref  = p_trx_pre_iface_tab(indx).orig_system_ship_customer_ref  
                ,orig_system_ship_customer_id   = p_trx_pre_iface_tab(indx).orig_system_ship_customer_id   
                ,orig_system_ship_address_ref   = p_trx_pre_iface_tab(indx).orig_system_ship_address_ref   
                ,orig_system_ship_address_id    = p_trx_pre_iface_tab(indx).orig_system_ship_address_id    
                ,orig_system_ship_contact_ref   = p_trx_pre_iface_tab(indx).orig_system_ship_contact_ref   
                ,orig_system_ship_contact_id    = p_trx_pre_iface_tab(indx).orig_system_ship_contact_id    
                ,receipt_method_name            = p_trx_pre_iface_tab(indx).receipt_method_name            
                ,receipt_method_id              = p_trx_pre_iface_tab(indx).receipt_method_id              
                ,conversion_type                = p_trx_pre_iface_tab(indx).conversion_type                
                ,trx_date                       = p_trx_pre_iface_tab(indx).trx_date                       
                ,gl_date                        = p_trx_pre_iface_tab(indx).gl_date                        
                ,trx_number                     = p_trx_pre_iface_tab(indx).trx_number                     
                ,fob_point                      = p_trx_pre_iface_tab(indx).fob_point                      
                ,ship_via                       = p_trx_pre_iface_tab(indx).ship_via                       
                ,waybill_number                 = p_trx_pre_iface_tab(indx).waybill_number                 
                ,invoicing_rule_name            = p_trx_pre_iface_tab(indx).invoicing_rule_name            
                ,invoicing_rule_id              = p_trx_pre_iface_tab(indx).invoicing_rule_id              
                ,accounting_rule_name           = p_trx_pre_iface_tab(indx).accounting_rule_name           
                ,accounting_rule_id             = p_trx_pre_iface_tab(indx).accounting_rule_id             
                ,primary_salesrep_number        = p_trx_pre_iface_tab(indx).primary_salesrep_number        
                ,primary_salesrep_id            = p_trx_pre_iface_tab(indx).primary_salesrep_id            
                ,inventory_item_id              = p_trx_pre_iface_tab(indx).inventory_item_id              
                ,mtl_system_items_seg1          = p_trx_pre_iface_tab(indx).mtl_system_items_seg1          
                ,uom_name                       = p_trx_pre_iface_tab(indx).uom_name  
                ,uom_code                       = p_trx_pre_iface_tab(indx).uom_code
                ,operating_unit_name            = p_trx_pre_iface_tab(indx).operating_unit_name
                ,org_id                         = p_trx_pre_iface_tab(indx).org_id                         
                ,tax_code                       = p_trx_pre_iface_tab(indx).tax_code
                ,process_code                   = p_trx_pre_iface_tab(indx).process_code
                ,error_code                     = p_trx_pre_iface_tab(indx).error_code
                ,last_updated_by                = x_last_updated_by
                ,last_update_date               = x_last_update_date
                ,last_update_login              = x_last_update_login
            WHERE batch_id      = p_trx_pre_iface_tab(indx).batch_id 
              AND record_number = p_trx_pre_iface_tab(indx).record_number;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'Error update_pre_interface_records '
                               || SQLERRM
                              );
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         ROLLBACK;
   END update_pre_interface_records;

   FUNCTION process_data
      RETURN NUMBER
   IS
      x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
      x_creation_date       DATE   := SYSDATE;
      x_created_by          NUMBER := fnd_global.user_id;
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
   BEGIN
      xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_medium,
                      'process_data: Inserting into standard interface Table'
                     );

      INSERT INTO ra_interface_lines_all
                  ( 
                 --interface_line_id              
                 interface_line_context         
                ,interface_line_attribute1      
                ,interface_line_attribute2      
                ,interface_line_attribute3      
                ,interface_line_attribute4      
                ,interface_line_attribute5      
                ,interface_line_attribute6      
                ,interface_line_attribute7      
                ,interface_line_attribute8      
                ,batch_source_name              
                ,set_of_books_id                
                ,line_type                      
                ,description                    
                ,currency_code                  
                ,amount                         
                ,cust_trx_type_name             
                ,cust_trx_type_id               
                ,term_name                      
                ,term_id                        
                ,orig_system_batch_name         
                ,orig_system_bill_customer_ref  
                ,orig_system_bill_customer_id   
                ,orig_system_bill_address_ref   
                ,orig_system_bill_address_id    
                ,orig_system_bill_contact_ref   
                ,orig_system_bill_contact_id    
                ,orig_system_ship_customer_ref  
                ,orig_system_ship_customer_id   
                ,orig_system_ship_address_ref   
                ,orig_system_ship_address_id    
                ,orig_system_ship_contact_ref   
                ,orig_system_ship_contact_id    
                ,orig_system_sold_customer_ref  
                ,orig_system_sold_customer_id   
                ,link_to_line_id                
                ,link_to_line_context           
                ,link_to_line_attribute1        
                ,link_to_line_attribute2        
                ,link_to_line_attribute3        
                ,link_to_line_attribute4        
                ,link_to_line_attribute5        
                ,link_to_line_attribute6        
                ,link_to_line_attribute7        
                ,receipt_method_name            
                ,receipt_method_id              
                ,conversion_type                
                ,conversion_date                
                ,conversion_rate                
                ,customer_trx_id                
                ,trx_date                       
                ,gl_date                        
                ,document_number                
                ,trx_number                     
                ,line_number                    
                ,quantity                       
                ,quantity_ordered               
                ,unit_selling_price             
                ,unit_standard_price            
                ,printing_option                
                ,interface_status               
                --,request_id                     
                ,related_batch_source_name      
                ,related_trx_number             
                ,related_customer_trx_id        
                ,previous_customer_trx_id       
                ,credit_method_for_acct_rule    
                ,credit_method_for_installments 
                ,reason_code                    
                ,tax_rate                       
                ,tax_code                       
                ,tax_precedence                 
                ,exception_id                   
                ,exemption_id                   
                ,ship_date_actual               
                ,fob_point                      
                ,ship_via                       
                ,waybill_number                 
                ,invoicing_rule_name            
                ,invoicing_rule_id              
                ,accounting_rule_name           
                ,accounting_rule_id             
                ,accounting_rule_duration       
                ,rule_start_date                
                ,primary_salesrep_number        
                ,primary_salesrep_id            
                ,sales_order                    
                ,sales_order_line               
                ,sales_order_date               
                ,sales_order_source             
                ,sales_order_revision           
                ,purchase_order                 
                ,purchase_order_revision        
                ,purchase_order_date            
                ,agreement_name                 
                ,agreement_id                   
                ,memo_line_name                 
                ,memo_line_id                   
                ,inventory_item_id              
                ,mtl_system_items_seg1          
                ,mtl_system_items_seg2          
                ,mtl_system_items_seg3          
                ,mtl_system_items_seg4          
                ,mtl_system_items_seg5          
                ,mtl_system_items_seg6          
                ,mtl_system_items_seg7          
                ,mtl_system_items_seg8          
                ,mtl_system_items_seg9          
                ,mtl_system_items_seg10         
                ,mtl_system_items_seg11         
                ,mtl_system_items_seg12         
                ,mtl_system_items_seg13         
                ,mtl_system_items_seg14         
                ,mtl_system_items_seg15         
                ,mtl_system_items_seg16         
                ,mtl_system_items_seg17         
                ,mtl_system_items_seg18         
                ,mtl_system_items_seg19         
                ,mtl_system_items_seg20         
                ,reference_line_id              
                ,reference_line_context         
                ,reference_line_attribute1      
                ,reference_line_attribute2      
                ,reference_line_attribute3      
                ,reference_line_attribute4      
                ,reference_line_attribute5      
                ,reference_line_attribute6      
                ,reference_line_attribute7      
                ,territory_id                   
                ,territory_segment1             
                ,territory_segment2             
                ,territory_segment3             
                ,territory_segment4             
                ,territory_segment5             
                ,territory_segment6             
                ,territory_segment7             
                ,territory_segment8             
                ,territory_segment9             
                ,territory_segment10            
                ,territory_segment11            
                ,territory_segment12            
                ,territory_segment13            
                ,territory_segment14            
                ,territory_segment15            
                ,territory_segment16            
                ,territory_segment17            
                ,territory_segment18            
                ,territory_segment19            
                ,territory_segment20            
                ,attribute_category             
                ,attribute1                     
                ,attribute2                     
                ,attribute3                     
                ,attribute4                     
                ,attribute5                     
                ,attribute6                     
                ,attribute7                     
                ,attribute8                     
                ,attribute9                     
                ,attribute10                    
                ,attribute11                    
                ,attribute12                    
                ,attribute13                    
                ,attribute14                    
                ,attribute15                    
                ,header_attribute_category      
                ,header_attribute1              
                ,header_attribute2              
                ,header_attribute3              
                ,header_attribute4              
                ,header_attribute5              
                ,header_attribute6              
                ,header_attribute7              
                ,header_attribute8              
                ,header_attribute9              
                ,header_attribute10             
                ,header_attribute11             
                ,header_attribute12             
                ,header_attribute13             
                ,header_attribute14             
                ,header_attribute15             
                ,comments                       
                ,internal_notes                 
                ,initial_customer_trx_id        
                ,ussgl_transaction_code_context 
                ,ussgl_transaction_code         
                ,acctd_amount                   
                ,customer_bank_account_id       
                ,customer_bank_account_name     
                ,uom_code                       
                ,uom_name                       
                ,document_number_sequence_id    
                ,link_to_line_attribute10       
                ,link_to_line_attribute11       
                ,link_to_line_attribute12       
                ,link_to_line_attribute13       
                ,link_to_line_attribute14       
                ,link_to_line_attribute15       
                ,link_to_line_attribute8        
                ,link_to_line_attribute9        
                ,reference_line_attribute10     
                ,reference_line_attribute11     
                ,reference_line_attribute12     
                ,reference_line_attribute13     
                ,reference_line_attribute14     
                ,reference_line_attribute15     
                ,reference_line_attribute8      
                ,reference_line_attribute9      
                ,interface_line_attribute10     
                ,interface_line_attribute11     
                ,interface_line_attribute12     
                ,interface_line_attribute13     
                ,interface_line_attribute14     
                ,interface_line_attribute15     
                ,interface_line_attribute9      
                ,vat_tax_id                     
                ,reason_code_meaning            
                ,last_period_to_credit          
                ,paying_customer_id             
                ,paying_site_use_id             
                ,tax_exempt_flag                
                ,tax_exempt_reason_code         
                ,tax_exempt_reason_code_meaning 
                ,tax_exempt_number              
                ,sales_tax_id                   
                ,created_by                     
                ,creation_date                  
                ,last_updated_by                
                ,last_update_date               
                ,last_update_login              
                ,location_segment_id            
                ,movement_id                    
                ,org_id                         
                ,amount_includes_tax_flag       
                ,header_gdf_attr_category       
                ,header_gdf_attribute1          
                ,header_gdf_attribute2          
                ,header_gdf_attribute3          
                ,header_gdf_attribute4          
                ,header_gdf_attribute5          
                ,header_gdf_attribute6          
                ,header_gdf_attribute7          
                ,header_gdf_attribute8          
                ,header_gdf_attribute9          
                ,header_gdf_attribute10         
                ,header_gdf_attribute11         
                ,header_gdf_attribute12         
                ,header_gdf_attribute13         
                ,header_gdf_attribute14         
                ,header_gdf_attribute15         
                ,header_gdf_attribute16         
                ,header_gdf_attribute17         
                ,header_gdf_attribute18         
                ,header_gdf_attribute19         
                ,header_gdf_attribute20         
                ,header_gdf_attribute21         
                ,header_gdf_attribute22         
                ,header_gdf_attribute23         
                ,header_gdf_attribute24         
                ,header_gdf_attribute25         
                ,header_gdf_attribute26         
                ,header_gdf_attribute27         
                ,header_gdf_attribute28         
                ,header_gdf_attribute29         
                ,header_gdf_attribute30         
                ,line_gdf_attr_category         
                ,line_gdf_attribute1            
                ,line_gdf_attribute2            
                ,line_gdf_attribute3            
                ,line_gdf_attribute4            
                ,line_gdf_attribute5            
                ,line_gdf_attribute6            
                ,line_gdf_attribute7            
                ,line_gdf_attribute8            
                ,line_gdf_attribute9            
                ,line_gdf_attribute10           
                ,line_gdf_attribute11           
                ,line_gdf_attribute12           
                ,line_gdf_attribute13           
                ,line_gdf_attribute14           
                ,line_gdf_attribute15           
                ,line_gdf_attribute16           
                ,line_gdf_attribute17           
                ,line_gdf_attribute18           
                ,line_gdf_attribute19           
                ,line_gdf_attribute20           
                ,reset_trx_date_flag            
                ,payment_server_order_num       
                ,approval_code                  
                ,address_verification_code      
                ,warehouse_id                   
                ,translated_description         
                ,cons_billing_number            
                ,promised_commitment_amount     
                ,payment_set_id                 
                ,original_gl_date               
                ,contract_line_id               
                ,contract_id                    
                ,source_data_key1               
                ,source_data_key2               
                ,source_data_key3               
                ,source_data_key4               
                ,source_data_key5               
                ,invoiced_line_acctg_level      
                ,override_auto_accounting_flag  
                ,source_application_id          
                ,source_event_class_code        
                ,source_entity_code             
                ,source_trx_id                  
                ,source_trx_line_id             
                ,source_trx_line_type           
                ,source_trx_detail_tax_line_id  
                ,historical_flag                
                ,tax_regime_code                
                ,tax                            
                ,tax_status_code                
                ,tax_rate_code                  
                ,tax_jurisdiction_code          
                ,taxable_amount                 
                ,taxable_flag                   
                ,legal_entity_id                
                ,parent_line_id                 
                ,deferral_exclusion_flag        
                ,payment_trxn_extension_id      
                ,rule_end_date                  
                ,payment_attributes             
                ,application_id                 
                ,billing_date                   
                ,trx_business_category          
                ,product_fisc_classification    
                ,product_category               
                ,product_type                   
                ,line_intended_use              
                ,assessable_value               
                ,document_sub_type              
                ,default_taxation_country       
                ,user_defined_fisc_class        
                ,taxed_upstream_flag            
                ,tax_invoice_date               
                ,tax_invoice_number             
                ,payment_type_code              
                ,mandate_last_trx_flag               
                  )
                
                  SELECT     
                     --interface_line_id              
                 interface_line_context         
                ,interface_line_attribute1      
                ,interface_line_attribute2      
                ,interface_line_attribute3      
                ,interface_line_attribute4      
                ,interface_line_attribute5      
                ,interface_line_attribute6      
                ,interface_line_attribute7      
                ,interface_line_attribute8      
                ,batch_source_name              
                ,set_of_books_id                
                ,CASE WHEN interface_line_attribute2 LIKE '%*FR'
                      THEN 'FREIGHT'
                      ELSE line_type
                  END                                                  --Added for Freight lines   
                ,description                    
                ,currency_code                  
                ,amount                         
                ,cust_trx_type_name             
                ,cust_trx_type_id               
                ,term_name                      
                ,term_id                        
                ,orig_system_batch_name         
                ,orig_system_bill_customer_ref  
                ,orig_system_bill_customer_id   
                ,orig_system_bill_address_ref   
                ,orig_system_bill_address_id    
                ,orig_system_bill_contact_ref   
                ,orig_system_bill_contact_id    
                ,orig_system_ship_customer_ref  
                ,orig_system_ship_customer_id   
                ,orig_system_ship_address_ref   
                ,orig_system_ship_address_id    
                ,orig_system_ship_contact_ref   
                ,orig_system_ship_contact_id    
                ,orig_system_sold_customer_ref  
                ,orig_system_sold_customer_id   
                ,link_to_line_id                
                ,link_to_line_context           
                ,link_to_line_attribute1        
                ,link_to_line_attribute2        
                ,link_to_line_attribute3        
                ,link_to_line_attribute4        
                ,link_to_line_attribute5        
                ,link_to_line_attribute6        
                ,link_to_line_attribute7        
                ,receipt_method_name            
                ,receipt_method_id              
                ,conversion_type                
                ,conversion_date                
                ,conversion_rate                
                ,customer_trx_id                
                ,trx_date                       
                ,gl_date                        
                ,document_number                
                ,trx_number                     
                ,line_number                    
                ,quantity                       
                ,quantity_ordered               
                ,unit_selling_price             
                ,unit_standard_price            
                ,printing_option                
                ,interface_status               
                --,request_id                     
                ,related_batch_source_name      
                ,related_trx_number             
                ,related_customer_trx_id        
                ,previous_customer_trx_id       
                ,credit_method_for_acct_rule    
                ,credit_method_for_installments 
                ,reason_code                    
                ,tax_rate                       
                ,tax_code                       
                ,tax_precedence                 
                ,exception_id                   
                ,exemption_id                   
                ,ship_date_actual               
                ,fob_point                      
                ,ship_via                       
                ,waybill_number                 
                ,invoicing_rule_name            
                ,invoicing_rule_id              
                ,accounting_rule_name           
                ,accounting_rule_id             
                ,accounting_rule_duration       
                ,rule_start_date                
                ,primary_salesrep_number        
                ,primary_salesrep_id            
                ,sales_order                    
                ,sales_order_line               
                ,sales_order_date               
                ,sales_order_source             
                ,sales_order_revision           
                ,purchase_order                 
                ,purchase_order_revision        
                ,purchase_order_date            
                ,agreement_name                 
                ,agreement_id                   
                ,memo_line_name                 
                ,memo_line_id                   
                ,inventory_item_id              
                ,mtl_system_items_seg1          
                ,mtl_system_items_seg2          
                ,mtl_system_items_seg3          
                ,mtl_system_items_seg4          
                ,mtl_system_items_seg5          
                ,mtl_system_items_seg6          
                ,mtl_system_items_seg7          
                ,mtl_system_items_seg8          
                ,mtl_system_items_seg9          
                ,mtl_system_items_seg10         
                ,mtl_system_items_seg11         
                ,mtl_system_items_seg12         
                ,mtl_system_items_seg13         
                ,mtl_system_items_seg14         
                ,mtl_system_items_seg15         
                ,mtl_system_items_seg16         
                ,mtl_system_items_seg17         
                ,mtl_system_items_seg18         
                ,mtl_system_items_seg19         
                ,mtl_system_items_seg20         
                ,reference_line_id              
                ,reference_line_context         
                ,reference_line_attribute1      
                ,reference_line_attribute2      
                ,reference_line_attribute3      
                ,reference_line_attribute4      
                ,reference_line_attribute5      
                ,reference_line_attribute6      
                ,reference_line_attribute7      
                ,territory_id                   
                ,territory_segment1             
                ,territory_segment2             
                ,territory_segment3             
                ,territory_segment4             
                ,territory_segment5             
                ,territory_segment6             
                ,territory_segment7             
                ,territory_segment8             
                ,territory_segment9             
                ,territory_segment10            
                ,territory_segment11            
                ,territory_segment12            
                ,territory_segment13            
                ,territory_segment14            
                ,territory_segment15            
                ,territory_segment16            
                ,territory_segment17            
                ,territory_segment18            
                ,territory_segment19            
                ,territory_segment20            
                ,attribute_category             
                ,attribute1                     
                ,attribute2                     
                ,attribute3                     
                ,attribute4                     
                ,attribute5                     
                ,attribute6                     
                ,attribute7                     
                ,attribute8                     
                ,attribute9                     
                ,attribute10                    
                ,batch_id     --attribute11                    
                ,attribute12                    
                ,attribute13                    
                ,attribute14                    
                ,attribute15                    
                ,header_attribute_category      
                ,header_attribute1              
                ,header_attribute2              
                ,header_attribute3              
                ,header_attribute4              
                ,header_attribute5              
                ,header_attribute6              
                ,header_attribute7              
                ,header_attribute8              
                ,header_attribute9              
                ,header_attribute10             
                ,header_attribute11             
                ,header_attribute12             
                ,header_attribute13             
                ,header_attribute14             
                ,header_attribute15             
                ,comments                       
                ,internal_notes                 
                ,initial_customer_trx_id        
                ,ussgl_transaction_code_context 
                ,ussgl_transaction_code         
                ,acctd_amount                   
                ,customer_bank_account_id       
                ,customer_bank_account_name     
                ,uom_code                       
                ,uom_name                       
                ,document_number_sequence_id    
                ,link_to_line_attribute10       
                ,link_to_line_attribute11       
                ,link_to_line_attribute12       
                ,link_to_line_attribute13       
                ,link_to_line_attribute14       
                ,link_to_line_attribute15       
                ,link_to_line_attribute8        
                ,link_to_line_attribute9        
                ,reference_line_attribute10     
                ,reference_line_attribute11     
                ,reference_line_attribute12     
                ,reference_line_attribute13     
                ,reference_line_attribute14     
                ,reference_line_attribute15     
                ,reference_line_attribute8      
                ,reference_line_attribute9      
                ,interface_line_attribute10     
                ,interface_line_attribute11     
                ,interface_line_attribute12     
                ,interface_line_attribute13     
                ,interface_line_attribute14     
                ,interface_line_attribute15     
                ,interface_line_attribute9      
                ,vat_tax_id                     
                ,reason_code_meaning            
                ,last_period_to_credit          
                ,paying_customer_id             
                ,paying_site_use_id             
                ,tax_exempt_flag                
                ,tax_exempt_reason_code         
                ,tax_exempt_reason_code_meaning 
                ,tax_exempt_number              
                ,sales_tax_id                   
                ,x_created_by                         --created_by                     
                ,x_creation_date                      --creation_date
                ,x_last_updated_by                    --last_updated_by                
                ,x_last_update_date                   --last_update_date
                ,x_last_update_login                  --last_update_login            
                ,location_segment_id            
                ,movement_id                    
                ,org_id                         
                ,amount_includes_tax_flag       
                ,header_gdf_attr_category       
                ,header_gdf_attribute1          
                ,header_gdf_attribute2          
                ,header_gdf_attribute3          
                ,header_gdf_attribute4          
                ,header_gdf_attribute5          
                ,header_gdf_attribute6          
                ,header_gdf_attribute7          
                ,header_gdf_attribute8          
                ,header_gdf_attribute9          
                ,header_gdf_attribute10         
                ,header_gdf_attribute11         
                ,header_gdf_attribute12         
                ,header_gdf_attribute13         
                ,header_gdf_attribute14         
                ,header_gdf_attribute15         
                ,header_gdf_attribute16         
                ,header_gdf_attribute17         
                ,header_gdf_attribute18         
                ,header_gdf_attribute19         
                ,header_gdf_attribute20         
                ,header_gdf_attribute21         
                ,header_gdf_attribute22         
                ,header_gdf_attribute23         
                ,header_gdf_attribute24         
                ,header_gdf_attribute25         
                ,header_gdf_attribute26         
                ,header_gdf_attribute27         
                ,header_gdf_attribute28         
                ,header_gdf_attribute29         
                ,header_gdf_attribute30         
                ,line_gdf_attr_category         
                ,line_gdf_attribute1            
                ,line_gdf_attribute2            
                ,line_gdf_attribute3            
                ,line_gdf_attribute4            
                ,line_gdf_attribute5            
                ,line_gdf_attribute6            
                ,line_gdf_attribute7            
                ,line_gdf_attribute8            
                ,line_gdf_attribute9            
                ,line_gdf_attribute10           
                ,line_gdf_attribute11           
                ,line_gdf_attribute12           
                ,line_gdf_attribute13           
                ,line_gdf_attribute14           
                ,line_gdf_attribute15           
                ,line_gdf_attribute16           
                ,line_gdf_attribute17           
                ,line_gdf_attribute18           
                ,line_gdf_attribute19           
                ,line_gdf_attribute20           
                ,reset_trx_date_flag            
                ,payment_server_order_num       
                ,approval_code                  
                ,address_verification_code      
                ,warehouse_id                   
                ,translated_description         
                ,cons_billing_number            
                ,promised_commitment_amount     
                ,payment_set_id                 
                ,original_gl_date               
                ,contract_line_id               
                ,contract_id                    
                ,source_data_key1               
                ,source_data_key2               
                ,source_data_key3               
                ,source_data_key4               
                ,source_data_key5               
                ,invoiced_line_acctg_level      
                ,override_auto_accounting_flag  
                ,source_application_id          
                ,source_event_class_code        
                ,source_entity_code             
                ,source_trx_id                  
                ,source_trx_line_id             
                ,source_trx_line_type           
                ,source_trx_detail_tax_line_id  
                ,historical_flag                
                ,tax_regime_code                
                ,tax                            
                ,tax_status_code                
                ,tax_rate_code                  
                ,tax_jurisdiction_code          
                ,taxable_amount                 
                ,taxable_flag                   
                ,legal_entity_id                
                ,parent_line_id                 
                ,deferral_exclusion_flag        
                ,payment_trxn_extension_id      
                ,rule_end_date                  
                ,payment_attributes             
                ,application_id                 
                ,billing_date                   
                ,trx_business_category          
                ,product_fisc_classification    
                ,product_category               
                ,product_type                   
                ,line_intended_use              
                ,assessable_value               
                ,document_sub_type              
                ,default_taxation_country       
                ,user_defined_fisc_class        
                ,taxed_upstream_flag            
                ,tax_invoice_date               
                ,tax_invoice_number             
                ,payment_type_code              
                ,mandate_last_trx_flag          
             FROM  xx_ar_inv_line_pre_int
             WHERE batch_id = G_BATCH_ID
             AND   request_id = xx_emf_pkg.G_REQUEST_ID;
             --Modified as per Wave1
             --AND   error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
             --AND   process_code = xx_emf_cn_pkg.CN_POSTVAL;

      COMMIT;
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
                 (xx_emf_cn_pkg.cn_medium,
                     'Error While Inserting into standard interface Table = '
                  || SQLERRM
                 );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand
                          );
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         ROLLBACK;
         RETURN x_error_code;
   END process_data;
   
   FUNCTION insert_into_sales_credits_int
   RETURN NUMBER
   IS
      x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
      x_creation_date       DATE   := SYSDATE;
      x_created_by          NUMBER := fnd_global.user_id;
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
   BEGIN
       xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_medium,
                             'insert_into_sales_credits_int: Inserting into Sales Credits standard interface Table'
                     );
                     
       INSERT INTO 
           ra_interface_salescredits_all
           (
          interface_line_context ,
          interface_line_attribute1 ,
          interface_line_attribute2 ,
          interface_line_attribute3 ,
          interface_line_attribute4 ,
          interface_line_attribute5 ,
          interface_line_attribute6 ,
          interface_line_attribute7 ,
          interface_line_attribute8 ,
          interface_line_attribute9 ,
          interface_line_attribute10 ,
          interface_line_attribute11 ,
          interface_line_attribute12 ,
          interface_line_attribute13 ,
          interface_line_attribute14 ,
          interface_line_attribute15,
          sales_credit_percent_split,
          sales_credit_type_name,
          sales_credit_type_id,
          salesrep_number,
          salesrep_id,
          org_id,
          attribute11,
          created_by,                     
          creation_date,                  
          last_updated_by,                
          last_update_date,               
              last_update_login    
          )
          SELECT
          interface_line_context,
          interface_line_attribute1,
          interface_line_attribute2 ,
          interface_line_attribute3 ,
          interface_line_attribute4 ,
          interface_line_attribute5 ,
          interface_line_attribute6 ,
          interface_line_attribute7 ,
          interface_line_attribute8 ,
          interface_line_attribute9 ,
          interface_line_attribute10 ,
          interface_line_attribute11 ,
          interface_line_attribute12 ,
          interface_line_attribute13 ,
          interface_line_attribute14 ,
          interface_line_attribute15 ,
          '100',
          'Quota Sales Credit',  --SALES_CREDIT_TYPE_NAME
          '1', --SALES_CREDIT_TYPE_ID
          primary_salesrep_number,
          primary_salesrep_id, --SALESREP_ID 
          org_id,    
          batch_id,
          x_created_by,                         --created_by                     
          x_creation_date,                      --creation_date
          x_last_updated_by,                    --last_updated_by                
          x_last_update_date,                   --last_update_date
              x_last_update_login                  --last_update_login  
    FROM  xx_ar_inv_line_pre_int
       WHERE  batch_id = G_BATCH_ID
     AND  request_id = xx_emf_pkg.G_REQUEST_ID
     --Modified as per Wave1
     --AND  error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         --AND  process_code = xx_emf_cn_pkg.CN_POSTVAL
         AND  ( primary_salesrep_number IS NOT NULL OR primary_salesrep_id IS NOT NULL );
         
         COMMIT;
         RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
            xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_medium,
                        'Error While Inserting into ra_interface_salescredits_all interface Table = '
                     || SQLERRM
                    );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            ROLLBACK;
         RETURN x_error_code;
   END insert_into_sales_credits_int;

   PROCEDURE mark_records_complete (p_process_code VARCHAR2)
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_ar_inv_line_pre_int
         SET process_code = g_stage,
             ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
             last_updated_by = x_last_update_by,
             last_update_date = x_last_update_date,
             last_update_login = x_last_updated_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code =
                DECODE (p_process_code,
                        xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                        xx_emf_cn_pkg.cn_derive
                       )
         AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error While mark_records_complete = '
                               || SQLERRM
                              );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand
                          );
         ROLLBACK;
   END mark_records_complete;

   PROCEDURE main (
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2,
      p_gl_date             IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_ar_trx_stg_table    g_xx_ar_cnv_stg_tab_type;
      x_pre_std_hdr_table   g_xx_ar_cnv_pre_std_tab_type;

      -- Cursor to fetch staging data
      CURSOR c_xx_intg_trx_cnv (cp_process_status VARCHAR2)
      IS
         SELECT   trxstg.*
             FROM xx_ar_inv_trx_stg trxstg
            WHERE trxstg.batch_id = g_batch_id
              AND trxstg.request_id = xx_emf_pkg.g_request_id
              AND trxstg.process_code = cp_process_status
              AND trxstg.ERROR_CODE IS NULL
         ORDER BY record_number;

      --Cursor to get pre-interface data
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   trxpre.*
             FROM xx_ar_inv_line_pre_int trxpre
            WHERE trxpre.batch_id = g_batch_id
              AND trxpre.request_id = xx_emf_pkg.g_request_id
              AND trxpre.process_code = cp_process_status
              AND trxpre.ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      PROCEDURE update_master_status (
         p_trx_pre_iface_rec   IN OUT   g_xx_ar_cnv_pre_std_rec_type,
         p_error_code          IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_trx_pre_iface_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_trx_pre_iface_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max
                                        (p_error_code,
                                         NVL (p_trx_pre_iface_rec.ERROR_CODE,
                                              xx_emf_cn_pkg.cn_success
                                             )
                                        );
         END IF;

         p_trx_pre_iface_rec.process_code := g_stage;
      END update_master_status;

      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date       DATE   := SYSDATE;
         x_created_by          NUMBER := fnd_global.user_id;
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
         x_gl_date             DATE   := FND_DATE.CANONICAL_TO_DATE (p_gl_date);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         INSERT INTO xx_ar_inv_line_pre_int
                     (
                      line_type                      
                     ,description                    
                     ,currency_code
                     ,amount                         
                     ,cust_trx_type_name             
                     ,term_name                      
                     ,interface_line_context         
                     ,interface_line_attribute1      
                     ,interface_line_attribute2      
                     ,interface_line_attribute3      
                     ,interface_line_attribute4      
                     ,interface_line_attribute5      
                     ,interface_line_attribute6      
                     ,interface_line_attribute7      
                     ,interface_line_attribute8      
                     ,interface_line_attribute9      
                     ,interface_line_attribute10     
                     ,batch_source_name              
                     ,orig_system_batch_name         
                     ,orig_system_bill_customer_ref  
                     ,orig_system_bill_address_ref   
                     ,orig_system_bill_contact_ref   
                     ,orig_system_ship_customer_ref  
                     ,orig_system_ship_address_ref   
                     ,orig_system_ship_contact_ref   
                     ,orig_system_sold_customer_ref  
                     ,link_to_line_context           
                     ,link_to_line_attribute1        
                     ,link_to_line_attribute2        
                     ,link_to_line_attribute3        
                     ,link_to_line_attribute4        
                     ,link_to_line_attribute5        
                     ,link_to_line_attribute6        
                     ,link_to_line_attribute8        
                     ,link_to_line_attribute9        
                     ,link_to_line_attribute7        
                     ,link_to_line_attribute10       
                     ,receipt_method_name            
                     ,conversion_type                
                     ,conversion_date                
                     ,conversion_rate                
                     ,trx_date                       
                     ,gl_date                        
                     ,document_number                
                     ,trx_number                     
                     ,line_number                    
                     ,quantity                       
                     ,quantity_ordered               
                     ,unit_selling_price             
                     ,unit_standard_price            
                     ,printing_option                
                     ,related_batch_source_name      
                     ,related_trx_number             
                     ,credit_method_for_acct_rule    
                     ,credit_method_for_installments 
                     --,credit_card_number             
                     ,reason_code                    
                     ,tax_rate                       
                     ,tax_code                       
                     ,tax_precedence                 
                     ,ship_date_actual               
                     ,fob_point                      
                     ,ship_via                       
                     ,waybill_number                 
                     ,invoicing_rule_name            
                     ,accounting_rule_name           
                     ,accounting_rule_duration       
                     ,rule_start_date                
                     ,primary_salesrep_number        
                     ,sales_order                    
                     ,sales_order_line               
                     ,sales_order_date               
                     ,sales_order_source             
                     ,sales_order_revision           
                     ,purchase_order                 
                     ,purchase_order_revision        
                     ,purchase_order_date            
                     ,agreement_name                 
                     ,memo_line_name                 
                     ,mtl_system_items_seg1          
                     ,mtl_system_items_seg2          
                     ,mtl_system_items_seg3          
                     ,mtl_system_items_seg4          
                     ,mtl_system_items_seg5          
                     ,mtl_system_items_seg6          
                     ,mtl_system_items_seg7          
                     ,mtl_system_items_seg8          
                     ,mtl_system_items_seg9          
                     ,mtl_system_items_seg10         
                     ,reference_line_context         
                     ,reference_line_attribute1      
                     ,reference_line_attribute2      
                     ,reference_line_attribute3      
                     ,reference_line_attribute4      
                     ,reference_line_attribute5      
                     ,reference_line_attribute6      
                     ,reference_line_attribute8      
                     ,reference_line_attribute9      
                     ,reference_line_attribute7      
                     ,reference_line_attribute10     
                     ,territory_segment1             
                     ,territory_segment2             
                     ,territory_segment3             
                     ,territory_segment4             
                     ,territory_segment5             
                     ,territory_segment6             
                     ,territory_segment7             
                     ,territory_segment8             
                     ,territory_segment9             
                     ,territory_segment10            
                     ,attribute_category             
                     ,attribute1                     
                     ,attribute2                     
                     ,attribute3                     
                     ,attribute4                     
                     ,attribute5                     
                     ,attribute6                     
                     ,attribute7                     
                     ,attribute8                     
                     ,attribute9                     
                     ,attribute10                    
                     ,header_attribute_category      
                     ,header_attribute1              
                     ,header_attribute2              
                     ,header_attribute3              
                     ,header_attribute4              
                     ,header_attribute5              
                     ,header_attribute6              
                     ,header_attribute7              
                     ,header_attribute8              
                     ,header_attribute9              
                     ,header_attribute10             
                     ,comments                       
                     ,internal_notes                 
                     ,ussgl_transaction_code_context 
                     ,ussgl_transaction_code         
                     ,acctd_amount                   
                     --,customer_bank_account_number   
                     --,account_suffix                 
                     ,customer_bank_account_name     
                     ,uom_code                       
                     ,reason_code_meaning            
                     ,last_period_to_credit          
                     ,tax_exempt_flag                
                     ,tax_exempt_reason_code         
                     ,tax_exempt_reason_code_meaning 
                     ,tax_exempt_number              
                     ,operating_unit_name            
                     ,amount_includes_tax_flag       
                     ,reset_trx_date_flag            
                     ,payment_server_order_num       
                     ,approval_code                  
                     ,address_verification_code      
                     ,translated_description         
                     ,cons_billing_number            
                     ,promised_commitment_amount     
                     ,original_gl_date               
                     ,source_data_key1               
                     ,source_data_key2               
                     ,source_data_key3               
                     ,source_data_key4               
                     ,source_data_key5               
                     ,invoiced_line_acctg_level      
                     ,override_auto_accounting_flag  
                     ,source_event_class_code        
                     ,source_entity_code             
                     ,source_trx_line_type           
                     ,historical_flag                
                     ,tax_regime_code                
                     ,tax                            
                     ,tax_status_code                
                     ,tax_rate_code                  
                     ,tax_jurisdiction_code          
                     ,taxable_amount                 
                     ,taxable_flag                   
                     ,deferral_exclusion_flag        
                     ,rule_end_date                  
                     ,payment_attributes             
                     ,billing_date                   
                     --,src_sys_nm                     
                     --,src_cntry_cd                   
                     --,sales_region                   
                     --,salesman_number                
                     --,term_code                      
                     ,uom_name                       
                     ,batch_id                       
                     ,record_number                  
                     ,source_system_name             
                     ,process_code                   
                     ,error_code                     
                     ,created_by                     
                     ,creation_date                  
                     ,last_update_date               
                     ,last_updated_by                
                     ,last_update_login              
                     ,request_id                     
                   )
               SELECT
                     line_type                                       
                    ,description                    
                    ,NVL(currency_code,'USD')                  
                    ,amount                         
                    ,cust_trx_type_name             
                    ,DECODE(cust_trx_type_name,'Credit Memo',NULL,term_name)  --Added for Credit memo
                    ,interface_line_context         
                    ,interface_line_attribute1      
                    ,interface_line_attribute2      
                    ,interface_line_attribute3      
                    ,interface_line_attribute4      
                    ,interface_line_attribute5      
                    ,interface_line_attribute6      
                    ,interface_line_attribute7      
                    ,interface_line_attribute8      
                    ,interface_line_attribute9      
                    ,interface_line_attribute10     
                    ,batch_source_name              
                    ,orig_system_batch_name         
                    ,orig_system_bill_customer_ref  
                    ,orig_system_bill_address_ref   
                    ,orig_system_bill_contact_ref   
                    ,orig_system_ship_customer_ref  
                    ,orig_system_ship_address_ref   
                    ,orig_system_ship_contact_ref   
                    ,orig_system_sold_customer_ref  
                    ,link_to_line_context           
                    ,link_to_line_attribute1        
                    ,link_to_line_attribute2        
                    ,link_to_line_attribute3        
                    ,link_to_line_attribute4        
                    ,link_to_line_attribute5        
                    ,link_to_line_attribute6        
                    ,link_to_line_attribute8        
                    ,link_to_line_attribute9        
                    ,link_to_line_attribute7        
                    ,link_to_line_attribute10       
                    ,receipt_method_name            
                    ,NVL(conversion_type,'User')
                    ,conversion_date                
                    ,NVL(conversion_rate,1)  --Added to fix conversion rate issue                
                    ,trx_date                       
                    ,x_gl_date            --gl_date  Modified to populate at run time
                    ,document_number                
                    ,trx_number                     
                    ,line_number                    
                    ,quantity                       
                    ,quantity_ordered               
                    ,unit_selling_price             
                    ,unit_standard_price            
                    ,printing_option                
                    ,related_batch_source_name      
                    ,related_trx_number             
                    ,credit_method_for_acct_rule    
                    ,credit_method_for_installments 
                    --,credit_card_number             
                    ,reason_code                    
                    ,tax_rate                       
                    ,tax_code                       
                    ,tax_precedence                 
                    ,ship_date_actual               
                    ,fob_point                      
                    ,ship_via                       
                    ,waybill_number                 
                    ,DECODE(cust_trx_type_name,'Credit Memo',NULL,invoicing_rule_name)   --Added for Credit memo
                    ,DECODE(cust_trx_type_name,'Credit Memo',NULL,accounting_rule_name)  --Added for Credit memo
                    ,accounting_rule_duration       
                    ,rule_start_date                
                    ,primary_salesrep_number        
                    ,sales_order                    
                    ,sales_order_line               
                    ,sales_order_date               
                    ,sales_order_source             
                    ,sales_order_revision           
                    ,purchase_order                 
                    ,purchase_order_revision        
                    ,purchase_order_date            
                    ,agreement_name                 
                    ,memo_line_name                 
                    ,mtl_system_items_seg1          
                    ,mtl_system_items_seg2          
                    ,mtl_system_items_seg3          
                    ,mtl_system_items_seg4          
                    ,mtl_system_items_seg5          
                    ,mtl_system_items_seg6          
                    ,mtl_system_items_seg7          
                    ,mtl_system_items_seg8          
                    ,mtl_system_items_seg9          
                    ,mtl_system_items_seg10         
                    ,reference_line_context         
                    ,reference_line_attribute1      
                    ,reference_line_attribute2      
                    ,reference_line_attribute3      
                    ,reference_line_attribute4      
                    ,reference_line_attribute5      
                    ,reference_line_attribute6      
                    ,reference_line_attribute8      
                    ,reference_line_attribute9      
                    ,reference_line_attribute7      
                    ,reference_line_attribute10     
                    ,territory_segment1             
                    ,territory_segment2             
                    ,territory_segment3             
                    ,territory_segment4             
                    ,territory_segment5             
                    ,territory_segment6             
                    ,territory_segment7             
                    ,territory_segment8             
                    ,territory_segment9             
                    ,territory_segment10            
                    ,attribute_category             
                    ,attribute1                     
                    ,attribute2                     
                    ,attribute3                     
                    ,attribute4                     
                    ,attribute5                     
                    ,attribute6                     
                    ,attribute7                     
                    ,attribute8                     
                    ,attribute9                     
                    ,attribute10                    
                    ,header_attribute_category      
                    ,header_attribute1              
                    ,header_attribute2              
                    ,header_attribute3              
                    ,header_attribute4              
                    ,header_attribute5              
                    ,header_attribute6              
                    ,header_attribute7              
                    ,header_attribute8              
                    ,header_attribute9              
                    ,header_attribute10             
                    ,comments                       
                    ,internal_notes                 
                    ,ussgl_transaction_code_context 
                    ,ussgl_transaction_code         
                    ,acctd_amount                   
                    --,customer_bank_account_number   
                    --,account_suffix                 
                    ,customer_bank_account_name     
                    ,uom_code
                    ,reason_code_meaning            
                    ,last_period_to_credit          
                    ,tax_exempt_flag                
                    ,tax_exempt_reason_code         
                    ,tax_exempt_reason_code_meaning 
                    ,tax_exempt_number              
                    ,operating_unit_name            
                    ,amount_includes_tax_flag       
                    ,reset_trx_date_flag            
                    ,payment_server_order_num       
                    ,approval_code                  
                    ,address_verification_code      
                    ,translated_description         
                    ,cons_billing_number            
                    ,promised_commitment_amount     
                    ,original_gl_date               
                    ,source_data_key1               
                    ,source_data_key2               
                    ,source_data_key3               
                    ,source_data_key4               
                    ,source_data_key5               
                    ,invoiced_line_acctg_level      
                    ,override_auto_accounting_flag  
                    ,source_event_class_code        
                    ,source_entity_code             
                    ,source_trx_line_type           
                    ,historical_flag                
                    ,tax_regime_code                
                    ,tax                            
                    ,tax_status_code                
                    ,tax_rate_code                  
                    ,tax_jurisdiction_code          
                    ,taxable_amount                 
                    ,taxable_flag                   
                    ,deferral_exclusion_flag        
                    ,rule_end_date                  
                    ,payment_attributes             
                    ,billing_date                   
                    --,src_sys_nm                     
                    --,src_cntry_cd                   
                    --,sales_region                   
                    --,salesman_number                
                    --,term_code                      
                    ,uom_name                       
                    ,batch_id                       
                    ,record_number                  
                    ,source_system_name             
                    ,process_code                   
                    ,error_code                     
                    ,x_created_by                     
                    ,x_creation_date                  
                    ,x_last_update_date               
                    ,x_last_updated_by                
                    ,x_last_update_login              
                    ,request_id                     
               FROM xx_ar_inv_trx_stg
              WHERE batch_id = G_BATCH_ID
                AND process_code = xx_emf_cn_pkg.CN_PREVAL
                AND request_id = xx_emf_pkg.G_REQUEST_ID
                AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

         COMMIT;
         --Updated term name to all the credit memos as per Wave1 11i
         UPDATE xx_ar_inv_line_pre_int pre
        SET term_name = NULL          
      WHERE pre.amount < 0        
            AND pre.batch_id = G_BATCH_ID
            AND EXISTS ( SELECT 'X'
                           FROM ra_cust_trx_types_all rctt
                          WHERE UPPER(rctt.name) = UPPER(pre.cust_trx_type_name)                            
                            AND rctt.type = 'CM' 
                            AND TRUNC(SYSDATE) >= TRUNC(NVL(rctt.start_date, SYSDATE))
                            AND TRUNC(SYSDATE) <= TRUNC(NVL(rctt.end_date, SYSDATE + 1))
                        );
         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Error in move_rec_pre_standard_table = '
                                 || SQLERRM
                                );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            ROLLBACK;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_ar_inv_trx_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT COUNT (1) error_count
              FROM xx_ar_inv_line_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ar_inv_line_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) succ_count
              FROM xx_ar_inv_line_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               --AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
      BEGIN
         OPEN c_get_total_cnt;

         FETCH c_get_total_cnt
          INTO x_total_cnt;

         CLOSE c_get_total_cnt;

         OPEN c_get_error_cnt;

         FETCH c_get_error_cnt
          INTO x_error_cnt;

         CLOSE c_get_error_cnt;

         OPEN c_get_warning_cnt;

         FETCH c_get_warning_cnt
          INTO x_warn_cnt;

         CLOSE c_get_warning_cnt;

         OPEN c_get_success_cnt;

         FETCH c_get_success_cnt
          INTO x_success_cnt;

         CLOSE c_get_success_cnt;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'G_BATCH_ID = ' || g_batch_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'xx_emf_pkg.G_REQUEST_ID = '
                               || xx_emf_pkg.g_request_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'xx_emf_cn_pkg.CN_REC_ERR = '
                               || xx_emf_cn_pkg.cn_rec_err
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' x_total_cnt = ' || x_total_cnt
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' x_error_cnt = ' || x_error_cnt
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' x_warn_cnt = ' || x_warn_cnt
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' x_success_cnt = ' || x_success_cnt
                              );
         xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                     p_success_recs_cnt      => x_success_cnt,
                                     p_warning_recs_cnt      => x_warn_cnt,
                                     p_error_recs_cnt        => x_error_cnt
                                    );
      END update_record_count;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Main  begins');
      retcode := xx_emf_cn_pkg.cn_success;
      --Set Environment
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Start of main program....'
                           );
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_batch_id ' || p_batch_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_restart_flag ' || p_restart_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_override_flag ' || p_override_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Main:Param - p_validate_and_load '
                            || p_validate_and_load
                           );
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'After mark record for processing call'
                           );

      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Within p_override_flag '
                              );
         /********************************************************
            Pre Validations starts here................
         ***********************************************************/
         set_stage (xx_emf_cn_pkg.cn_preval);

         OPEN c_xx_intg_trx_cnv (xx_emf_cn_pkg.cn_new);

         FETCH c_xx_intg_trx_cnv
         BULK COLLECT INTO x_ar_trx_stg_table;-- LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

         FOR i IN 1 .. x_ar_trx_stg_table.COUNT
         LOOP
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_medium,
                                 'Within staging - Trx Number Number '
                              || x_ar_trx_stg_table (i).interface_line_attribute1
                             );
            x_error_code :=
               xx_ar_trx_cnv_validations_pkg.pre_validations
                                                        (x_ar_trx_stg_table
                                                                           (i)
                                                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                     'After pre-validations x_error_code '
                                  || x_error_code
                                 );
            update_staging_records (x_error_code,
                                    x_ar_trx_stg_table (i).record_number
                                   );
         END LOOP;

         IF c_xx_intg_trx_cnv%ISOPEN
         THEN
            CLOSE c_xx_intg_trx_cnv;
         END IF;

         /*****************************************************************************
             Pre Validations Ends here................
          **********************************************************************************/

         /**********************************************************************************
           Moving Records from Staging table to Pre-Interface tables
                    having process_code = 'Pre- Validations'
          ***********************************************************************************/
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                            'After move_rec_pre_standard_table x_error_code: '
                         || x_error_code
                        );
      END IF;                                       -- End of override if loop

     /*********************************************************************************
       Data Validations Starts here................
      **********************************************************************************/
      set_stage (xx_emf_cn_pkg.cn_valid);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Validations starts here'
                           );

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      FETCH c_xx_intg_pre_std_hdr
      BULK COLLECT INTO x_pre_std_hdr_table;-- LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

      FOR i IN 1 .. x_pre_std_hdr_table.COUNT
      LOOP
      BEGIN
         -- Perform AR invoice data validations
         x_error_code :=
            xx_ar_trx_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'data_validations x_error_code for '
                               || x_pre_std_hdr_table (i).record_number
                               || ' is '
                               || x_error_code
                              );
         update_master_status (x_pre_std_hdr_table (i), x_error_code);
         xx_emf_pkg.propagate_error (x_error_code);
      EXCEPTION
         -- If HIGH error then it will be propagated to the next level
         -- IF the process has to continue maintain it as a medium severity
         WHEN xx_emf_pkg.g_e_rec_error
         THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                      xx_emf_cn_pkg.cn_rec_err
                     );
         WHEN xx_emf_pkg.g_e_prc_error
         THEN
        xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_high,
                   'Process Level Error in Data Validations'
                  );
        update_pre_interface_records (x_pre_std_hdr_table);
        raise_application_error (-20199,
                     xx_emf_cn_pkg.cn_prc_err);
         WHEN OTHERS
         THEN
        xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                  xx_emf_cn_pkg.cn_tech_error,
                  xx_emf_cn_pkg.cn_exp_unhand,
                  x_pre_std_hdr_table (i).record_number
             );      
      END;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Calling update_pre_interface_records'
                           );
      update_pre_interface_records (x_pre_std_hdr_table);
      /********************************************************
         Data Validations Ends here................
       ***********************************************************/

      /********************************************************
           Data Derivation starts here................
       **********************************************************/
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Derivations Starts here'
                           );
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      FETCH c_xx_intg_pre_std_hdr
      BULK COLLECT INTO x_pre_std_hdr_table;-- LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

      FOR i IN 1 .. x_pre_std_hdr_table.COUNT
      LOOP
      BEGIN
         x_error_code :=
            xx_ar_trx_cnv_validations_pkg.data_derivations
                                                      (x_pre_std_hdr_table (i)
                                                      );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'data_derivations x_error_code for '
                               || x_pre_std_hdr_table (i).record_number
                               || ' is '
                               || x_error_code
                              );
         update_master_status (x_pre_std_hdr_table (i), x_error_code);
         xx_emf_pkg.propagate_error (x_error_code);
      EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            xx_emf_cn_pkg.cn_rec_err
                           );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
              xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_high,
                         'Process Level Error in Data Validations'
                        );
              update_pre_interface_records (x_pre_std_hdr_table);
              raise_application_error (-20199,
                           xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
              xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                        xx_emf_cn_pkg.cn_tech_error,
                        xx_emf_cn_pkg.cn_exp_unhand,
                        x_pre_std_hdr_table (i).record_number
             );    
      END;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      update_pre_interface_records (x_pre_std_hdr_table);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Derivations ends here '
                           );
      /********************************************************
       Data Derivations Ends here....
       ***********************************************************/

      /********************************************************
           Post Validations starts here................
       ***********************************************************/
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      x_error_code := xx_ar_trx_cnv_validations_pkg.post_validations;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                     'After post-validations X_ERROR_CODE '
                                  || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.propagate_error (x_error_code);                    
            
      /********************************************************
       Post Validations Ends here....
       ***********************************************************/

      /********************************************************
            Process Data Starts here....
       ***********************************************************/

      -- Perform process data only if p_validate_and_load is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         -- Set the stage to Process Data
         set_stage (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Start of process data section '
                              );
         x_error_code := process_data;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'End of process data section '
                              );
         --Insert into sales credit interface table
         x_error_code := insert_into_sales_credits_int;
         
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Start of mark_records_complete '
                              );
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'End of mark_records_complete '
                              );
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                 --End If for p_validate_and_load

      /********************************************************
              Process Data Ends here....
       ***********************************************************/
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Start of statistics update_record_count program '
                           );
      update_record_count;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'End of statistics update_record_count program '
                           );
      --xx_emf_pkg.create_report;  Modified as per Wave1 to display distinct errors
      xx_emf_pkg.generate_report;
      
      EXCEPTION
         WHEN xx_emf_pkg.g_e_env_not_set
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  xx_emf_pkg.cn_env_not_set);
            retcode := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.create_report;
         WHEN xx_emf_pkg.g_e_rec_error
         THEN
            retcode := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.create_report;
         WHEN xx_emf_pkg.g_e_prc_error
         THEN
            retcode := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.create_report;
         WHEN OTHERS
         THEN
            retcode := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.create_report;
   END main;
END xx_trx_conversion_pkg; 
/
