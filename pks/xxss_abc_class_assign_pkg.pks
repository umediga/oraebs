CREATE OR REPLACE PACKAGE APPS.XXSS_abc_class_assign_pkg
AS
   /**************************************************************************************
   *   Copyright (c) SeaSpine
   *   All rights reserved
   ***************************************************************************************
   *
   *   HEADER
   *   Package Specification
   *
   *   PROGRAM NAME
   *   XXSS_ABC_CLASS_ASSIGN_PKG.pks
   *
   *   DESCRIPTION
   *   Concurrent program to auto assign Class C to all new items that are transactable, stockable and cycle count enabled in a specfic org and assignment group
   *
   *   USAGE
   *   Enable new items to be included in Cycle Count 
   *
   *   PARAMETERS
   *   ==========
   *   NAME                DESCRIPTION
   *   ----------------- ------------------------------------------------------------------
   *   (1). p_inv_org_id     Inventory Organization ID
   *   (2). p_abc_grp_id     ABC assignment group id
   *
   *
   *   CALLED BY
   *   Sea Spine Auto Item Addition to ABC Assignment Group Concurrent Program
   *
   *   HISTORY
   *   =======
   *
   *   VERSION  DATE          AUTHOR(S)                 DESCRIPTION
   *   -------  -----------   ----------------------    ---------------------------------------------
   *   1.0      24-MAY-2016   Uma Ediga      Initially created
   *
   ***************************************************************************************/
   -----------------------------------------------------------------------
   -- Public procedures
   -----------------------------------------------------------------------
   PROCEDURE exec_main_pr (p_errbuf          OUT VARCHAR2,
                           p_retcode         OUT NUMBER,
                           p_inv_org_id   IN     NUMBER,
                           p_abc_grp_id   IN     NUMBER);
END XXSS_ABC_CLASS_ASSIGN_PKG;
/