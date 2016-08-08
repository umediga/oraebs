DROP FUNCTION APPS.XXSS_OIC_CATCHUP_FN;

CREATE OR REPLACE FUNCTION APPS.XXSS_OIC_CATCHUP_FN
					(p_salesrep_id 		      IN NUMBER,
					 p_period_id 		        IN NUMBER,
					 p_srp_plan_assign_id 	IN NUMBER,
					 p_quota_id     	      IN NUMBER)
/*****************************************************************************************
*
*   FUNCTION
*    XXSS_OIC_CATCHUP_FN
*
*   DESCRIPTION
*   The function will calculate amount required for Catch-up in OIC.
*
*   PARAMETERS
*   ==========
*   NAME                            TYPE           DESCRIPTION
*   -----------------               --------       -------------------------------------------------
*    p_sales_rep_id                 IN             The Oracle internal ID of the sales rep.
*    p_srp_plan_assign_id           IN             The Oracle internal ID for plan assignment.
*    p_quota_id                     IN             The Oracle internal ID for the quota.
*    p_period_id                    IN             The Oracle internal ID for the period.
*
*     RETURN VALUE
*     Returns the amount required for Catch-up.
*
*   CALLED BY
*     The function is called by OIC to calculate Catch-up Plan.
*
*
*
*   HISTORY
*   =======
*
* VERSION    	DATE          	 AUTHOR(S)  		DESCRIPTION
* ------- 	------------- 	----------------	------------------------------
* 1.00    	15-MAR-2016       Dik Ahuja        	Creation
**********************************************************************************************/
 RETURN NUMBER IS



  l_year                    NUMBER;
  l_quarter                 NUMBER;
  x_ytd_bonus               NUMBER :=0;
  x_qtd_bonus               NUMBER :=0;
  x_prior_ytd               NUMBER :=0;
  x_catchup          	      NUMBER :=0;



BEGIN


  SELECT period_year, quarter_num
   INTO l_year, l_quarter
  FROM cn_period_statuses
  WHERE period_id = p_period_id;

  cn_message_pkg.DEBUG ('Year: '|| l_year||', Quarter: '||l_quarter);


        BEGIN

          SELECT NVL(SUM(cspq.commission_payed_ptd),0)
            INTO x_qtd_bonus
          FROM  cn_srp_period_quotas cspq,
            	cn_quotas cq,
            	cn_period_statuses cps
          WHERE cspq.salesrep_id = p_salesrep_id
            AND cspq.srp_plan_assign_id = p_srp_plan_assign_id
            AND cspq.period_id = cps.period_id
            AND cps.period_year = l_year
            AND cps.quarter_num <= l_quarter
            AND cps.period_id <= p_period_id
            AND cspq.quota_id = cq.quota_id
            AND cq.attribute1 = 'QTR BONUS';

            cn_message_pkg.DEBUG ('Period: '|| p_period_id ||', Total QTD Bonus: '|| x_qtd_bonus);


       BEGIN

          SELECT NVL(SUM(cspq.commission_payed_ptd),0)
            INTO x_prior_ytd
          FROM  cn_srp_period_quotas cspq,
            	cn_quotas cq,
            	cn_period_statuses cps
          WHERE cspq.salesrep_id = p_salesrep_id
            AND cspq.srp_plan_assign_id = p_srp_plan_assign_id
            AND cspq.period_id = cps.period_id
            AND cps.period_year = l_year
            AND cps.quarter_num < l_quarter
            AND cps.period_id < p_period_id
            AND cspq.quota_id = cq.quota_id
            AND cq.attribute1 = 'YTD BONUS';

            cn_message_pkg.DEBUG ('Period: '|| p_period_id ||', Prior YTD: '|| x_prior_ytd);

              x_catchup := x_qtd_bonus + x_prior_ytd;

              cn_message_pkg.DEBUG ('Prior Bonus: '|| x_catchup);

              RETURN (x_catchup);

         EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     cn_message_pkg.DEBUG ('Prior Payout does not exist in OIC');
                     RETURN 0;
                  WHEN OTHERS THEN
                     cn_message_pkg.DEBUG ( 'Unexpected error occurred ' || SQLERRM );
                     RETURN 0;
          END;

          EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     cn_message_pkg.DEBUG ('Quarterly Bonus does not exist in OIC');
                     RETURN 0;
                  WHEN OTHERS THEN
                     cn_message_pkg.DEBUG ( 'Unexpected error occurred ' || SQLERRM );
                     RETURN 0;
          END;




 EXCEPTION
   WHEN OTHERS THEN
      cn_message_pkg.DEBUG ('Unexpected error occurred ' || SQLERRM);
      RETURN 0;
END XXSS_OIC_CATCHUP_FN;
/
