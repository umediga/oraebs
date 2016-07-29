DROP VIEW APPS.XXINTG_COMMISSION_DCODES_V;

/* Formatted on 6/6/2016 5:00:24 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_COMMISSION_DCODES_V
(
   ORG_ID,
   REV_NAME,
   USER_TYPE_NAME,
   ATTRIBUTE_NAME,
   OPERATOR_MEANING,
   LOW_VALUE,
   HIGH_VALUE
)
AS
   (SELECT DISTINCT
           abc.ORG_ID,
           UPPER (SUBSTR (abc.name, 1, 5)) Rev_name,
           abc.user_type_name,
           abc.attribute_name,
           'BETWEEN' Operator_meaning,
           abc.low_value,
           DECODE (abc.high_value, NULL, abc.low_value, abc.high_value)
              high_value
      FROM (SELECT CRV.NAME,
                   --CAR.ATTRIBUTE_RULE_ID,
                   CAR.ORG_ID,
                   CO.USER_NAME user_type_name,
                   CO.NAME attribute_name,
                   --CAR.COLUMN_ID,
                   --CAR.OBJECT_VERSION_NUMBER,
                   --CAR.NOT_FLAG,
                   --DECODE(CAR.HIGH_VALUE,NULL,
                   --  decode(CO.DATA_TYPE,'DATE',TO_CHAR(TO_DATE(CAR.COLUMN_VALUE,'DD/MM/RRRR')),CAR.COLUMN_VALUE),
                   --  decode(CO.DATA_TYPE,'DATE',TO_CHAR(TO_DATE(CAR.LOW_VALUE,'DD/MM/RRRR')),CAR.LOW_VALUE)) as LOW_VALUE,
                   --decode(CO.DATA_TYPE,'DATE',TO_CHAR(TO_DATE(CAR.HIGH_VALUE,'DD/MM/RRRR')),CAR.HIGH_VALUE) as HIGH_VALUE,
                   --CAR.RULESET_ID, CAR.RULE_ID, CO.VALUE_SET_ID, CO.USER_NAME, CO.OBJECT_ID, CO.NAME,
                   --decode(CO.VALUE_SET_ID,null,decode(CO.DATA_TYPE,'DATE','DATE','TEXT'),'LOV') as Field_Type1,
                   --decode(CO.VALUE_SET_ID,null,decode(CO.DATA_TYPE,'DATE','DATE1','TEXT1'),'LOV1') as Field_Type2,
                   --CN_RuleAttribute_PVT.get_operator(CAR.ATTRIBUTE_RULE_ID,CAR.ORG_ID) as OPERATOR_MEANING,
                   --CN_RuleAttribute_PVT.get_rendered(CAR.ATTRIBUTE_RULE_ID,CAR.ORG_ID) as RENDERED,
                   DECODE (
                      CAR.HIGH_VALUE,
                      NULL, DECODE (
                               CO.DATA_TYPE,
                               'DATE', TO_CHAR (
                                          TO_DATE (CAR.COLUMN_VALUE,
                                                   'DD/MM/RRRR')),
                               CAR.COLUMN_VALUE),
                      DECODE (
                         CO.DATA_TYPE,
                         'DATE', TO_CHAR (
                                    TO_DATE (CAR.LOW_VALUE, 'DD/MM/RRRR')),
                         CAR.LOW_VALUE))
                      AS LOW_VALUE,
                   DECODE (
                      CO.DATA_TYPE,
                      'DATE', TO_CHAR (
                                 TO_DATE (CAR.HIGH_VALUE, 'DD/MM/RRRR')),
                      CAR.HIGH_VALUE)
                      AS HIGH_VALUE
              --CO.DATA_TYPE
              FROM CN_ATTRIBUTE_RULES CAR, CN_OBJECTS CO, CN_RULES_V CRV
             WHERE     1 = 1
                   --and UPPER(crv.name) like 'NEURO%'
                   AND CAR.RULE_ID = CRV.RULE_ID
                   AND CAR.DIMENSION_HIERARCHY_ID IS NULL
                   AND CO.OBJECT_ID = CAR.COLUMN_ID
                   AND CO.TABLE_ID IN (-11803, -16134)
                   AND CAR.org_id = CO.org_id     --and CO.NAME = 'ATTRIBUTE6'
                                             ) abc);
