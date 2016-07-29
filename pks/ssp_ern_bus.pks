DROP PACKAGE APPS.SSP_ERN_BUS;

CREATE OR REPLACE PACKAGE APPS.ssp_ern_bus AUTHID CURRENT_USER as
/* $Header: spernrhi.pkh 120.0.12000000.1 2007/01/17 14:14:38 appldev noship $ */
--
Procedure check_person_id (p_person_id      in number,
			   p_effective_date in date);
--
Procedure check_effective_date (p_person_id      in number,
				p_effective_date in date);
--
PROCEDURE CALCULATE_AVERAGE_EARNINGS (
	p_person_id                  in number,
	p_effective_date             in date,
	p_average_earnings_amount    out nocopy number,
	p_user_entered		     in	varchar2 default 'Y',
	p_absence_category	     in varchar2-- DFoster 1304683
	) ;
--
--
-- ----------------------------------------------------------------------------
-- |---------------------------< number_of_periods >---------------------------|
-- ----------------------------------------------------------------------------
--
function number_of_periods
return number;
--
-- ----------------------------------------------------------------------------
-- |---------------------------< insert_validate >----------------------------|
-- ----------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------
Procedure insert_validate(p_rec in out nocopy ssp_ern_shd.g_rec_type);
--
-- ----------------------------------------------------------------------------
-- |---------------------------< update_validate >----------------------------|
-- ----------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------
Procedure update_validate(p_rec in out nocopy ssp_ern_shd.g_rec_type);
--
-- ----------------------------------------------------------------------------
-- |---------------------------< delete_validate >----------------------------|
-- ----------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------
Procedure delete_validate(p_rec in ssp_ern_shd.g_rec_type);
--
end ssp_ern_bus;

/


GRANT EXECUTE ON APPS.SSP_ERN_BUS TO INTG_NONHR_NONXX_RO;
