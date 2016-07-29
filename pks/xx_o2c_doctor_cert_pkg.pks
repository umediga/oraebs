DROP PACKAGE APPS.XX_O2C_DOCTOR_CERT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_O2C_DOCTOR_CERT_PKG" AUTHID CURRENT_USER
AS
/* $Header: XXO2CDOCTORCERTPKG.pks 1.0.0 2013/03/29 700:00:00 riqbal noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Raquib Iqbal
 Creation Date  : 29-Mar-2013
 Filename       : XXO2CDOCTORCERTPKG.pks
 Description    : This package is used to validate the order line eligibility and to apply hold using seeded API

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 29-Mar-2013   1.0       Raquib Iqbal        Initial development.

 */
--------------------------------------------------------------------------------

   ------------------------------------------------------------------------/*
   FUNCTION xx_val_ord_line_eligibility (
      p_item_id                NUMBER,
      p_organization_id   IN   NUMBER
   )
      RETURN VARCHAR2;

   PROCEDURE xx_apply_hold_on_order_line (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );

   FUNCTION xx_validate_order_line (
      p_attribute8         IN   VARCHAR2,
      p_item_id           IN   NUMBER,
      p_organization_id   IN   NUMBER,
      p_ordered_item      IN   VARCHAR2
   )
      RETURN VARCHAR2;
-------------------------------------------------------------------------------  /*
END xx_o2c_doctor_cert_pkg;
/
