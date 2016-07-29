DROP PACKAGE APPS.XXQP_FREIGHT_CONFIG;

CREATE OR REPLACE PACKAGE APPS."XXQP_FREIGHT_CONFIG" AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 04-July-2013
File Name     : XXQPFRCONFIG122.pks
Description   : This script creates the package of the package XXQP_FREIGHT_CONFIG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
04-July-2013  Narendra Yadav        Initial Draft.
16-Aug-2013   Aabhas Bhargava       Changes as per the modified FRS
26-Sep-2013   Narendra Yadav        Changes as per modified FRS (added 3 more functions)
29-Oct-2013   Narendra Yadav        Changes into XXINTG_CONFIG_FRCOST as per New FS
16-June-2014  Krishna Ayalavarapu   Added few addl functions to setup pricing attributes for case #7608

*/
----------------------------------------------------------------------
    FUNCTION XXINTG_CONFIG_CONTYPE(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_CONTYPE_NAME(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_DIV(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
    FUNCTION XXINTG_CONFIG_PROSHIP(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_FRCOST(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
    FUNCTION XXINTG_CONFIG_CONT_PRC(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_HAZAR(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_CUSTACC(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_CUSTID(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
    FUNCTION XXINTG_CONFIG_GETDIV(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_SUBDIV(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_PROTYPE(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR;
    FUNCTION XXINTG_CONFIG_TOTFR(xx_line_record IN oe_order_pub.g_line%type,xx_type IN VARCHAR2 DEFAULT 'TOT') RETURN NUMBER;
    FUNCTION XXINTG_CONFIG_PRORATE(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
    --Functions added by K AYalavarapu on 6/16/2014 to configure addl pricing attributes.
    FUNCTION HEADER_PRICE_LIST(P_HEADER_ID number) return number; 
    FUNCTION DAY_OF_THE_WEEK(p_date date,p_param varchar2) return varchar2; 
    FUNCTION DAY_OF_THE_WEEK_TWO_DATES(p_date1 date,p_date2 date,p_param varchar2) return varchar2; 
  
   FUNCTION order_source(p_order_source_id number) return varchar2; 
   --Functions added by K AYalavarapu on 6/16/2014 to configure addl pricing attributes ends here
END;
/
