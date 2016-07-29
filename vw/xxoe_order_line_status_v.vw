DROP VIEW APPS.XXOE_ORDER_LINE_STATUS_V;

/* Formatted on 6/6/2016 5:00:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXOE_ORDER_LINE_STATUS_V
(
   FLOW_STATUS_CODE
)
AS
     SELECT ool.flow_status_code
       FROM oe_order_lines_all ool
      WHERE NOT EXISTS
               (SELECT 1
                  FROM xx_emf_process_setup xeps,
                       xx_emf_process_parameters xepp
                 WHERE     xeps.process_name = 'XX_OE_ASSIGN_SALESREP'
                       AND xeps.process_id = xepp.process_id
                       AND UPPER (xepp.parameter_name) LIKE
                              'ORDER_LINE_STATUS%'
                       AND NVL (xepp.enabled_flag, 'Y') <> 'N'
                       AND ool.flow_status_code = UPPER (xepp.parameter_value))
   GROUP BY ool.flow_Status_code;
