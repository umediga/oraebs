DROP PACKAGE APPS.XX_JTF_USER_REG_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_JTF_USER_REG_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXJTF_USERREG.pks 1.0 2012/07/20 12:00:00 pnarva noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Jul-2012
 File Name      : XXJTF_USERREG.pks
 Description    : This script creates the specification of xx_jtf_user_reg_pkg the package

 Change History:

 Version Date          Name                    Remarks
 ------- -----------   ----                    ----------------------
 1.0     20-Jul-2012   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
AS
-- =================================================================================
-- These Global Variables
-- =================================================================================
   g_chr_pkg_name           VARCHAR2 (30)  := 'xx_jtf_user_reg_pkg';
   g_chr_transaction_type   VARCHAR2 (200);
   g_num_err_loc_code       NUMBER (5);

-- =================================================================================
-- Name           : xx_jtf_send_mail
-- Description    : Procedure is used to send mails to the User to notify about the
--                  approval progress
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_jtf_send_mail (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : xx_jtf_admin_appr
-- Description    : Procedure is used to send mails to the User to notify about the
--                  approval progress and also send a notification to the Admin
--                  to create user account for the User.
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_jtf_admin_appr (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : xx_jtf_usr_approved
-- Description    : Procedure is used to send mails to the User to notify about the
--                  approval completion at different level
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_jtf_usr_approved (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : xx_jtf_usr_rejected
-- Description    : Procedure is used to send mails to the User to notify about the
--                  approval rejection of the User Creation request.
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
PROCEDURE xx_jtf_usr_rejected (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : xx_jtf_create_user
-- Description    : Procedure is used to create contact , relationship , account roles
--                  contact points.
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
PROCEDURE xx_jtf_create_user (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );


-- =================================================================================
-- Name           : cust_get_approver
-- Description    : Procedure is used to get Next Approver in AME
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE cust_get_approver (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : upd_appr_status
-- Description    : Procedure is used to get Update Approval Status for AME Approver
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
PROCEDURE upd_appr_status (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : upd_rejected_status
-- Description    : Procedure is used to get Update Approval Reject Status for AME Approver
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
PROCEDURE upd_rejected_status (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   );
----------------------------------------------------------------------
END xx_jtf_user_reg_pkg;
/
