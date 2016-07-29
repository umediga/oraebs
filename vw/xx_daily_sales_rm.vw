DROP VIEW APPS.XX_DAILY_SALES_RM;

/* Formatted on 6/6/2016 4:58:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_DAILY_SALES_RM
(
   SOURCE_NAME
)
AS
     SELECT DISTINCT res.source_name
       FROM jtf_rs_role_relations jrr,
            jtf_rs_roles_b jrb,
            jtf_rs_roles_tl jrbt,
            jtf_rs_resource_extns res
      WHERE     1 = 1
            AND jrr.role_id = jrb.role_id
            AND jrb.role_id = jrbt.role_id
            AND jrbt.LANGUAGE = 'US'
            AND jrr.role_resource_id = res.resource_id
            --  AND jrb.role_type_code LIKE 'SALES_COMP'
            AND jrb.manager_flag = 'Y'
            AND res.source_name IS NOT NULL
            AND TRUNC (SYSDATE) BETWEEN TRUNC (JRR.start_date_active)
                                    AND NVL (TRUNC (JRR.end_date_active),
                                             TRUNC (SYSDATE + 1))
            AND TRUNC (SYSDATE) BETWEEN TRUNC (res.start_date_active)
                                    AND NVL (TRUNC (res.end_date_active),
                                             TRUNC (SYSDATE + 1))
   --   AND res.source_name like 'Bergman, Robert'
   ORDER BY 1;
