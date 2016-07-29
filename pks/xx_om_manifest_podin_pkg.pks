DROP PACKAGE APPS.XX_OM_MANIFEST_PODIN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_MANIFEST_PODIN_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 25-May-2012
 File Name     : XX_OM_MANIFEST_PODIN_INT.pks
 Description   : This script creates the specification of the package
                 xx_om_manifest_podin_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 20-Jun-2012 Prabhakar               Initial Version
 10-Oct-2012 Renjith               Changes as per new manifest design
 08-Nov-2013 Renjith               Changes as per wave1 changes
 30-Jan-2013 Renjith               Changes as per new file format
*/
----------------------------------------------------------------------
   g_data_dir         VARCHAR2(200);
   g_arch_dir         VARCHAR2(200);

   TYPE G_XX_OM_POD_REC_TYPE IS RECORD
   (record_id                 NUMBER
   ,file_name                 VARCHAR2(240)
   ,consignee                 VARCHAR2(240)
   ,shipper                   VARCHAR2(240)
   --,sender_address            VARCHAR2(240)
   --,sender_city               VARCHAR2(240)
   --,sender_state              VARCHAR2(240)
   --,sender_country            VARCHAR2(240)
   --,service_type              VARCHAR2(240)
   ,carrier	              VARCHAR2(240)
   ,modef                     VARCHAR2(240)
   ,zonef                     VARCHAR2(240)
   ,billing_option            VARCHAR2(240)
   ,shipped	              VARCHAR2(240)
   ,delivery_date             VARCHAR2(240)
   ,delivery_time             VARCHAR2(240)
   ,trackingno                VARCHAR2(240)
   ,status                    VARCHAR2(240)
   ,fedex_office              VARCHAR2(240)
   ,refused                   VARCHAR2(240)
   ,signed_by                 VARCHAR2(240)
   ,ref1                      VARCHAR2(240)
   ,ref2                      VARCHAR2(240)
   ,ref3                      VARCHAR2(240)
   ,ref4                      VARCHAR2(240)
   ,ref5                      VARCHAR2(240)
   ,ref6                      VARCHAR2(240)
   ,ref7                      VARCHAR2(240)
   ,ref8                      VARCHAR2(240)
   ,ref9                      VARCHAR2(240)
   ,ref10                     VARCHAR2(240)
   ,weight                    VARCHAR2(240)
   ,created_by                NUMBER
   ,creation_date             DATE
   ,last_update_date          DATE
   ,last_updated_by           NUMBER
   ,last_update_login         NUMBER
   );

   TYPE G_XX_OM_POD_TAB_TYPE IS TABLE OF G_XX_OM_POD_REC_TYPE
   INDEX BY BINARY_INTEGER;

   PROCEDURE manifest_podinreprocess( p_errbuf            OUT   VARCHAR2
                                     ,p_retcode           OUT   VARCHAR2
                                     ,p_org_id            IN    NUMBER
                                     ,p_header_id         IN    NUMBER
                                     ,p_domestic          IN    NUMBER
                                     ,p_inter             IN    NUMBER
                                     );


END xx_om_manifest_podin_pkg;
/
