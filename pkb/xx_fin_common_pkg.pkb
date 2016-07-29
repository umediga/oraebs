DROP PACKAGE BODY APPS.XX_FIN_COMMON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_FIN_COMMON_PKG" 
/*----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- File Name       : XXFINCOMMON.pkb
-- Description     : This Package contain different validation functions and procedures
--                   which can be used by Finance People across the development of Integra
Change History:

Version Date        Name       Remarks
------- ----------- ---------  ---------------------------------------
1.0     07-MAR-2012 IBM Development  Initial development.
*/
------------------------------------------------------------------------
AS

/* Function to Validate AP Payment Term */
FUNCTION VALIDATE_AP_PAYMENT_TERM(  P_payment_term         	IN    	VARCHAR2,
      	  		  		P_inv_date             	IN    	DATE
    					   ) RETURN NUMBER IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     :  Function to Validate AP Payment Term
--
-- P_payment_term  : Payment term name in AP
-- P_inv_date      : AP Invoice Date
----------------------------------------------------------------------
x_payment_term_id   AP_TERMS.TERM_ID%TYPE;
BEGIN
     BEGIN
                  SELECT ATERM.TERM_ID
                  INTO   x_payment_term_id
			FROM   AP_TERMS ATERM
                  WHERE ATERM.NAME = P_payment_term
                  AND   ATERM.ENABLED_FLAG = 'Y'
                  AND   TRUNC (P_inv_date) BETWEEN TRUNC (ATERM.START_DATE_ACTIVE)
       		  	    			 AND   NVL (TRUNC (ATERM.END_DATE_ACTIVE), TRUNC (SYSDATE));
     EXCEPTION
     			WHEN NO_DATA_FOUND THEN
    				x_payment_term_id	:= NULL;
		 	WHEN TOO_MANY_ROWS THEN
		  		x_payment_term_id	:= NULL;
          			RAISE_APPLICATION_ERROR(-20000, G_mult_ap_pay_term_msg);
		 	WHEN OTHERS THEN
				x_payment_term_id	:= NULL;
          			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
     END;
	   RETURN (x_payment_term_id);
END VALIDATE_AP_PAYMENT_TERM;

/* Function to validate AR Payment Term */
FUNCTION VALIDATE_AR_PAYMENT_TERM (	P_payment_term         	IN   VARCHAR2,
                                    P_inv_date             	IN   DATE
                                  ) RETURN NUMBER IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to validate AR Payment Term
--
-- P_payment_term  : Payment term name in AR
-- P_inv_date      : AR Invoice date
----------------------------------------------------------------------
x_payment_term_id    RA_TERMS.TERM_ID%TYPE;
BEGIN
     BEGIN
                SELECT RTERM.TERM_ID
                INTO   x_payment_term_id
                FROM   RA_TERMS    RTERM
                WHERE  RTERM.NAME = P_payment_term
                AND    TRUNC (P_inv_date) BETWEEN TRUNC (RTERM.START_DATE_ACTIVE)
     		  	    				AND    NVL (TRUNC (RTERM.END_DATE_ACTIVE), TRUNC (SYSDATE));
     EXCEPTION
     		    WHEN NO_DATA_FOUND THEN
    				x_payment_term_id	  := NULL;
		    WHEN TOO_MANY_ROWS THEN
    				x_payment_term_id   := NULL;
          			RAISE_APPLICATION_ERROR(-20000, G_mult_ar_pay_term_msg);
		    WHEN OTHERS THEN
			   	x_payment_term_id	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
    END;
RETURN (x_payment_term_id);
END VALIDATE_AR_PAYMENT_TERM;

/* Function to Validate Receipt Method in AR */
FUNCTION VALIDATE_RECEIPT_METHOD (
                                	P_receipt_method        IN    VARCHAR2,
                                	P_inv_date             	IN    DATE
                                  ) RETURN NUMBER IS
