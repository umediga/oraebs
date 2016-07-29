DROP PACKAGE APPS.XX_H2R_UPDATE_EXPENSE_ACCOUNT;

CREATE OR REPLACE PACKAGE APPS."XX_H2R_UPDATE_EXPENSE_ACCOUNT" AS
/* $Header: XXH2RUPDEXPACCT.pks 1.0.0 2012/04/02 00:00:00$ */
--===============================================================================
  -- Created By     : Arjun.K
  -- Creation Date  : 02-APR-2012
  -- Filename       : XXH2RUPDEXPACCT.pks
  -- Description    : Package specification for Update expense Account Extension.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ------------------------------
  -- 02-APR-2012   1.0         Arjun.K             Initial Development.
--===============================================================================

   g_accounting_flex VARCHAR2 (150) := 'INTG_ACCOUNTING_FLEXFIELD';

   PROCEDURE xx_upd_exp_acct
                 (o_errbuf              OUT   VARCHAR2
                 ,o_retcode             OUT   VARCHAR2
                 ,p_business_group_id    IN   NUMBER
                 );
END xx_h2r_update_expense_account;
/
