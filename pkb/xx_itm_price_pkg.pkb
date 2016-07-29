DROP PACKAGE BODY APPS.XX_ITM_PRICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_itm_price_pkg AS

--------------------------------------------------------------------------------------
/*
 Created By    : Deepti Gaur
 Creation Date : 12-FEB-2015
 File Name     : XXINTGITMPRC.pkb
 Description   : This Package calls the Pricing Engine API to calculate
                 the Unit Price,Unit List Price and Effective Untill Date

 Change History:

 Date        Name          Remarks
 ----------- -----------   ---------------------------------------
 10-FEB-2015   IBM Development    Initial development
 */
--------------------------------------------------------------------------------------


PROCEDURE xx_itm_price(p_item_id IN NUMBER,
		       p_org_id  IN NUMBER,
		       p_cust_id IN NUMBER,
                       p_curr_code IN VARCHAR2,
                       P_PRICING_DATE IN VARCHAR2,
                       p_currency OUT VARCHAR2,
                       p_unit_price OUT NUMBER,
                       p_adjusted_Price OUT NUMBER,
                       p_effective_date OUT DATE
                      ) IS

	    -- Variables


	    l_panda_rec_table    oe_oe_pricing_availability.PANDA_REC_TABLE;

	    g_line_id            NUMBER := 2253548;--Dummy Value;It would not have any significane on the Price Calculation.

	    l_index              NUMBER;
	    l_ship_to_org_id     NUMBER;
	    l_invoice_to_org_id  NUMBER;
	    l_price_list_id      NUMBER ;
            l_list_line_id       NUMBER ;
            l_out_unit_price     NUMBER;
            l_out_adjusted_price NUMBER;
            l_count              NUMBER;
            l_out_tot_price      NUMBER;
            l_cust_account_id    NUMBER;
            l_out_line_id        NUMBER;



	    G_req_line_tbl             OE_OE_PRICING_AVAILABILITY.QP_LINE_TBL_TYPE;
	    G_Req_line_attr_tbl        OE_OE_PRICING_AVAILABILITY.QP_LINE_ATTR_TBL_TYPE;
	    G_Req_LINE_DETAIL_attr_tbl OE_OE_PRICING_AVAILABILITY.QP_LINE_DATTR_TBL_TYPE;
	    G_Req_LINE_DETAIL_tbl      OE_OE_PRICING_AVAILABILITY.QP_LINE_DETAIL_TBL_TYPE;
	    G_Req_related_lines_tbl    OE_OE_PRICING_AVAILABILITY.QP_RLTD_LINES_TBL_TYPE;
	    G_Req_qual_tbl             OE_OE_PRICING_AVAILABILITY.QP_QUAL_TBL_TYPE;
	    G_Req_LINE_DETAIL_qual_tbl OE_OE_PRICING_AVAILABILITY.QP_LINE_DQUAL_TBL_TYPE;
	    G_child_detail_type        VARCHAR2(30);


	    l_out_uom             VARCHAR2(30);
	    l_out_currency        VARCHAR2(40);
	    l_curr_code           VARCHAR2(100);
            l_uom                 VARCHAR2(10);
            l_flag                VARCHAR2(10);
            l_list_line_type_code VARCHAR2(100);
            l_modifier_level_code VARCHAR2(100);


	    l_end_date             DATE ;
            l_start_date           DATE;
            l_out_effective_date   DATE ;



	  BEGIN


	    BEGIN
	      mo_global.set_policy_context('S', p_org_id);
	      commit;
	    END;

	    l_out_unit_price := 0;

	    l_panda_rec_table.delete;
	    g_req_line_tbl.delete;
	    g_req_line_attr_tbl.delete;
	    g_req_LINE_DETAIL_attr_tbl.delete;
	    g_req_LINE_DETAIL_tbl.delete;
	    g_req_related_lines_tbl.delete;
	    g_req_qual_tbl.delete;
	    g_req_LINE_DETAIL_qual_tbl.delete;

	    ---- Derivation requird
	    BEGIN
	      SELECT primary_uom_code
		INTO l_uom
		FROM mtl_system_items_b msi
	       WHERE inventory_item_id = p_item_id
		 AND rownum < 2; --- value will be taken from from input

	    EXCEPTION
	      WHEN OTHERS THEN
		 DBMS_OUTPUT.PUT_LINE('Exception while deriving inventory_item_id'||SQLERRM);
		 FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while deriving inventory_item_id '||SQLERRM);
	    END;

	    l_cust_account_id := p_cust_id;

	BEGIN
	SELECT  hcasu.site_use_id
	  INTO l_ship_to_org_id
	  FROM hz_cust_acct_sites_all hcasa,hz_cust_site_uses_all hcasu
	 WHERE cust_account_id = l_cust_account_id
	   AND hcasa.cust_acct_site_id = hcasu.cust_acct_site_id
	   AND hcasu.site_use_code = 'SHIP_TO'
	   AND hcasu.primary_flag = 'Y' ;

	EXCEPTION
	  WHEN OTHERS THEN
	       DBMS_OUTPUT.PUT_LINE('Exception while deriving Ship To'||SQLERRM);
	END;


         BEGIN
	SELECT  hcasu.site_use_id
	  INTO l_invoice_to_org_id
	  FROM hz_cust_acct_sites_all hcasa,hz_cust_site_uses_all hcasu
	 WHERE cust_account_id = l_cust_account_id
	   AND hcasa.cust_acct_site_id = hcasu.cust_acct_site_id
	   AND hcasu.site_use_code = 'BILL_TO'
	   AND hcasu.primary_flag = 'Y' ;
        EXCEPTION
          WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Exception while deriving Bill To'||SQLERRM);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while deriving Bill To'||SQLERRM);
        END;


        BEGIN
	SELECT price_list_id
	  INTO l_price_list_id
	  FROM hz_cust_accounts_all
	 WHERE cust_account_id = l_cust_account_id ;
        EXCEPTION
           WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Exception while deriving Price List'||SQLERRM);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while deriving Price List'||SQLERRM);
           END;


	 l_curr_code := p_curr_code;

	    commit;

	    l_index := 1;
	    l_panda_rec_table(l_index).p_line_id := g_line_id;
	    l_panda_rec_table(l_index).p_inventory_item_id := p_item_id;
	    l_panda_rec_table(l_index).p_qty := 1;
	    l_panda_rec_table(l_index).p_request_date := TRUNC(SYSDATE);
	    l_panda_rec_table(l_index).p_pricing_date := TRUNC(to_date(P_PRICING_DATE,'YYYY/MM/DD HH24:MI:SS'));
	    l_panda_rec_table(l_index).p_uom := l_uom;
	    l_panda_rec_table(l_index).p_customer_id := l_cust_account_id;
	    l_panda_rec_table(l_index).p_currency := l_curr_code;
	    l_panda_rec_table(l_index).p_ship_to_org_id := l_ship_to_org_id ;
	    l_panda_rec_table(l_index).p_invoice_to_org_id := l_invoice_to_org_id ;
	    l_panda_rec_table(l_index).p_price_list_id  := l_price_list_id ;


	    oe_oe_pricing_availability.pass_values_to_backend(l_panda_rec_table);

	    oe_oe_pricing_availability.price_item(out_req_line_tbl             => g_req_line_tbl,
						  out_Req_line_attr_tbl        => g_req_line_attr_tbl,
						  out_Req_LINE_DETAIL_attr_tbl => g_req_line_detail_attr_tbl,
						  out_Req_LINE_DETAIL_tbl      => g_req_line_detail_tbl,
						  out_Req_related_lines_tbl    => g_req_related_lines_tbl,
						  out_Req_qual_tbl             => g_req_qual_tbl,
						  out_Req_LINE_DETAIL_qual_tbl => g_req_line_detail_qual_tbl,
						  out_child_detail_type        => g_child_detail_type);
	    commit;

	    FOR i in g_req_line_tbl.first .. g_req_line_tbl.last loop

	      IF i = 2 THEN
		l_count              := i;
		l_out_uom            := g_req_line_tbl(i).priced_uom_code;
		l_out_currency       := g_req_line_tbl(i).currency_code;
		l_out_unit_price     := g_req_line_tbl(i).unit_price;
		l_out_adjusted_Price := g_req_line_tbl(i).adjusted_unit_price;
		l_out_tot_price      := g_req_line_tbl(i)
				       .adjusted_unit_price * g_req_line_tbl(i)
				       .line_quantity;
		l_out_line_id  := g_req_line_tbl(i).LINE_ID ;
	     END IF;


                  p_unit_price := l_out_unit_price ;
                  p_adjusted_Price := l_out_adjusted_Price ;
                  p_currency   := l_out_currency ;

	    DBMS_OUTPUT.PUT_LINE('l_count = '||l_count);
	    DBMS_OUTPUT.PUT_LINE('l_out_uom = '||l_out_uom);
	    DBMS_OUTPUT.PUT_LINE('l_out_currency = '||l_out_currency);
	    DBMS_OUTPUT.PUT_LINE('l_out_unit_price = '||l_out_unit_price);
	    DBMS_OUTPUT.PUT_LINE('l_out_adjusted_Price = '||l_out_adjusted_Price);
	    DBMS_OUTPUT.PUT_LINE('l_out_line_id = '||l_out_line_id);



	    END LOOP;

       g_effective_until := NULL ;

      FOR j in g_req_line_detail_tbl.first .. g_req_line_detail_tbl.last loop


      DBMS_OUTPUT.PUT_LINE('j = '||j);
      DBMS_OUTPUT.PUT_LINE('g_req_line_detail_tbl(j).list_line_id = '||g_req_line_detail_tbl(j).list_line_id);

      l_list_line_id :=  g_req_line_detail_tbl(j).list_line_id;
      l_flag := g_req_line_detail_tbl(j).AUTOMATIC_FLAG ;

      oe_oe_pricing_availability.Get_list_line_details(
							in_list_line_id => l_list_line_id
							,out_end_date => l_end_date
							,out_start_date => l_start_date
							,out_list_line_type_Code =>l_list_line_type_code
							,out_modifier_level_code =>l_modifier_level_code
						      );

      DBMS_OUTPUT.PUT_LINE('l_end_date = '||l_end_date);
      DBMS_OUTPUT.PUT_LINE('l_flag = '||l_flag);

      IF l_flag = 'N' THEN

      l_end_date := NULL;

      END IF;

      find_the_best_date(l_end_date,l_out_effective_date);

                    p_effective_date := l_out_effective_date;

      DBMS_OUTPUT.PUT_LINE('p_effective_date = '||p_effective_date);

      END LOOP;

