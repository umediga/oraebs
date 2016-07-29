DROP PACKAGE APPS.XX_SDC_AR_RCPT_INTF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_AR_RCPT_INTF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Yogesh (IBM Development)
 Creation Date :
 File Name     : xxsdcarrcptintf.pks
 Description   : This script creates the specification of the package
                 xx_irc_emp_ref_notif_pkg.
 Change History:
 Date           Name                    Remarks
 ----------- -------------         -----------------------------------
 03-Mar-2014 Yogesh                Initial Version
*/
----------------------------------------------------------------------

PROCEDURE raise_publish_event;

    PROCEDURE main_prc( p_errbuf           OUT   VARCHAR2
                       ,p_retcode          OUT   NUMBER
                       ,p_type             IN    VARCHAR2
                       ,p_hidden1          IN    VARCHAR2
                       ,p_hidden2          IN    VARCHAR2
                       ,p_cust_site_from   IN    HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
                       ,p_cust_site_to     IN    HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
                       ,p_date_from        IN    VARCHAR2 DEFAULT NULL
                       ,p_date_to          IN    VARCHAR2 DEFAULT NULL
                       );
----------------------------------------------------------------------
FUNCTION ret_collection_status ( p_cust_account_id   IN   NUMBER)
RETURN VARCHAR2;
END xx_sdc_ar_rcpt_intf_pkg;
/
