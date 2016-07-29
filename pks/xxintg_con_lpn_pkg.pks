DROP PACKAGE APPS.XXINTG_CON_LPN_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_CON_LPN_PKG" AS

FUNCTION CREATE_LPN(p_lpn_name in VARCHAR2, p_organization_id in NUMBER,
                    p_return_status    IN  OUT  VARCHAR2,
                    p_return_code            IN  OUT     VARCHAR2,
                    p_return_message   IN  OUT  VARCHAR2)
RETURN NUMBER;
PROCEDURE PACK_LPN(p_lpn_contents intg_t_lpn_contents_t, 
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code            IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
                   );
PROCEDURE UNPACK_LPN(p_lpn_contents intg_t_lpn_contents_t, 
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code            IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
                   );
END; 
/
