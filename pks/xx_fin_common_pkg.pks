DROP PACKAGE APPS.XX_FIN_COMMON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_FIN_COMMON_PKG" AS
/*----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- File Name       : XXFINCOMMON.pks
-- Description     : This Package contain different validation functions and procedures
--                   which can be used by Finance People across the development of Integra


 Change History:

Version Date        Name       Remarks
------- ----------- ---------  ---------------------------------------
1.0     07-MAR-2012 IBM Development  Initial development.
*/
----------------------------------------------------------------------

  FUNCTION VALIDATE_AP_PAYMENT_TERM(
						p_payment_term         	IN   VARCHAR2,
						p_inv_date             	IN   DATE
    						) RETURN NUMBER;
  FUNCTION VALIDATE_AR_PAYMENT_TERM (
						 p_payment_term         	IN   VARCHAR2,
						 p_inv_date             	IN   DATE
    						 ) RETURN NUMBER;
  FUNCTION VALIDATE_RECEIPT_METHOD (
						 p_receipt_method        IN 	VARCHAR2,
						 p_inv_date              IN  DATE
						 ) RETURN NUMBER;

  FUNCTION VALIDATE_TRANS_BATCH_SOURCE (
						p_batch_source_name       IN  VARCHAR2,
						p_inv_date             	  IN  DATE,
						p_org_id		  IN	NUMBER
  						   ) RETURN NUMBER;
  FUNCTION VALIDATE_AP_PAY_GROUP (
					     p_pay_group_name        	IN  VARCHAR2
    					     )   RETURN VARCHAR2;
  FUNCTION VALIDATE_AP_PAYMENT_METHOD (
						    p_payment_method_name        	IN  VARCHAR2
						  ) RETURN VARCHAR2;
  FUNCTION VALIDATE_JE_SOURCE (
      	                    p_user_je_source_name        	IN  VARCHAR2
                              ) RETURN VARCHAR2;
  FUNCTION VALIDATE_JE_CATEGORY (
					    p_user_je_category_name        	IN 	VARCHAR2
					    ) RETURN VARCHAR ;
  FUNCTION VALIDATE_AR_LINE_TYPE (
                            	      p_inv_line_type		      IN 	VARCHAR2
                                  ) RETURN VARCHAR2;
  FUNCTION CHECK_AP_INV_NUM_EXISTS( p_invoice_num	  IN  VARCHAR2,
	   	  		  		p_vendor_id		  IN	NUMBER
      				     ) RETURN NUMBER;
 FUNCTION CHECK_AR_INVOICE_STATUS ( P_bill_cust_acct		IN    NUMBER,
	   	  		  		P_org_id			IN    NUMBER,
	 					P_inv_number		IN	VARCHAR2
    					     ) RETURN VARCHAR2;



 G_mult_ap_pay_term_msg 		VARCHAR2(200) 	DEFAULT 'Multiple AP Payment Term Exists';
 G_mult_ar_pay_term_msg 		VARCHAR2(200) 	DEFAULT 'Multiple AR Payment Term Exists';
 G_mult_ar_recpt_method_msg 		VARCHAR2(200) 	DEFAULT 'Multiple AR Receipt Method Exists';
 G_mult_trns_batch_src_msg 		VARCHAR2(100) 	DEFAULT 'Multiple AR Transaction Batch Source Exists';
 G_mult_pay_group_msg      		VARCHAR2(200) 	DEFAULT 'Multiple Pay Group Lookup Code Exists';
 G_mult_pay_method_msg     		VARCHAR2(200) 	DEFAULT 'Multiple Payment Method Lookup Code Exists';
 G_mult_je_source_msg 			VARCHAR2(200) 	DEFAULT 'Multiple Journal Source Name Exists';
 G_mult_je_cat_msg   			VARCHAR2(200) 	DEFAULT 'Multiple Journal Categories Exist';
 G_mult_ar_line_type_msg 		VARCHAR2(200) 	DEFAULT 'Multiple AR Line Type Lookup Code Exists';
 G_mult_invoice_msg   			VARCHAR2(200) 	DEFAULT 'Duplicate Invoice Number exists for the same Customer';

 G_pay_group_lkp_type  			FND_LOOKUP_VALUES_VL.LOOKUP_TYPE%TYPE DEFAULT 'PAY GROUP';
 G_pay_method_lkp_type  		FND_LOOKUP_VALUES_VL.LOOKUP_TYPE%TYPE DEFAULT 'PAYMENT METHOD';
 G_stdline_typ_lkp_type  		FND_LOOKUP_VALUES_VL.LOOKUP_TYPE%TYPE DEFAULT 'STD_LINE_TYPE';

END XX_FIN_COMMON_PKG;
/


GRANT EXECUTE ON APPS.XX_FIN_COMMON_PKG TO INTG_XX_NONHR_RO;