EXCEPTION
   WHEN OTHERS THEN
	      DBMS_OUTPUT.PUT_LINE('Exception in XX_ITM_PRICE PROC '||SQLERRM);
	      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in XX_ITM_PRICE PROC '||SQLERRM);

END xx_itm_price;

-------------------------------------------------
-------------------------------------------------

PROCEDURE find_the_best_date(in_compare_date in date, effective_until out date) IS

----------------------------------------------------------------------
-- Created By      : Deepti Gaur
-- Creation Date   : 10-FEB-2015
-- Description   :  Procedure to return the earliest date
-- Parameters Description
---------------------------------------------------------------------

BEGIN


    IF in_compare_date is not null then

       IF g_effective_until is null then
        g_effective_until := in_compare_date;

         effective_until :=  g_effective_until;

       ELSE


          IF to_date(to_char(in_compare_date,'DD-MON-RRRR'),'DD-MON-RRRR') <=
           to_date(to_char(g_effective_until,'DD-MON-RRRR'),'DD-MON-RRRR') then



          g_effective_until := in_compare_date;

          effective_until :=  g_effective_until;

          ELSE
             effective_until :=  g_effective_until;
          END IF;

       END IF;
  ELSE
      effective_until :=  g_effective_until;

  END IF;  -- in in_compare date is null


EXCEPTION
   WHEN OTHERS THEN
	      DBMS_OUTPUT.PUT_LINE('Exception in FIND_THE_BEST_DATE PROC '||SQLERRM);
	      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in FIND_THE_BEST_DATE PROC '||SQLERRM);


END find_the_best_date;



END ;
/
