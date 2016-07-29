DROP PACKAGE APPS.XX_QP_PRCLST_QUAL_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_QP_PRCLST_QUAL_PKG AUTHID CURRENT_USER AS
  ----------------------------------------------------------------------
  /*
   Created By     : IBM Development Team
   Creation Date  : 11-Jun-2013
   File Name      : XXQPPRICLSTQUAL.pks
   Description    : This script creates the body of the package xx_qp_prclst_qual_pkg


  Change History:

  Version Date          Name                       Remarks
  ------- -----------   --------                   -------------------------------
  1.0     11-Sep-2013   IBM Development Team       Initial development.
  */
  ----------------------------------------------------------------------
  function main (
      P_List_Type  IN   VARCHAR2,
      P_List_Name IN   VARCHAR2,
      P_Grouping_Number IN   VARCHAR2,
       p_operator IN   VARCHAR2,
      P_Customer_Number IN   VARCHAR2,
      P_Customer_Name IN   VARCHAR2,
      P_Start_Date IN   DATE,
      P_End_Date IN   DATE,
      P_Precedence IN   VARCHAR2,
      P_Record_Type IN   VARCHAR2
   --   ,p_ret_status  OUT  VARCHAR2
     )
      RETURN VARCHAR;

      END;



/
