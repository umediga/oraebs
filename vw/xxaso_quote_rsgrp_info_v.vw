DROP VIEW APPS.XXASO_QUOTE_RSGRP_INFO_V;

/* Formatted on 6/6/2016 5:00:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXASO_QUOTE_RSGRP_INFO_V
(
   GROUP_ID,
   GROUP_NAME
)
AS
   SELECT "GROUP_ID", "GROUP_NAME"
     FROM (SELECT DISTINCT jrgm.GROUP_ID, jrgt.group_name
             FROM jtf_rs_group_members jrgm,
                  jtf_rs_groups_tl jrgt,
                  jtf_rs_group_usages jrgu
            WHERE     jrgm.GROUP_ID = jrgt.GROUP_ID
                  AND jrgt.LANGUAGE = USERENV ('LANG')
                  AND jrgu.GROUP_ID = jrgm.GROUP_ID
                  AND jrgu.USAGE = 'SALES'
                  AND NVL (jrgm.delete_flag, 'N') <> 'Y'
                  AND EXISTS
                         (SELECT 1
                            FROM jtf_rs_role_relations jrrr
                           WHERE     jrrr.role_resource_id =
                                        jrgm.group_member_id
                                 AND NVL (jrrr.start_date_active, SYSDATE) <=
                                        SYSDATE
                                 AND NVL (jrrr.end_date_active, SYSDATE) >=
                                        SYSDATE
                                 AND jrrr.role_resource_type =
                                        'RS_GROUP_MEMBER'
                                 AND NVL (jrrr.delete_flag, 'N') <> 'Y'
                                 AND ROWNUM = 1));
