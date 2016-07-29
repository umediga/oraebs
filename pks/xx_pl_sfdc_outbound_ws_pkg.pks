DROP PACKAGE APPS.XX_PL_SFDC_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PL_SFDC_OUTBOUND_WS_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
Created By : AMishra
Creation Date : 28-Feb-2014
File Name : XXPLSFDCOUTWSPKG.pks
Description : This script creates the specification of the package

/* High Level approach
----------------------------------------------------------------------------------
--   1. Update instance Id to control Table for a batch
--   2. Run the View to extract data for a batch making join to control table
--   3. Insert the extracted data in staging table.
--   4. Run the multiset view with batch and load data out variable
--   5. Populate the error status
----------------------------------------------------------------------------------

Change History
---------------
Date          VER     Name   |       Remarks
-------------- -- |----------|-----------------------------------------
28-Feb-2014   1.0 |AMishra   |     Initial development.
------------------|----------|------------------------------------------
              1.1 |          |
------------------|----------|-------------------------------------------
*/
----------------------------------------------------------------------
   PROCEDURE get_price_list (
                            p_batch_id         IN       NUMBER,
                            p_instance_id      IN       NUMBER,
                            x_pl_output        OUT      xx_pl_sfdc_outbound_tab_typ,
                            x_return_status    OUT      VARCHAR2,
                            x_return_message   OUT      VARCHAR2);


  PROCEDURE update_response (p_error_tab       IN  xx_pl_sfdc_err_mess_tab_typ,
                            x_response_status  OUT VARCHAR2,
                            x_response_message OUT VARCHAR2);


   PROCEDURE update_instance (
      p_instance_id      IN       NUMBER,
      p_out_batch_id     IN       NUMBER,
      x_update_status    OUT      VARCHAR2,
      x_update_message   OUT      VARCHAR2
   );

  PROCEDURE xx_republish_price_list
  (
    p_errbuf           OUT 		NOCOPY   VARCHAR2,
    p_retcode          OUT 		NOCOPY   VARCHAR2,
    p_type             IN 			       VARCHAR2,
    p_hidden1          IN              VARCHAR2,
    p_pl_item_from     IN mtl_system_items_b.segment1%TYPE DEFAULT NULL,
    p_PL_item_to       IN mtl_system_items_b.segment1%TYPE DEFAULT NULL,
    p_hidden2          IN              VARCHAR2,
    p_date_from        IN             VARCHAR2 DEFAULT NULL,
    p_date_to          IN             VARCHAR2 DEFAULT NULL
  );

  PROCEDURE LOGME(p_text IN varchar2);


 FUNCTION NEXT_BATCH RETURN NUMBER;


END xx_pl_sfdc_outbound_ws_pkg;
/
