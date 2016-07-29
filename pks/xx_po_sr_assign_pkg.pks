DROP PACKAGE APPS.XX_PO_SR_ASSIGN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_SR_ASSIGN_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Yogesh (IBM Development)
 Creation Date : 29-APR-2013
 File Name     : xxposrassign.pks
 Description   : This script creates the specification of the package
                 xx_po_sr_assign_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 29-Apr-2013 Yogesh               Initial Version
*/
----------------------------------------------------------------------

g_assignment_type_id              NUMBER;
g_sr_type_id                      NUMBER;
g_assignment_set_id               NUMBER;

TYPE G_XX_PO_SR_ASSIGN_REC_TYPE IS RECORD
( request_id              NUMBER
 ,item_id                 NUMBER
 ,organization_id         NUMBER
 ,vendor_id               NUMBER
 ,sr_id                   NUMBER
 ,sr_name                 VARCHAR2(50)
 ,assignment_type_id      NUMBER
 ,sr_type_id              NUMBER
 ,process_code            VARCHAR2(100)
 ,error_code              VARCHAR2(100)
 ,error_message           VARCHAR2(4000)
 ,created_by              NUMBER
 ,creation_date           DATE
 ,last_update_date        DATE
 ,last_updated_by         NUMBER
 ,last_update_login       NUMBER
 ,attribute1              VARCHAR2 (100)
 ,attribute2              VARCHAR2 (100)
 ,attribute3              VARCHAR2 (100)
 ,attribute4              VARCHAR2 (100)
 ,attribute5              VARCHAR2 (100)
);

TYPE G_XX_PO_SR_ASSIGN_TAB_TYPE IS TABLE OF G_XX_PO_SR_ASSIGN_REC_TYPE
INDEX BY BINARY_INTEGER;

----------------------------------------------------------------------
PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                    ,p_retcode       OUT VARCHAR2
                    ,p_org_id        IN  NUMBER
                    );
END xx_po_sr_assign_pkg;
/
