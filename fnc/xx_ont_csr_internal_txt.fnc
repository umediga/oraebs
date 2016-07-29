DROP FUNCTION APPS.XX_ONT_CSR_INTERNAL_TXT;

CREATE OR REPLACE FUNCTION APPS."XX_ONT_CSR_INTERNAL_TXT" (p_ord_hdr_id in NUMBER)
RETURN VARCHAR2 AS
l_st_txt VARCHAR2(4000);
BEGIN
     select fdst.short_text
     into l_st_txt
     from FND_ATTACHED_DOCUMENTS a
         ,fnd_document_categories_tl FDC
         ,FND_DOCUMENTS FD
         ,fnd_documents_short_text FDST
     WHERE a.ENTITY_NAME = 'OE_ORDER_HEADERS'
     and a.category_id = FDC.category_id
     AND a.document_id = fd.document_id
     AND fd.media_id = fdst.media_id
     AND a.PK1_VALUE = p_ord_hdr_id
     AND fdc.LANGUAGE = 'US'
     AND fdc.USER_NAME = 'CSR Internal';

     return(l_st_txt);
EXCEPTION
WHEN OTHERS THEN
     return NULL;
END;
/
