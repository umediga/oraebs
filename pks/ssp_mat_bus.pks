DROP PACKAGE APPS.SSP_MAT_BUS;

CREATE OR REPLACE PACKAGE APPS.ssp_mat_bus AUTHID CURRENT_USER as
/* $Header: spmatrhi.pkh 120.1.12010000.3 2010/11/27 16:32:35 npannamp ship $ */
--
Procedure validate_female_sex (p_person_id in number);
--
Procedure unique_person_due_date (p_due_date in date,
				p_person_id in number,
                                p_leave_type in varchar2,
				p_maternity_id in number);
--
Procedure check_actual_birth (p_actual_birth_date in date) ;
--
Procedure check_live_birth (p_live_birth_flag in out nocopy varchar2,
				p_actual_birth_date in date);
--
Procedure check_date_notified (p_notification_of_birth_date in date,
				p_actual_birth_date in date);
--
Procedure check_stated_ret_date (p_stated_return_date in date,
				p_intend_to_return in varchar2,
				p_mpp_start_date in date,
				p_earliest_mpp_start in date);
--
Procedure check_forward_MPP_date (p_start_date_mat_allow in date,
				p_mpp_start_date in out nocopy date);
--
Procedure check_MPP_start_date (p_mpp_start_date in out nocopy date,
				p_earliest_mpp_start_date in date,
				p_actual_birth_date in date);
--
Procedure check_MPP_start_date_2 (p_mpp_start_date in date,
                                  p_person_id in number,
                                  p_ewc in date,
			     	  p_earliest_mpp_start_date in date,
                                  p_due_date in date,
                                  p_prev_mpp_start_date in date,
				  p_actual_birth_date in date);
--
FUNCTION  late_evidence (p_maternity_id  in number,
			p_evidence_rcvd in date,
			p_effective_date in date,
			p_element_name in varchar2) return boolean;
--
PROCEDURE evd_before_ewc_due_date_change
                       (p_qualifying_week in date,
			p_ewc             in date,
			p_maternity_id    in number);
--
PROCEDURE evd_before_ewc (p_ewc          in date,
			p_evidence_date  in date,
			p_effective_date in date,
			p_element_name   in varchar2);
--
PROCEDURE default_mpp_date(p_actual_birth_date in date,
			p_mpp_start_date in out nocopy date);
--
PROCEDURE default_date_notification(p_actual_birth_date in date,
                        p_notif_of_birth_date in out nocopy date);

PROCEDURE default_date_notification(p_actual_birth_date in date,
                                    p_effective_date    in date,
			p_notif_of_birth_date in out nocopy date);

PROCEDURE CHECK_CHILD_EXPECTED_DATE(p_due_date in date,
            p_matching_date in date);
--
PROCEDURE CHECK_APP_START_DATE(p_mpp_start_date in date,
            p_placement_date in date,
            p_due_date in date);
--
PROCEDURE CHECK_PPP_START_DATE(p_ppp_start_date in date,
            p_birth_date in date,
            p_ewc in date,
            p_due_date in date);
--
PROCEDURE CHECK_PPPA_START_DATE(p_ppp_start_date in date,
            p_placement_date in date,
            p_due_date in date);
--
PROCEDURE CHECK_ASPP_START_DATE(p_aspp_start_date in date,
            p_birth_date in date,
            p_partner_mpp_start in date,
            p_partner_return_date in date,
            p_mother_death_date in date);
--
PROCEDURE CHECK_ASPPA_START_DATE(p_aspp_start_date in date,
            p_placement_date in date,
            p_partner_app_start in date,
            p_partner_return_date in date,
            p_mother_death_date in date);
--
PROCEDURE CHECK_PLACEMENT_DATE( p_placement_date in date,
            P_MATCHING_DATE IN DATE);
--
PROCEDURE CHECK_DISRUPTED_PLACEMENT_DATE (p_disrupted_placement_date in date,
            p_mpp_start_date in date);
--
Procedure check_adopt_child_birth_dt(p_actual_birth_date in date,
            p_due_date in date);
--
PROCEDURE CHECK_ASPP_PARTNER_DATES( p_partner_return in date,
            p_partner_death IN DATE, p_partner_mpp_start in date);
--
-- ----------------------------------------------------------------------------
-- |---------------------------< insert_validate >----------------------------|
-- ----------------------------------------------------------------------------
-- {Start Of Comments}
--
-- Description:
--   This procedure controls the execution of all insert business rules
--   validation.
--
-- Pre Conditions:
--   This private procedure is called from ins procedure.
--
-- In Parameters:
--   A Pl/Sql record structre.
--
-- Post Success:
--   Processing continues.
--
-- Post Failure:
--   If a business rules fails the error will not be handled by this procedure
--   unless explicity coded.
--
-- Developer Implementation Notes:
--   For insert, your business rules should be executed from this procedure and
--   should ideally (unless really necessary) just be straight procedure or
--   function calls. Try and avoid using conditional branching logic.
--
-- Access Status:
--   Internal Table Handler Use Only.
--
-- {End Of Comments}
-- ----------------------------------------------------------------------------
Procedure insert_validate(p_rec in out nocopy ssp_mat_shd.g_rec_type);
--
-- ----------------------------------------------------------------------------
-- |---------------------------< update_validate >----------------------------|
-- ----------------------------------------------------------------------------
-- {Start Of Comments}
--
-- Description:
--   This procedure controls the execution of all update business rules
--   validation.
--
-- Pre Conditions:
--   This private procedure is called from upd procedure.
--
-- In Parameters:
--   A Pl/Sql record structre.
--
-- Post Success:
--   Processing continues.
--
-- Post Failure:
--   If a business rules fails the error will not be handled by this procedure
--   unless explicity coded.
--
-- Developer Implementation Notes:
--   For update, your business rules should be executed from this procedure and
--   should ideally (unless really necessary) just be straight procedure or
--   function calls. Try and avoid using conditional branching logic.
--
-- Access Status:
--   Internal Table Handler Use Only.
--
-- {End Of Comments}
-- ----------------------------------------------------------------------------
Procedure update_validate(p_rec in out nocopy ssp_mat_shd.g_rec_type);
--
-- ----------------------------------------------------------------------------
-- |---------------------------< delete_validate >----------------------------|
-- ----------------------------------------------------------------------------
-- {Start Of Comments}
--
-- Description:
--   This procedure controls the execution of all delete business rules
--   validation.
--
-- Pre Conditions:
--   This private procedure is called from del procedure.
--
-- In Parameters:
--   A Pl/Sql record structre.
--
-- Post Success:
--   Processing continues.
--
-- Post Failure:
--   If a business rules fails the error will not be handled by this procedure
--   unless explicity coded.
--
-- Developer Implementation Notes:
--   For delete, your business rules should be executed from this procedure and
--   should ideally (unless really necessary) just be straight procedure or
--   function calls. Try and avoid using conditional branching logic.
--
-- Access Status:
--   Internal Table Handler Use Only.
--
-- {End Of Comments}
-- ----------------------------------------------------------------------------
Procedure delete_validate(p_rec in ssp_mat_shd.g_rec_type);
--
end ssp_mat_bus;

/


GRANT EXECUTE ON APPS.SSP_MAT_BUS TO INTG_NONHR_NONXX_RO;
