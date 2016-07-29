DROP PACKAGE APPS.XX_INTG_CONC_PROG_ADD;

CREATE OR REPLACE PACKAGE APPS."XX_INTG_CONC_PROG_ADD" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 24-JUL-2013
 File Name     : XX_INTG_CONC_PROG_ADD.pks
 Description   : This script creates the specification of the package
                 xx_intg_conc_prog_add
 Change History:
 Date         Name                    Remarks
 -----------  -------------           -----------------------------------
 24-JUL-2013  IBM Development Team      Initial Draft.
 */
----------------------------------------------------------------------

------------------< add_prgrm_to_rqst_grp >------------------------------------------------------
 /**
 * PROCEDURE main
 *
 * DESCRIPTION
 *     procedure to add concurrent program to the request group
 *
 * ARGUMENTS
 *   IN:
 *      p_resp_name              Responsibility Name
 *      p_conc_prgrm_name        Concurrent program Name
 *
 *   OUT:
 *      errbuf                  Error
 *      retcode                 Code
 */
--------------------------------------------------------------------------------

PROCEDURE add_prgrm_to_rqst_grp(errbuf                 OUT VARCHAR2,
                                    retcode                OUT NUMBER,
                                    p_resp_name         IN     VARCHAR2,
                                    p_conc_prgrm_name   IN     VARCHAR2);

END xx_intg_conc_prog_add;
/
