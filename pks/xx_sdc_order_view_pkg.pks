DROP PACKAGE APPS.XX_SDC_ORDER_VIEW_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_ORDER_VIEW_PKG" 
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
   FUNCTION header_total ( p_header_id   IN   NUMBER) RETURN NUMBER;

   FUNCTION header_sub_total ( p_header_id   IN   NUMBER) RETURN NUMBER;

   FUNCTION header_tax ( p_header_id   IN   NUMBER) RETURN NUMBER;

   FUNCTION line_status ( p_header_id   IN   NUMBER
                         ,p_line_id     IN   NUMBER
                         ,p_status      IN   VARCHAR2
                        ) RETURN VARCHAR2;

   FUNCTION is_onhold ( p_header_id   IN   NUMBER
                       ,p_line_id     IN   NUMBER
                      ) RETURN VARCHAR2;

   FUNCTION return_context ( p_header_id   IN   NUMBER
                            ,p_line_id     IN   NUMBER
                          ) RETURN VARCHAR2;

END XX_SDC_ORDER_VIEW_PKG;
/
