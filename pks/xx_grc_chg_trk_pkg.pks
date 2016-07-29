DROP PACKAGE APPS.XX_GRC_CHG_TRK_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_grc_chg_trk_pkg
IS
-------------------------------------------------------------------------------
--| Program:    INTG GRC Change Tracking Reports
--| Author:     Integra Development
--| Created:    06-JUN-2014
--|
--| Description: Package with procedures that can be run as concurrent requests
--|              to produce Change History captured by Oracle GRC.
--|
--| Modifications:
--| -------------
--| Date       Name               Version     Description
--| ---------  ---------------    -------     -----------
--| 06-JUN-2014 Integra Development       1.0         Created
-------------------------------------------------------------------------------


   --
   -- Procedure to generate Vendor Change History
   --
   PROCEDURE vendor_change_data_report (errbuf             OUT   VARCHAR2,
                                        retcode            OUT   NUMBER,
                                        p_oper_unit              VARCHAR2,
                                        p_start_date             VARCHAR2,
                                        p_end_date               VARCHAR2,
                                        p_changed_by             VARCHAR2,
                                        p_vendor_id              VARCHAR2,
                                        p_vendor_site_id         VARCHAR2,
                                        p_field                  VARCHAR2
                                        );


   PROCEDURE customer_change_data_report (errbuf             OUT   VARCHAR2,
                                          retcode            OUT   NUMBER,
                                          p_start_date             VARCHAR2,
                                          p_end_date               VARCHAR2,
                                          p_changed_by             VARCHAR2,
                                          p_party_id               VARCHAR2,
                                          p_field                  VARCHAR2
                                          );


END xx_grc_chg_trk_pkg;
/
