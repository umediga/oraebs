DROP VIEW APPS.XXINTG_HR_REPORT_ORG_MATRIX_V;

/* Formatted on 6/6/2016 5:00:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_HR_REPORT_ORG_MATRIX_V
(
   FULL_NAME,
   HR_LOGIN,
   HR_PERSON_ID,
   PERSON_ID,
   LOCATION_ID,
   HR_REPORTING_ORG
)
AS
   SELECT Papf.Full_Name,
          Fu.User_Name "HR_LOGIN",
          Papf.Person_Id "HR_PERSON_ID",
          asgn.person_id "PERSON_ID",
          Loc.Location_Code "LOCATION_ID",
          Puc.User_Column_Name "HR_REPORTING_ORG"
     FROM Apps.Pay_User_Tables Put,
          Apps.Pay_User_Columns Puc,
          Apps.Pay_User_Rows_F Pur,
          Apps.Pay_User_Column_Instances_F Puci,
          Apps.Hr_Locations Loc,
          Apps.Hr_Location_Extra_Info Lei,
          Apps.Per_All_People_F Papf,
          Apps.Fnd_User Fu,
          apps.per_all_assignments_f asgn
    WHERE     1 = 1
          AND Put.User_Table_Name = 'INTG_HR_REPORTING_ORG'
          AND Put.User_Table_Id = Puc.User_Table_Id
          AND Put.User_Table_Id = Pur.User_Table_Id
          AND Puci.User_Row_Id = Pur.User_Row_Id
          AND Puci.User_Column_Id = Puc.User_Column_Id
          AND pur.row_low_range_or_name <> 'Executive'
          AND Loc.Location_Id = Lei.Location_Id
          AND Lei.Information_Type = 'INTG_HR_Location_Security'
          AND Lei.Lei_Information_Category = 'INTG_HR_Location_Security'
          AND Lei.Lei_Information1 = Puci.VALUE
          AND Puci.VALUE = TO_CHAR (Papf.Person_Id)
          AND TRUNC (SYSDATE) BETWEEN Papf.Effective_Start_Date
                                  AND Papf.Effective_End_Date
          AND TRUNC (SYSDATE) BETWEEN Pur.Effective_Start_Date
                                  AND Pur.Effective_End_Date
          AND TRUNC (SYSDATE) BETWEEN Puci.Effective_Start_Date
                                  AND Puci.Effective_End_Date
          AND Papf.Person_Id = Fu.Employee_Id
          AND Loc.Location_Id = Asgn.Location_Id
          AND Puc.User_Column_Name =
                 Apps.Xxintg_Hr_Get_Reporting_Org.Get_Reporting_Org (
                    Asgn.Person_Id,
                    TRUNC (SYSDATE))
          AND TRUNC (SYSDATE) BETWEEN Asgn.Effective_Start_Date
                                  AND Asgn.Effective_End_Date
          AND Asgn.Primary_Flag = 'Y'
          AND Asgn.Assignment_Type IN ('E', 'C')
          AND asgn.assignment_status_type_id NOT IN (5, 2);
