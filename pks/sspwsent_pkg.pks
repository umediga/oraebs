DROP PACKAGE APPS.SSPWSENT_PKG;

CREATE OR REPLACE PACKAGE APPS.SSPWSENT_PKG AUTHID CURRENT_USER as
/* $Header: sspwsent.pkh 120.1 2005/06/15 03:20:37 tukumar noship $ */

 PROCEDURE fetch_maternity_details ( P_MATERNITY_ID in number,
				     P_SMP_DUE_DATE out NOCOPY date,
				     P_PERSON_ID out NOCOPY number,
				     P_MATCHING_DATE out NOCOPY DATE);

 PROCEDURE fetch_absence_details ( p_absence_id in number,
				   p_ABSENCE_CATEGORY out NOCOPY varchar2,
				   P_PERSON_ID out NOCOPY number,
				   p_SICKNESS_START_DATE out NOCOPY date,
				   p_SICKNESS_END_DATE out NOCOPY  date,
                                   P_MATERNITY_ID out NOCOPY number,
				   P_SMP_DUE_DATE out NOCOPY date,
				   P_LINKED_ABSENCE_ID out NOCOPY number) ;


 FUNCTION fetch_element_type (p_effective_date in date,
			      p_absence_category varchar2)  return number;


END SSPWSENT_PKG;

/


GRANT EXECUTE ON APPS.SSPWSENT_PKG TO INTG_NONHR_NONXX_RO;
