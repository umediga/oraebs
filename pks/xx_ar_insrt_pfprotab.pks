DROP PACKAGE APPS.XX_AR_INSRT_PFPROTAB;

CREATE OR REPLACE PACKAGE APPS."XX_AR_INSRT_PFPROTAB" 
AS
----------------------------------------------------------------------------------------
--| Program:     Integra Life Sciences - PO Number Line Details Interface To Paypal Pkg |
--| Author:      Vargab Pathak  - OCS                                                   |
--| Created:     20-May-12                                                              |
--|                                                                                     |
--| Description: ITGR_INSRT_PFPROTAB contains procedure call to insert po detls n line  |
--|              dtls of a receipt into ipayment tables.                                |
--|                                                                                     |
--| Modifications:                                                                      |
--| -------------                                                                       |
--| Date          Name                Version       Description                         |
--| ---------   ---------------       -------       -----------                         |
--| 20-May-12   IBM Development         1.0         Initial Version                     |
--|                                                                                     |
----------------------------------------------------------------------------------------|
--- Package Specification
----------------------------------------------------------------------------------------
-- Procedure ITGR_INSRT_PFPROTAB is called from concurrent program in Receipts
----------------------------------------------------------------------------------------

procedure itgr_pfpro_polinedtls (    errbuf OUT varchar2,
                                     retcode OUT number
                                );
end XX_AR_INSRT_PFPROTAB;
/
