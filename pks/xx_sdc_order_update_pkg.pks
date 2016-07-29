DROP PACKAGE APPS.XX_SDC_ORDER_UPDATE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_ORDER_UPDATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Renjith
 Creation Date : 19-FEBR-2014
 File Name     : XX_SDC_ORDER_UPDATE_PKG.pks
 Description   : This script creates the specification of the package
		 xx_ont_so_acknowledge_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 19-FEBR-2014 Renjith              Initial Development
*/
----------------------------------------------------------------------

   PROCEDURE get_order_details    (   p_errbuf           OUT  VARCHAR2
                                     ,p_retcode          OUT  NUMBER
                                     ,p_type             IN   VARCHAR2
                                     ,p_hidden1          IN   VARCHAR2
                                     ,p_hidden2          IN   VARCHAR2
                                     ,p_so_from          IN   NUMBER
                                     ,p_so_to            IN   NUMBER
                                     ,p_date_from        IN   VARCHAR2
                                     ,p_date_to          IN   VARCHAR2);

   --header control record
   TYPE xx_head_control_rec_type IS RECORD
   (
      record_id            NUMBER
     ,publish_batch_id     NUMBER
   );

   TYPE xx_head_control_tab_type IS TABLE OF xx_head_control_rec_type
      INDEX BY BINARY_INTEGER;

   --line control record
   TYPE xx_line_control_rec_type IS RECORD
   (
      record_id            NUMBER
     ,publish_batch_id     NUMBER
     ,master_batch_id      NUMBER
     ,status_flag          VARCHAR(10)
   );

   TYPE xx_line_control_tab_type IS TABLE OF xx_line_control_rec_type
      INDEX BY BINARY_INTEGER;

   --delivery control record
   TYPE xx_delv_control_rec_type IS RECORD
   (
      record_id            NUMBER
     ,publish_batch_id     NUMBER
     ,master_batch_id      NUMBER
     ,status_flag          VARCHAR(10)
   );

   TYPE xx_delv_control_tab_type IS TABLE OF xx_delv_control_rec_type
      INDEX BY BINARY_INTEGER;


END xx_sdc_order_update_pkg;
/
