DROP VIEW APPS.XX_BI_FI_ODR_MNF_V;

/* Formatted on 6/6/2016 4:59:44 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_ODR_MNF_V
(
   ALTERNATE_BOM,
   ALTERNATE_ROUTING,
   BOM_REVISION_DATE,
   COMPLETION_DATE,
   CREATION_DATE,
   DEMAND_CLASS,
   DESCRIPTION,
   LAST_UPDATE_DATE,
   MFG_ORDER_NAME,
   ORDER_CLOSED_DATE,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   ROUTING_REVISION_DATE,
   START_DATE,
   BOM_REVISION_DATE_DAY,
   BOM_REVISION_DATE_MONTH,
   BOM_REVISION_DATE_QUARTER,
   BOM_REVISION_DATE_DATE,
   COMPLETION_DATE_DAY,
   COMPLETION_DATE_MONTH,
   COMPLETION_DATE_QUARTER,
   COMPLETION_DATE_YEAR,
   ORDER_CLOSED_DATE_DAY,
   ORDER_CLOSED_DATE_MONTH,
   ORDER_CLOSED_DATE_QUARTER,
   ORDER_CLOSED_DATE_YEAR,
   ROUTING_REVISION_DATE_DAY,
   ROUTING_REVISION_DATE_MONTH,
   ROUTING_REVISION_DATE_QUARTER,
   ROUTING_REVISION_DATE_YEAR,
   START_DATE_DAY,
   START_DATE_MONTH,
   START_DATE_QUARTER,
   START_DATE_YEAR,
   MFG_ORDER_TYPE,
   MFG_ORDER_STATUS,
   ITEM_NUMBER,
   COMPLETED_QUANTITY
)
AS
   SELECT DI.ALTERNATE_BOM_DESIGNATOR ALTERNATE_BOM,
          DI.ALTERNATE_ROUTING_DESIGNATOR ALTERNATE_ROUTING,
          DI.BOM_REVISION_DATE,
          DI.SCHEDULED_COMPLETION_DATE COMPLETION_DATE,
          EN.CREATION_DATE,
          DI.DEMAND_CLASS,
          EN.DESCRIPTION,
          EN.LAST_UPDATE_DATE,
          NULL,
          DI.DATE_CLOSED ORDER_CLOSED_DATE,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          DI.ROUTING_REVISION_DATE,
          DI.SCHEDULED_START_DATE START_DATE,
          (DECODE (
              DI.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.BOM_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             BOM_REVISION_DATE_DAY,
          (DECODE (
              DI.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (DI.BOM_REVISION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_MONTH,
          (DECODE (
              DI.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (DI.BOM_REVISION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_QUARTER,
          (DECODE (
              DI.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.BOM_REVISION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             BOM_REVISION_DATE_YEAR,
          (DECODE (
              DI.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_COMPLETION_DATE, 'DD'),
                             'DD')
                 || '190001',
                 'DDYYYYMM')))
             COMPLETION_DATE_DAY,
          (DECODE (
              DI.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_COMPLETION_DATE, 'MM'),
                             'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_MONTH,
          (DECODE (
              DI.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_COMPLETION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_QUARTER,
          (DECODE (
              DI.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_COMPLETION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             COMPLETION_DATE_YEAR,
          (DECODE (
              DI.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (DI.DATE_CLOSED, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             ORDER_CLOSED_DATE_DAY,
          (DECODE (
              DI.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (DI.DATE_CLOSED, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             ORDER_CLOSED_DATE_MONTH,
          (DECODE (
              DI.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (DI.DATE_CLOSED, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             ORDER_CLOSED_DATE_QUARTER,
          (DECODE (
              DI.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (DI.DATE_CLOSED, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             ORDER_CLOSED_DATE_YEAR,
          (DECODE (
              DI.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.ROUTING_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             RTNG_REVISN_DTE_DAY,
          (DECODE (
              DI.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.ROUTING_REVISION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             RTNG_REVISN_DTE_MNTH,
          (DECODE (
              DI.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.ROUTING_REVISION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             RTNG_REVISN_DTE_QTR,
          (DECODE (
              DI.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.ROUTING_REVISION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             RTNG_REVISN_DTE_YR,
          (DECODE (
              DI.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_START_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             START_DATE_DAY,
          (DECODE (
              DI.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_START_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             START_DATE_MONTH,
          (DECODE (
              DI.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (SCHEDULED_START_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             STRT_DATE_QTR,
          (DECODE (
              DI.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (DI.SCHEDULED_START_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             START_DATE_YR,
          DECODE (EN.ENTITY_TYPE,
                  '1', 'Discrete job',
                  '2', 'Repetitive assembly',
                  '3', 'Closed discrete job',
                  '4', 'Flow schedule',
                  '5', 'Lot based job',
                  '6', 'Maintenance job',
                  '7', 'Closed maintenance job',
                  '8', 'Closed lot based job',
                  NULL)
             MFG_ORDER_TYPE,
          DECODE (DI.STATUS_TYPE,
                  '1', 'Unreleased',
                  '10', 'Pending Routing Load',
                  '11', 'Failed Routing Load',
                  '12', 'Closed',
                  '13', 'Pending - Mass Loaded',
                  '14', 'Pending Close',
                  '15', 'Failed Close',
                  '16', 'Pending Scheduling',
                  '17', 'Draft',
                  '3', 'Released',
                  '4', 'Complete',
                  '5', 'Complete - No Charges',
                  '6', 'On Hold',
                  '7', 'Cancelled',
                  '8', 'Pending Bill Load',
                  '9', 'Failed Bill Load',
                  NULL)
             MFG_ORDER_STATUS,
          MSIB.SEGMENT1 ITEM_NUMBER,
          DI.QUANTITY_COMPLETED
     FROM MTL_SYSTEM_ITEMS_B MSIB,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          WIP_ENTITIES EN,
          WIP_DISCRETE_JOBS DI
    WHERE     DI.WIP_ENTITY_ID = EN.WIP_ENTITY_ID
          AND DI.ORGANIZATION_ID = OOD.ORGANIZATION_ID
          AND DI.PRIMARY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND DI.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
   --AND HR_SECURITY.SHOW_BIS_RECORD (DI.ORGANIZATION_ID) = 'TRUE'
   UNION
   SELECT RE.ALTERNATE_BOM_DESIGNATOR ALTERNATE_BOM,
          RE.ALTERNATE_ROUTING_DESIGNATOR ALTERNATE_ROUTING,
          RE.BOM_REVISION_DATE,
          RE.LAST_UNIT_COMPLETION_DATE COMPLETION_DATE,
          EN.CREATION_DATE,
          RE.DEMAND_CLASS,
          EN.DESCRIPTION,
          EN.LAST_UPDATE_DATE,
          NULL,
          RE.DATE_CLOSED ORDER_CLOSED_DATE,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          RE.ROUTING_REVISION_DATE,
          RE.FIRST_UNIT_START_DATE START_DATE,
          (DECODE (
              RE.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.BOM_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             BOM_REVISION_DATE_DAY,
          (DECODE (
              RE.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (RE.BOM_REVISION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_MONTH,
          (DECODE (
              RE.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (RE.BOM_REVISION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_QUARTER,
          (DECODE (
              RE.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.BOM_REVISION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             BOM_REVISION_DATE_YEAR,
          (DECODE (
              RE.LAST_UNIT_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.LAST_UNIT_COMPLETION_DATE, 'DD'),
                             'DD')
                 || '190001',
                 'DDYYYYMM')))
             COMPLETION_DATE_DAY,
          (DECODE (
              RE.LAST_UNIT_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.LAST_UNIT_COMPLETION_DATE, 'MM'),
                             'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_MONTH,
          (DECODE (
              RE.LAST_UNIT_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.LAST_UNIT_COMPLETION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_QUARTER,
          (DECODE (
              RE.LAST_UNIT_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.LAST_UNIT_COMPLETION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             COMPLETION_DATE_YEAR,
          (DECODE (
              RE.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (RE.DATE_CLOSED, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             ORDER_CLOSED_DATE_DAY,
          (DECODE (
              RE.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (RE.DATE_CLOSED, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             ORDER_CLOSED_DATE_MONTH,
          (DECODE (
              RE.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (RE.DATE_CLOSED, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             ORDER_CLOSED_DATE_QUARTER,
          (DECODE (
              RE.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (RE.DATE_CLOSED, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             ORDER_CLOSED_DATE_YEAR,
          (DECODE (
              RE.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.ROUTING_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             ROUTING_REVISION_DATE_DAY,
          (DECODE (
              RE.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.ROUTING_REVISION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ROUTING_REVISION_DATE_MONTH,
          (DECODE (
              RE.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.ROUTING_REVISION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ROUTING_REVISION_DATE_QUARTER,
          (DECODE (
              RE.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.ROUTING_REVISION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             ROUTING_REVISION_DATE_YEAR,
          (DECODE (
              RE.FIRST_UNIT_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.FIRST_UNIT_START_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             START_DATE_DAY,
          (DECODE (
              RE.FIRST_UNIT_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.FIRST_UNIT_START_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             START_DATE_MONTH,
          (DECODE (
              RE.FIRST_UNIT_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.FIRST_UNIT_START_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             START_DATE_QUARTER,
          (DECODE (
              RE.FIRST_UNIT_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (RE.FIRST_UNIT_START_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             START_DATE_YEAR,
          DECODE (EN.ENTITY_TYPE,
                  '1', 'Discrete job',
                  '2', 'Repetitive assembly',
                  '3', 'Closed discrete job',
                  '4', 'Flow schedule',
                  '5', 'Lot based job',
                  '6', 'Maintenance job',
                  '7', 'Closed maintenance job',
                  '8', 'Closed lot based job',
                  NULL)
             MFG_ORDER_TYPE,
          DECODE (RE.STATUS_TYPE,
                  '1', 'Unreleased',
                  '10', 'Pending Routing Load',
                  '11', 'Failed Routing Load',
                  '12', 'Closed',
                  '13', 'Pending - Mass Loaded',
                  '14', 'Pending Close',
                  '15', 'Failed Close',
                  '16', 'Pending Scheduling',
                  '17', 'Draft',
                  '3', 'Released',
                  '4', 'Complete',
                  '5', 'Complete - No Charges',
                  '6', 'On Hold',
                  '7', 'Cancelled',
                  '8', 'Pending Bill Load',
                  '9', 'Failed Bill Load',
                  NULL)
             MFG_ORDER_STATUS,
          MSIB.SEGMENT1 ITEM_NUMBER,
          RE.QUANTITY_COMPLETED
     FROM MTL_SYSTEM_ITEMS_B MSIB,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          WIP_ENTITIES EN,
          WIP_REPETITIVE_ITEMS IT,
          WIP_REPETITIVE_SCHEDULES RE
    WHERE     RE.WIP_ENTITY_ID = EN.WIP_ENTITY_ID
          AND RE.WIP_ENTITY_ID = IT.WIP_ENTITY_ID
          AND RE.LINE_ID = IT.LINE_ID
          AND RE.ORGANIZATION_ID = OOD.ORGANIZATION_ID
          AND IT.PRIMARY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND IT.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
   --AND HR_SECURITY.SHOW_BIS_RECORD (RE.ORGANIZATION_ID) = 'TRUE'
   UNION
   SELECT FL.ALTERNATE_BOM_DESIGNATOR ALTERNATE_BOM,
          FL.ALTERNATE_ROUTING_DESIGNATOR ALTERNATE_ROUTING,
          FL.BOM_REVISION_DATE,
          FL.SCHEDULED_COMPLETION_DATE COMPLETION_DATE,
          EN.CREATION_DATE,
          FL.DEMAND_CLASS,
          EN.DESCRIPTION,
          EN.LAST_UPDATE_DATE,
          NULL,
          FL.DATE_CLOSED ORDER_CLOSED_DATE,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          FL.ROUTING_REVISION_DATE,
          FL.SCHEDULED_START_DATE START_DATE,
          (DECODE (
              FL.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.BOM_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             BOM_REVISION_DATE_DAY,
          (DECODE (
              FL.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (FL.BOM_REVISION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_MONTH,
          (DECODE (
              FL.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (FL.BOM_REVISION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             BOM_REVISION_DATE_QUARTER,
          (DECODE (
              FL.BOM_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.BOM_REVISION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             BOM_REVISION_DATE_YEAR,
          (DECODE (
              FL.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_COMPLETION_DATE, 'DD'),
                             'DD')
                 || '190001',
                 'DDYYYYMM')))
             COMPLETION_DATE_DAY,
          (DECODE (
              FL.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_COMPLETION_DATE, 'MM'),
                             'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_MONTH,
          (DECODE (
              FL.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_COMPLETION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             COMPLETION_DATE_QUARTER,
          (DECODE (
              FL.SCHEDULED_COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_COMPLETION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             COMPLETION_DATE_YEAR,
          (DECODE (
              FL.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (FL.DATE_CLOSED, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             ORDER_CLOSED_DATE_DAY,
          (DECODE (
              FL.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (FL.DATE_CLOSED, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             ORDER_CLOSED_DATE_MONTH,
          (DECODE (
              FL.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (FL.DATE_CLOSED, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             ORDER_CLOSED_DATE_QUARTER,
          (DECODE (
              FL.DATE_CLOSED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (FL.DATE_CLOSED, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             ORDER_CLOSED_DATE_YEAR,
          (DECODE (
              FL.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.ROUTING_REVISION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             ROUTING_REVISION_DATE_DAY,
          (DECODE (
              FL.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.ROUTING_REVISION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ROUTING_REVISION_DATE_MONTH,
          (DECODE (
              FL.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.ROUTING_REVISION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ROUTING_REVISION_DATE_QUARTER,
          (DECODE (
              FL.ROUTING_REVISION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.ROUTING_REVISION_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             ROUTING_REVISION_DATE_YEAR,
          (DECODE (
              FL.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_START_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             START_DATE_DAY,
          (DECODE (
              FL.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_START_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             START_DATE_MONTH,
          (DECODE (
              FL.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_START_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             START_DATE_QUARTER,
          (DECODE (
              FL.SCHEDULED_START_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (FL.SCHEDULED_START_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             START_DATE_YEAR,
          DECODE (EN.ENTITY_TYPE,
                  '1', 'Discrete job',
                  '2', 'Repetitive assembly',
                  '3', 'Closed discrete job',
                  '4', 'Flow schedule',
                  '5', 'Lot based job',
                  '6', 'Maintenance job',
                  '7', 'Closed maintenance job',
                  '8', 'Closed lot based job',
                  NULL)
             MFG_ORDER_TYPE,
          DECODE (FL.STATUS,  '1', 'Open',  '2', 'Closed',  NULL)
             MFG_ORDER_STATUS,
          MSIB.SEGMENT1 ITEM_NUMBER,
          FL.QUANTITY_COMPLETED
     FROM MTL_SYSTEM_ITEMS_B MSIB,
          WIP_ENTITIES EN,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          WIP_FLOW_SCHEDULES FL
    WHERE     FL.WIP_ENTITY_ID = EN.WIP_ENTITY_ID
          AND FL.ORGANIZATION_ID = OOD.ORGANIZATION_ID
          AND FL.PRIMARY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND FL.ORGANIZATION_ID = MSIB.ORGANIZATION_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_ODR_MNF_V FOR APPS.XX_BI_FI_ODR_MNF_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_ODR_MNF_V FOR APPS.XX_BI_FI_ODR_MNF_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_ODR_MNF_V FOR APPS.XX_BI_FI_ODR_MNF_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_ODR_MNF_V FOR APPS.XX_BI_FI_ODR_MNF_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ODR_MNF_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ODR_MNF_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ODR_MNF_V TO XXINTG;
