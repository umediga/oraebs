DROP PACKAGE APPS.XX_IRC_CB_JOB_POSTING_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IRC_CB_JOB_POSTING_PKG" 
AUTHID CURRENT_USER AS
/* $Header: XX_IRC_CB_JOB_POSTING_PKG.pkb 1.0.0 2012/05/23 700:00:00 riqbal noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Raquib Iqbal
 Creation Date  : 23-MAY-2012
 Filename       : XX_IRC_CB_JOB_POSTING_PKG.pks
 Description    : This package is used to post job to external sites using Web-Service

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 23-May-2012   1.0       Raquib Iqbal        Initial development.
 23-Mar-2013   1.1       Raquib Iqbal        Ticket# 2011

 */
--------------------------------------------------------------------------------

   -------------------------------------------------------------------------------  /*
   FUNCTION xx_irc_get_recruitment_site (p_recruitment_site_id IN NUMBER)
      RETURN VARCHAR2;
   -- VARCHAR changed to CLOB for Ticket# 2011
   FUNCTION xx_irc_post_jobsto_cb (p_xml_data IN CLOB )
         RETURN VARCHAR2;

   PROCEDURE xx_irc_post_job (
      o_errbuf                    OUT      VARCHAR2,
      o_retcode                   OUT      NUMBER,
      p_transact_id               IN       VARCHAR2,
      p_recruitment_activity_id   IN       VARCHAR2
   );
-------------------------------------------------------------------------------  /*
END xx_irc_cb_job_posting_pkg;
/
