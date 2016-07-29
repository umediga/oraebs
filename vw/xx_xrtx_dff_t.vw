DROP VIEW APPS.XX_XRTX_DFF_T;

/* Formatted on 6/6/2016 4:56:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_DFF_T
(
   APPLICATION_ID,
   APPLICATION_NAME,
   DESCRIPTIVE_FLEXFIELD_NAME,
   FORM_CONTEXT_PROMPT,
   FLEX_VALUE_SET_NAME,
   DEFAULT_CONTEXT_VALUE,
   DEFAULT_CONTEXT_FIELD_NAME,
   CONTEXT_REQUIRED_FLAG,
   CONTEXT_USER_OVERRIDE_FLAG,
   CONTEXT_SYNCHRONIZATION_FLAG
)
AS
   SELECT DISTINCT c.application_id,
                   c.application_name,
                   a.descriptive_flexfield_name,
                   a.form_context_prompt,
                   b.flex_value_set_name,
                   a.default_context_value,
                   a.default_context_field_name,
                   a.context_required_flag,
                   a.context_user_override_flag,
                   a.context_synchronization_flag
     FROM FND_FLEX_VALUE_SETS b,
          fnd_application_tl c,
          FND_DESCRIPTIVE_FLEXS_vl a
    WHERE     a.context_override_value_set_id = b.flex_value_set_id
          AND a.descriptive_flexfield_name NOT LIKE '$SRS$%'
          AND a.application_id = c.application_id
   UNION
   SELECT DISTINCT c.application_id,
                   c.application_name,
                   a.descriptive_flexfield_name,
                   a.form_context_prompt,
                   NULL,
                   a.default_context_value,
                   a.default_context_field_name,
                   a.context_required_flag,
                   a.context_user_override_flag,
                   a.context_synchronization_flag
     FROM fnd_application_tl c, FND_DESCRIPTIVE_FLEXS_vl a
    WHERE     a.context_override_value_set_id IS NULL
          AND a.descriptive_flexfield_name NOT LIKE '$SRS$%'
          AND a.application_id = c.application_id;
