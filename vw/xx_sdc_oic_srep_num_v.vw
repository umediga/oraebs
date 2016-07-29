DROP VIEW APPS.XX_SDC_OIC_SREP_NUM_V;

/* Formatted on 6/6/2016 4:58:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_OIC_SREP_NUM_V
(
   SALESREP_NUMBER,
   SALESREP_NAME
)
AS
     SELECT jrs.salesrep_number, jrs.name
       FROM jtf_rs_salesreps jrs
      WHERE     jrs.status = 'A'
            AND SYSDATE BETWEEN NVL (jrs.start_date_active, SYSDATE)
                            AND NVL (jrs.end_date_active, SYSDATE)
            AND EXISTS
                   (SELECT lookup_code
                      FROM fnd_lookup_values_vl
                     WHERE     lookup_type = 'XX_SFDC_OU_LOOKUP'
                           AND lookup_code = jrs.org_id
                           AND NVL (enabled_flag, 'X') = 'Y'
                           AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                           AND NVL (end_date_active, SYSDATE))
   ORDER BY jrs.salesrep_number DESC;
