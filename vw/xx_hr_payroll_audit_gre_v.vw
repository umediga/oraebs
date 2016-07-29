DROP VIEW APPS.XX_HR_PAYROLL_AUDIT_GRE_V;

/* Formatted on 6/6/2016 4:58:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_PAYROLL_AUDIT_GRE_V
(
   GRE
)
AS
   SELECT DISTINCT org.name gre                 --,paaf.soft_coding_keyflex_id
     FROM per_all_assignments_f paaf,
          hr_soft_coding_keyflex flx,
          hr_organization_units org
    WHERE     paaf.primary_flag = 'Y'
          AND paaf.soft_coding_keyflex_id = flx.soft_coding_keyflex_id(+)
          AND flx.segment1 = org.organization_id
          AND SYSDATE BETWEEN paaf.effective_start_date
                          AND paaf.effective_end_date;