----------------------------------------------------------------------
-- Created By       : IBM Development
-- Creation Date    : 07-MAR-2012
-- Description      : Function to Validate Receipt Method in AR
--
-- P_receipt_method : Receipt Method Name
-- P_inv_date       : Invoice date
----------------------------------------------------------------------
x_receipt_method_id    AR_RECEIPT_METHODS.RECEIPT_METHOD_ID%TYPE;
BEGIN
     	    BEGIN
                  SELECT RMETH.RECEIPT_METHOD_ID
                  INTO   x_receipt_method_id
			FROM   AR_RECEIPT_METHODS RMETH
                  WHERE RMETH.NAME = P_receipt_method
                  AND    TRUNC (P_inv_date) BETWEEN TRUNC (RMETH.START_DATE)
       		        			  AND NVL (TRUNC (RMETH.END_DATE), TRUNC (SYSDATE));
          EXCEPTION
          		WHEN NO_DATA_FOUND THEN
    					x_receipt_method_id	:= NULL;
			WHEN TOO_MANY_ROWS THEN
			    		x_receipt_method_id	:= NULL;
               			RAISE_APPLICATION_ERROR(-20000, G_mult_ar_recpt_method_msg);
			WHEN OTHERS THEN
					x_receipt_method_id	:= NULL;
               			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
	    END;
 RETURN (x_receipt_method_id);
END VALIDATE_RECEIPT_METHOD;

/* Function to validate Transaction Batch Source in AR */
FUNCTION VALIDATE_TRANS_BATCH_SOURCE (
                                    	P_batch_source_name     	IN  VARCHAR2,
                                    	P_inv_date             		IN  DATE,
                              	      P_org_id			      IN  NUMBER
                                      ) RETURN NUMBER IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     :  Function to validate Transaction Batch Source in AR
--
-- P_batch_source_name   : Batch Source Name in AR
-- P_inv_date            : Invoice Date
-- P_org_id              : Operating Unit
----------------------------------------------------------------------
x_batch_source_id RA_BATCH_SOURCES.BATCH_SOURCE_ID%TYPE;
BEGIN
     BEGIN
                  SELECT RBTS.BATCH_SOURCE_ID
                  INTO   x_batch_source_id
	            FROM   RA_BATCH_SOURCES RBTS
                  WHERE  RBTS.NAME      = P_batch_source_name
	            AND    RBTS.ORG_ID    = P_org_id
                  AND    TRUNC(P_inv_date) BETWEEN TRUNC(RBTS.START_DATE)
       		  	    			 AND    NVL (TRUNC (RBTS.END_DATE), TRUNC (SYSDATE));
      EXCEPTION
      		WHEN NO_DATA_FOUND THEN
           			x_batch_source_id	:= NULL;
		  	WHEN TOO_MANY_ROWS THEN
    			 	x_batch_source_id	:= NULL;
           			RAISE_APPLICATION_ERROR(-20000, G_mult_trns_batch_src_msg);
		  	WHEN OTHERS THEN
			     	x_batch_source_id	:= NULL;
           			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
      END;
RETURN (x_batch_source_id);
END VALIDATE_TRANS_BATCH_SOURCE;


/* Function to validate Pay Group in AP */
FUNCTION VALIDATE_AP_PAY_GROUP (P_pay_group_name        	IN  VARCHAR2
                               )RETURN VARCHAR2 IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     :  Function to validate Pay Group in AP
--
-- P_pay_group_name    : Payment Group Name
----------------------------------------------------------------------
x_pay_group_lookup_code FND_LOOKUP_VALUES_VL.LOOKUP_CODE%TYPE;
BEGIN
     BEGIN
                SELECT FLV.LOOKUP_CODE
                INTO   x_pay_group_lookup_code
  		    FROM   FND_LOOKUP_VALUES_VL FLV
                WHERE  FLV.LOOKUP_TYPE 	= G_pay_group_lkp_type
		    AND    FLV.ENABLED_FLAG   = 'Y'   --- Added by Pramit on 01/28/2008
  		    AND    FLV.MEANING   	= P_pay_group_name;
      EXCEPTION
      	    WHEN NO_DATA_FOUND THEN
    	  	 		x_pay_group_lookup_code	:= NULL;
		    WHEN TOO_MANY_ROWS THEN
		    	 	x_pay_group_lookup_code	:= NULL;
           			RAISE_APPLICATION_ERROR(-20000, G_mult_pay_group_msg);
		    WHEN OTHERS THEN
				x_pay_group_lookup_code	:= NULL;
           			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
	END;
 RETURN (x_pay_group_lookup_code);
END VALIDATE_AP_PAY_GROUP;

