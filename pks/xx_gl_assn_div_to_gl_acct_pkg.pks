DROP PACKAGE APPS.XX_GL_ASSN_DIV_TO_GL_ACCT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_GL_ASSN_DIV_TO_GL_ACCT_PKG" AUTHID CURRENT_USER
---------------------------------------------------------------------------------
/*$Header: XXGLSSNDIVTOGLACCTPKG.pks 1.0 2012/03/22 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 16-Mar-2012
 Filename      : XXGLSSNDIVTOGLACCTPKG.pks
 Description   : This Package specification is used for update procedures
                 (attribut1,attribute2)for the table GL_CODE_COMBINATIONS


 Change History:

 Date          Version#       Name                           Remarks
 -----------   --------   ---------------         ---------------------------------------
 16-Mar-2012   1.0       IBM Development Team           Initial development.
 26-Mar-1212   1.1       IBM Development Team    Added the logic for Process Setup Form
*/
---------------------------------------------------------------------------------

AS

   PROCEDURE main ( o_errbuff          OUT VARCHAR2
                   ,o_retcode          OUT VARCHAR2
                   ,p_coa_id         IN NUMBER
                   ,p_process_mode   IN VARCHAR2
                   ,p_low_acct       IN VARCHAR2
                   ,p_high_acct      IN VARCHAR2
                   ,p_lookup         IN VARCHAR2
                   ,p_div_prod_val   IN VARCHAR2
                   ,p_div_geo_region IN varchar2
                   );

END XX_GL_ASSN_DIV_TO_GL_ACCT_PKG;
/
