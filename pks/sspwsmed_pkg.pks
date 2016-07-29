DROP PACKAGE APPS.SSPWSMED_PKG;

CREATE OR REPLACE PACKAGE APPS.SSPWSMED_PKG AUTHID CURRENT_USER as
 /* $Header: sspwsmed.pkh 115.0 99/07/16 23:04:12 porting ship $ */
 /*
   ******************************************************************
   *                                                                *
   *  Copyright (C) 1993 Oracle Corporation.                        *
   *  All rights reserved.                                          *
   *                                                                *
   *  This material has been provided pursuant to an agreement      *
   *  containing restrictions on its use.  The material is also     *
   *  protected by copyright law.  No part of this material may     *
   *  be copied or distributed, transmitted or transcribed, in      *
   *  any form or by any means, electronic, mechanical, magnetic,   *
   *  manual, or otherwise, or disclosed to third parties without   *
   *  the express written permission of Oracle Corporation,         *
   *  500 Oracle Parkway, Redwood City, CA, 94065.                  *
   *                                                                *
   ******************************************************************


    Name        : sspwsmed_pkg

    Description : This package is the server side agent for SMP/SSP
                  form SSPWSMED

    Change List
    -----------
    Date        Name          Vers    Bug No     Description
    ----        ----          ----    ------     -----------
    22-AUG-1995 ssethi       40.0               Initial Creation
    13-SEP-1995 ssethi                          Added two procedures to
						update the evidence
						status if the current
						one is 'Current'.

  */

 PROCEDURE get_medical_sequence (p_medical_id in out number);

 PROCEDURE check_unique_mat_evidence
	    (p_evidence_source in varchar2,
	     p_evidence_date   in date,
             p_maternity_id    in number,
             p_medical_id      in number);

 PROCEDURE check_unique_abs_evidence
            (p_evidence_source in varchar2,
             p_evidence_date   in date,
             p_absence_attendance_id in number,
             p_medical_id in number);

 PROCEDURE upd_prev_sick_evid (p_absence_attendance_id in number);

 PROCEDURE upd_prev_mat_evid (p_maternity_id in number);

END SSPWSMED_PKG;

/


GRANT EXECUTE ON APPS.SSPWSMED_PKG TO INTG_NONHR_NONXX_RO;
