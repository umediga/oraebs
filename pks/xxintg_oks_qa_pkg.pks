DROP PACKAGE APPS.XXINTG_OKS_QA_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_OKS_QA_PKG" AUTHID CURRENT_USER AS
/*******************************************************************************
Name: This is add additional validations for QA check in contracts-
Description:      This is add additional validations for QA check in contracts-
History:  17-OCT-2014    Shankar Narayanan orignal version
  
******************************************************************************/
   PROCEDURE CHECK_PO_NUMBER_ENTERED(
    x_return_status            OUT NOCOPY VARCHAR2,
    p_chr_id                   IN  NUMBER);
    
END XXINTG_OKS_QA_PKG;
/