/* Function to validate Pay Method in AP */
FUNCTION VALIDATE_AP_PAYMENT_METHOD (	P_payment_method_name     IN   VARCHAR2
						 ) RETURN VARCHAR2 IS
----------------------------------------------------------------------
-- Created By     : IBM Development
-- Creation Date  : 07-MAR-2012
-- Description    : Function to validate Pay Method in AP
--
-- P_payment_method_name  : Payment Method Name
----------------------------------------------------------------------
x_pay_method_lookup_code   FND_LOOKUP_VALUES_VL.LOOKUP_CODE%TYPE;
BEGIN
     BEGIN
               SELECT FLV.LOOKUP_CODE
               INTO   x_pay_method_lookup_code
               FROM   FND_LOOKUP_VALUES_VL FLV
               WHERE  FLV.LOOKUP_TYPE 	= G_pay_method_lkp_type
		   AND    FLV.ENABLED_FLAG    = 'Y'   --- Added by Pramit on 01/28/2008
               AND    FLV.MEANING   	= P_payment_method_name;
    EXCEPTION
    		   WHEN NO_DATA_FOUND THEN
    		 		x_pay_method_lookup_code	:= NULL;
		   WHEN TOO_MANY_ROWS THEN
    		 		x_pay_method_lookup_code	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, G_mult_pay_method_msg);
		   WHEN OTHERS THEN
			   	x_pay_method_lookup_code	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
    END;
 RETURN (x_pay_method_lookup_code);
END VALIDATE_AP_PAYMENT_METHOD;

/* Function to validate Journal Entry Source in GL */
FUNCTION VALIDATE_JE_SOURCE (	P_user_je_source_name  IN   VARCHAR2
                            ) RETURN VARCHAR2 IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to validate Journal Entry Source in GL
--
-- P_user_je_source_name  : User Journal Source Name
----------------------------------------------------------------------
x_je_source_name   GL_JE_SOURCES.JE_SOURCE_NAME%TYPE;
BEGIN
     BEGIN
                  SELECT GJS.JE_SOURCE_NAME
                  INTO   x_je_source_name
			FROM   GL_JE_SOURCES GJS
                  WHERE  GJS.USER_JE_SOURCE_NAME 	= P_user_je_source_name
                  AND    LANGUAGE 				= USERENV ('LANG');
     EXCEPTION
     			WHEN NO_DATA_FOUND THEN
    				x_je_source_name	:= NULL;
		 	WHEN TOO_MANY_ROWS THEN
		   		x_je_source_name	:= NULL;
          			RAISE_APPLICATION_ERROR(-20000, G_mult_je_source_msg);
		 	WHEN OTHERS THEN
				x_je_source_name	:= NULL;
          			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
      END;
 RETURN (x_je_source_name);
END VALIDATE_JE_SOURCE;

/* Function to validate Journal Category in GL */
FUNCTION VALIDATE_JE_CATEGORY (	P_user_je_category_name IN  VARCHAR2
                              ) RETURN VARCHAR IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to validate Journal Category in GL
--
-- P_user_je_category_name   : User Journal Category Name
----------------------------------------------------------------------
x_je_category_name GL_JE_CATEGORIES_VL.JE_CATEGORY_NAME%TYPE;
BEGIN
     BEGIN
                  SELECT JE_CATEGORY_NAME
                  INTO   x_je_category_name
	            FROM   GL_JE_CATEGORIES_VL   GJC
                  WHERE  GJC.USER_JE_CATEGORY_NAME 	= P_user_je_category_name
                  AND    LANGUAGE 				= USERENV ('LANG');
    EXCEPTION
    			WHEN NO_DATA_FOUND THEN
         			x_je_category_name	:= NULL;
			WHEN TOO_MANY_ROWS THEN
    		 		x_je_category_name	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, G_mult_je_cat_msg);
			WHEN OTHERS THEN
			   	x_je_category_name	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
    END;
 RETURN (x_je_category_name);
END VALIDATE_JE_CATEGORY;

/* Function to validate Invoice Line type in AR */
FUNCTION VALIDATE_AR_LINE_TYPE ( P_inv_line_type		      IN   	VARCHAR2
                               ) RETURN VARCHAR2 IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to validate Invoice Line type in AR
