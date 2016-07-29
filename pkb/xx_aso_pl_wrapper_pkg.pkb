DROP PACKAGE BODY APPS.XX_ASO_PL_WRAPPER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASO_PL_WRAPPER_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By     : Partha
 Creation Date  : 24-JUL-2013
 File Name      : XXASOPRICELISTWRAP.pks
 Description    : This script creates the body of the package xx_aso_modifier_wrapper_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     24-JUL-2013   Partha       Initial development.
*/
----------------------------------------------------------------------
   PROCEDURE crt_updt_pl_wrap (o_errbuf OUT VARCHAR2, o_retcode OUT VARCHAR2)
   IS
      CURSOR get_quote_hdr
      IS
           SELECT   aqh.quote_header_id, aqh.quote_number
             FROM   aso_quote_headers_all aqh
            WHERE       aqh.quote_status_id = 27
                    AND aqh.ORDER_TYPE_ID = 1021
                    --AND aqh.quote_header_id = 1014        -- Added for testing
--                    AND aqh.creation_date between sysdate - 5 AND sysdate -- Added for testing
                    AND NOT EXISTS
                          (SELECT   1
                             FROM   wf_item_attribute_values iav
                            WHERE       iav.number_value = aqh.quote_header_id
                                    AND item_type LIKE 'ASOAPPRV'
                                    AND name = 'QTEHDRID')
                    AND NOT EXISTS
                          (SELECT   1
                             FROM   xx_aso_processed_pricelist xap
                            WHERE   xap.quote_header_id = aqh.quote_header_id)
         ORDER BY   aqh.creation_date;

      x_result_out   VARCHAR2 (5000);
      x_rec_count    NUMBER := 0;
   BEGIN
      FOR quote_hdr_data IN get_quote_hdr
      LOOP
         fnd_file.put_line (
            fnd_file.LOG,
            'Processing Quote Number : ' || quote_hdr_data.quote_number
         );
         x_result_out := NULL;
         x_rec_count := x_rec_count +1;
         -- Call procedure to create Price List
         BEGIN
            xx_aso_price_list_ext_pkg.create_upd_price_list (
               itemtype    => NULL,
               itemkey     => quote_hdr_data.quote_header_id, -- pass Quote Header ID
               actid       => NULL,
               funcmode    => 'RUN',
               resultout   => x_result_out
            );

            fnd_file.put_line (fnd_file.LOG,
                               'Message from Package : ' || x_result_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (
                  fnd_file.LOG,
                  'Error Calling XX_ASO_PRICE_LIST_EXT_PKG.CREATE_UPD_PRICE_LIST'
               );
               fnd_file.put_line (fnd_file.LOG, SQLERRM);
               fnd_file.put_line (fnd_file.LOG,
                                  DBMS_UTILITY.format_error_backtrace);
         END;

         BEGIN                                     -- insert into custom table
            INSERT INTO xx_aso_processed_pricelist
              VALUES   (quote_hdr_data.quote_header_id,
                        quote_hdr_data.quote_number,
                        x_result_out,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        SYSDATE,
                        fnd_profile.VALUE ('USER_ID'));
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  DBMS_UTILITY.format_error_backtrace);
         END;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,chr(10)||'Total Records Processed : '||x_rec_count);
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            DBMS_UTILITY.format_error_backtrace);
         o_retcode := '2';
   END crt_updt_pl_wrap;
END xx_aso_pl_wrapper_pkg;
/
