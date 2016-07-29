DROP PACKAGE APPS.XX_PA_ACCT_GENERATION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PA_ACCT_GENERATION_PKG" 
AS

   PROCEDURE get_capt_acct_cc(p_itemtype  IN  VARCHAR2,
                                   p_itemkey   IN  VARCHAR2,
                                   p_actid     IN  NUMBER,
                                   p_funcmode  IN  VARCHAR2,
                                   x_result    OUT VARCHAR2);

   PROCEDURE get_exp_acct_cc(p_itemtype  IN  VARCHAR2,
                                  p_itemkey   IN  VARCHAR2,
                                  p_actid     IN  NUMBER,
                                  p_funcmode  IN  VARCHAR2,
                                  x_result    OUT VARCHAR2);

   PROCEDURE is_task_capitalizable( p_itemtype  IN  VARCHAR2,
                                    p_itemkey   IN  VARCHAR2,
                                    p_actid     IN  NUMBER,
                                    p_funcmode  IN  VARCHAR2,
                                    x_result    OUT VARCHAR2);

   PROCEDURE is_project_capitalizable( p_itemtype  IN  VARCHAR2,
                                       p_itemkey   IN  VARCHAR2,
                                       p_actid     IN  NUMBER,
                                       p_funcmode  IN  VARCHAR2,
                                       x_result    OUT VARCHAR2);

   PROCEDURE is_project_related ( p_itemtype  IN  VARCHAR2,
                                  p_itemkey   IN  VARCHAR2,
                                  p_actid     IN  NUMBER,
                                  p_funcmode  IN  VARCHAR2,
                                  x_result    OUT VARCHAR2
                                );

END  xx_pa_acct_generation_pkg;
/
