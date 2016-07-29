DROP FUNCTION APPS.XX_AR_GL_CC;

CREATE OR REPLACE FUNCTION APPS."XX_AR_GL_CC" (
   p_trx_line_id   IN   NUMBER,
   p_line_type     IN   VARCHAR,
   p_type          IN   VARCHAR
)
   RETURN VARCHAR2
AS
   l_st_txt    VARCHAR2 (200);
   l_gl_date   VARCHAR2 (200);
   l_type      VARCHAR2 (100);
   l_count     NUMBER;
BEGIN
   IF p_line_type = 'TAX'
   THEN
      l_type := 'TAX';
   ELSIF p_line_type = 'LINE'
   THEN
      l_type := 'REV';
   ELSIF p_line_type = 'CB'
   THEN
      l_type := 'REV';
   ELSIF p_line_type = 'FREIGHT'
   THEN
      l_type := 'FREIGHT';
   ELSE
      l_type := 'REC';
   END IF;

   BEGIN
      SELECT COUNT (1)
        INTO l_count
        FROM ra_cust_trx_line_gl_dist_all a, gl_code_combinations glcc
       WHERE a.customer_trx_line_id = p_trx_line_id
         AND glcc.code_combination_id = a.code_combination_id
         AND a.account_class = l_type
         AND a.gl_date IS NOT NULL;
   END;

   IF l_count = 1
   THEN
      SELECT    'GL-'
             || glcc.segment1
             || '-'
             || glcc.segment2
             || '-'
             || glcc.segment3
             || '-'
             || glcc.segment4
             || '-'
             || glcc.segment5
             || '-'
             || glcc.segment6
             || '-'
             || glcc.segment7
             || '-'
             || glcc.segment8,
             TO_CHAR (a.gl_date, 'DD-MON-YYYY')
        INTO l_st_txt,
             l_gl_date
        FROM ra_cust_trx_line_gl_dist_all a, gl_code_combinations glcc
       WHERE a.customer_trx_line_id = p_trx_line_id
         AND glcc.code_combination_id = a.code_combination_id
         AND a.account_class = l_type
         AND a.gl_date IS NOT NULL;
   ELSE
      SELECT    'GL-'
             || glcc.segment1
             || '-'
             || glcc.segment2
             || '-'
             || glcc.segment3
             || '-'
             || '00000'
             || '-'
             || '000'
             || '-'
             || '000'
             || '-'
             || '000'
             || '-'
             || '00000',
             TO_CHAR (a.gl_date, 'DD-MON-YYYY')
        INTO l_st_txt,
             l_gl_date
        FROM ra_cust_trx_line_gl_dist_all a, gl_code_combinations glcc
       WHERE a.customer_trx_line_id = p_trx_line_id
         AND glcc.code_combination_id = a.code_combination_id
         AND a.account_class = l_type
         AND a.gl_date IS NOT NULL
         AND ROWNUM = 1;
   END IF;

   IF p_type = 'GL'
   THEN
      RETURN (l_st_txt);
   ELSIF p_type = 'DATE'
   THEN
      RETURN (l_gl_date);
   ELSE
      RETURN NULL;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN NULL;
END;
/