--
-- P_inv_line_type : AR Invoce Line Type
----------------------------------------------------------------------
x_line_type_lookup_code FND_LOOKUP_VALUES_VL.LOOKUP_CODE%TYPE;
BEGIN
     BEGIN
             SELECT LOOKUP_CODE
             INTO   x_line_type_lookup_code
             FROM   FND_LOOKUP_VALUES_VL  FLV
             WHERE  FLV.LOOKUP_TYPE 	= G_stdline_typ_lkp_type
             AND    FLV.MEANING   		= P_inv_line_type;
    EXCEPTION
    		WHEN NO_DATA_FOUND THEN
    		 		x_line_type_lookup_code	:= NULL;
		WHEN TOO_MANY_ROWS THEN
    		 		x_line_type_lookup_code	:= NULL;
			   	RAISE_APPLICATION_ERROR(-20000, G_mult_ar_line_type_msg);
		WHEN OTHERS THEN
			   	x_line_type_lookup_code	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
    END;
 RETURN (x_line_type_lookup_code);
END VALIDATE_AR_LINE_TYPE;

/* Function to check Duplicate Invoice Number in AP */
FUNCTION CHECK_AP_INV_NUM_EXISTS( P_invoice_num		IN   VARCHAR2,
	   	  		  	    P_vendor_id		IN	 NUMBER
    					   ) RETURN NUMBER IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to check whether the Invoice Number exists in AP or not
--
-- P_invoice_num   : Invoice Number
-- P_vendor_id     : Vendor ID
----------------------------------------------------------------------
x_count_invoice_num     NUMBER;
BEGIN
     BEGIN
                  /* getting the count of a Particular Invoice for the given vendor */
                  SELECT COUNT(*)
                  INTO   x_count_invoice_num
			FROM   AP_INVOICES_V    AINV
                  WHERE  AINV.VENDOR_ID 	= P_vendor_id
			AND    AINV.INVOICE_NUM = P_invoice_num;
                  -- if x_count_invoice_num = 1, Invoice number already exists in the system
                  -- if x_count_invoice_num = 0 , Invoice number doesn't exist in the system
                 RETURN (x_count_invoice_num);
     EXCEPTION
      		WHEN OTHERS THEN
					x_count_invoice_num		:= NULL;
          				RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
     END;
END CHECK_AP_INV_NUM_EXISTS;

/* Function to check Invoice status in AR */
FUNCTION CHECK_AR_INVOICE_STATUS ( P_bill_cust_acct		IN    NUMBER,
	   	  		  	     P_org_id			IN    NUMBER,
	 				     P_inv_number		      IN	VARCHAR2
    					   ) RETURN VARCHAR2 IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to check Invoice status in AR
--
-- P_bill_cust_acct  : Bill to Customer Account
-- P_org_id          : Operating Unit
-- P_inv_number      : AR Invoice Number
----------------------------------------------------------------------
X_comp_flag     RA_CUSTOMER_TRX.COMPLETE_FLAG%TYPE;
BEGIN
		BEGIN
        		SELECT COMPLETE_FLAG
		   	INTO   X_comp_flag
		   	FROM   RA_CUSTOMER_TRX RCT
		   	WHERE  RCT.TRX_NUMBER 	= P_inv_number
			AND    (
                		(p_bill_cust_acct IS NOT NULL AND RCT.BILL_TO_CUSTOMER_ID =  p_bill_cust_acct)
                	OR
                		(p_bill_cust_acct IS NULL)
               		)
		   	AND    RCT.ORG_ID  =  P_org_id;
    		EXCEPTION
			WHEN NO_DATA_FOUND THEN
    		 		X_comp_flag	:= NULL;
			WHEN TOO_MANY_ROWS THEN
    		 		X_comp_flag	:= NULL;
				RAISE_APPLICATION_ERROR(-20000,G_mult_invoice_msg);
			WHEN OTHERS THEN
			   	X_comp_flag	:= NULL;
         			RAISE_APPLICATION_ERROR(-20000, substr (SQLERRM, 1,200));
   		END;
    RETURN (X_comp_flag);
END CHECK_AR_INVOICE_STATUS;

END XX_FIN_COMMON_PKG;
/


GRANT EXECUTE ON APPS.XX_FIN_COMMON_PKG TO INTG_XX_NONHR_RO;
