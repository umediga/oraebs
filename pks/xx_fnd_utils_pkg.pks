DROP PACKAGE APPS.XX_FND_UTILS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_FND_UTILS_PKG" IS
g_prefix varchar2(4) := NULL;
procedure create_user;
procedure xx_copy_responsibility;
procedure xx_copy_responsibility_xns;
procedure assign_responsibility;
procedure xx_copy_menu;
procedure xx_copy_menu_ex_setup;
procedure xx_copy_menu_ex_xns;
procedure xx_copy_rbac_menu (p_top_menu_name IN VARCHAR);   -- Added on 04/16/2012.
procedure xx_data_cleanup;
end xx_fnd_utils_pkg; 
/


GRANT EXECUTE ON APPS.XX_FND_UTILS_PKG TO INTG_XX_NONHR_RO;
