DROP PACKAGE APPS.XX_OE_SALESREP_ASSIGN_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_SALESREP_ASSIGN_EXT_PKG" authid current_user
AS
  /* $Header: XX_OE_SALESREP_ASSIGN_EXT_PKG.pkb 1.0.0 2012/04/18700:00:00 riqbal noship $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-ARP-2012
  Filename       : XX_OE_SALESREP_ASSIGN_EXT_PKG.pkb
  Description    : Salesrep Assigment public API
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  1-Mar-2013    1.1       Vishal/Beda         Redesign of the code
  09-07-2014    1.2       Sanjeev            Modified as per the case 7839 to skip the AME
  approval noticiation if salesrep exists
  15-Sep-2014   1.3      Jaya Maran          Modified for Ticket#7197. OE MSG intialize commented.
  25-MAR-2016   1.4      Kannan Mariappan    Updating Internal Salesrep from TM along with External Salesrep
  */
  --------------------------------------------------------------------------------
  FUNCTION xx_catch_business_event(
      p_subscription_guid IN raw ,
      p_event             IN OUT nocopy wf_event_t )
    RETURN VARCHAR2;
  -------------------------------------------------------------------------------  /*
  FUNCTION xx_oe_call_salesrep_proc(
      p_header_id NUMBER)
    RETURN VARCHAR2;
  FUNCTION xx_oe_call_salesrep_auto_proc(
      p_header_id NUMBER)
    RETURN VARCHAR2;
  -------------------------------------------------------------------------------  /*
  PROCEDURE xx_oe_assign_salesrep(
      o_status OUT VARCHAR2 ,
      o_errormess OUT VARCHAR2 ,
      p_header_id IN NUMBER,
      p_line_id   IN NUMBER DEFAULT NULL );
  PROCEDURE xx_oe_populate_salesrep_bulk(
      o_errbuf OUT VARCHAR2 ,
      o_retcode OUT VARCHAR2 ,
      p_order_from      IN NUMBER ,
      p_order_to        IN NUMBER ,
      p_order_type      IN VARCHAR2 ,
      p_order_status    IN VARCHAR2 ,
      p_order_date_from IN VARCHAR2 ,
      p_order_date_to   IN VARCHAR2 );
  --------------------------------------------------------------------------------
  PROCEDURE xx_find_territories(
      p_country             VARCHAR2 ,
      p_customer_name_range VARCHAR2 ,
      p_customer_id         NUMBER ,
      p_site_number         NUMBER,
      p_division            VARCHAR2,
      p_sub_division        VARCHAR2,
      p_dcode               VARCHAR2,
      p_surgeon_name        VARCHAR2,
      p_cust_account        VARCHAR2 ,
      p_county              VARCHAR2,
      p_postal_code         VARCHAR2,
      P_PROVINCE            VARCHAR2,
      p_state               VARCHAR2,
      o_terr_id OUT NUMBER ,
      o_status OUT VARCHAR2 ,
      o_error_message OUT VARCHAR2 );
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  FUNCTION validate_order_eligibility(
      p_header_id IN NUMBER,
      p_line_id   IN NUMBER DEFAULT NULL )
    RETURN VARCHAR2;
  FUNCTION check_sr_exits(
      p_header_id IN NUMBER,
      p_line_id   IN NUMBER DEFAULT NULL)
    RETURN VARCHAR2;
  PROCEDURE ins_sales_credit_record(
      p_line_scredit_tbl IN OUT oe_order_pub.line_scredit_tbl_type ,
      p_header_id        IN NUMBER ,
      p_line_id          IN NUMBER ,
      p_terr_id          IN NUMBER ,
      o_return_status OUT VARCHAR2 ,
      o_return_message OUT VARCHAR2 );
  PROCEDURE xx_oe_assign_salesrep_line(
      p_header_id IN NUMBER,
      p_line_id   IN NUMBER,
      o_status OUT VARCHAR2 ,
      o_errormess OUT VARCHAR2);
END xx_oe_salesrep_assign_ext_pkg;
/
