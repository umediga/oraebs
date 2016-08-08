DROP FUNCTION APPS.XXSS_OIC_YTD_QUOTA_FN;

CREATE OR REPLACE FUNCTION APPS.XXSS_OIC_YTD_QUOTA_FN
          (p_salesrep_id IN NUMBER,
     			 p_period_id IN NUMBER,
    			 p_srp_plan_assign_id IN NUMBER,
           p_quota_id IN NUMBER)
/******************************************************************************************
*
*   FUNCTION
*     XXSS_OIC_YTD_QUOTA_FN
*
*   DESCRIPTION
*   The function will calculate Salesrep YTD Quota.
*
*   PARAMETERS
*   ==========
*   NAME                            TYPE           DESCRIPTION
*   -----------------               --------       -------------------------------------------------
*    p_sales_rep_id                 IN             The Oracle internal ID of the sales rep.
*    p_period_id                    IN             The Oracle internal ID for the period.
*    p_srp_plan_assign_id           IN             The Oracle internal ID for the plan assignment.
*    p_quota_id                     IN             The Oracle internal ID for the quota.
*
*     RETURN VALUE
*     Returns the YTD Quota value.
*
*   CALLED BY
*     The function is called by OIC to calculate Salesrep's YTD Quota.
*
*
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)  			DESCRIPTION
* ------- -----------	----------------	---------------------------------
* 1.0     15-Mar-2016   Dik Ahuja          Creation
*

**********************************************************************************************/
 RETURN NUMBER IS



  l_year                  NUMBER;
  l_ytd_quota             NUMBER := 0;


BEGIN

 cn_message_pkg.DEBUG ('Step1: Get Period Year');

    SELECT   period_year
     INTO l_year
    FROM cn_period_statuses_all
    WHERE period_id = p_period_id;

       cn_message_pkg.DEBUG ('Year: '|| l_year);


          BEGIN

                cn_message_pkg.DEBUG ('Step2: Calculate YTD Quota');

                SELECT NVL(SUM(cspq.target_amount),0)
                  INTO  l_ytd_quota
                  FROM  cn_srp_period_quotas cspq,
                        cn_quotas cq,
                        cn_period_statuses cps
                WHERE cspq.salesrep_id= p_salesrep_id
                    AND cspq.srp_plan_assign_id = p_srp_plan_assign_id
                    AND cspq.period_id = cps.period_id
                    AND cps.period_id <= p_period_id
                    AND cps.period_year = l_year
                    AND cspq.quota_id = cq.quota_id
                    AND cq.attribute1='COMBINED';

                  cn_message_pkg.DEBUG ('Year: '|| l_year ||', YTD Quota: '||l_ytd_quota||' for salesrep_id: '||p_salesrep_id);



             EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                      cn_Message_Pkg.Debug ('Error calculating YTD Quota for salesrep_id '||p_Salesrep_id);
                        RETURN 0 ;
                 WHEN OTHERS THEN
                      cn_message_pkg.DEBUG ('Unexpected error occured ' || SQLERRM);
                        RETURN 0;
            END;

       RETURN (l_ytd_quota);

  EXCEPTION
     WHEN OTHERS THEN
       cn_message_pkg.DEBUG ('Unexpected error occured ' || SQLERRM);
       RETURN 0;

END XXSS_OIC_YTD_QUOTA_FN;
/
