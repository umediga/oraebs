DROP PACKAGE APPS.SSP_MAT_INS;

CREATE OR REPLACE PACKAGE APPS.ssp_mat_ins AUTHID CURRENT_USER as
/* $Header: spmatrhi.pkh 120.1.12010000.3 2010/11/27 16:32:35 npannamp ship $ */
--
-- ----------------------------------------------------------------------------
-- |---------------------------------< ins >----------------------------------|
-- ----------------------------------------------------------------------------
-- {Start Of Comments}
--
-- Description:
--   This procedure is the record interface for the insert process
--   for the specified entity. The role of this process is to insert a fully
--   validated row, into the HR schema passing back to  the calling process,
--   any system generated values (e.g. primary and object version number
--   attributes). This process is the main backbone of the ins
--   process. The processing of this procedure is as follows:
--   1) If the p_validate parameter has been set to true then a savepoint is
--      issued.
--   2) The controlling validation process insert_validate is then executed
--      which will execute all private and public validation business rule
--      processes.
--   3) The pre_insert business process is then executed which enables any
--      logic to be processed before the insert dml process is executed.
--   4) The insert_dml process will physical perform the insert dml into the
--      specified entity.
--   5) The post_insert business process is then executed which enables any
--      logic to be processed after the insert dml process.
--   6) If the p_validate parameter has been set to true an exception is
--      raised which is handled and processed by performing a rollback to the
--      savepoint which was issued at the beginning of the Ins process.
--
-- Pre Conditions:
--   The main parameters to the this process have to be in the record
--   format.
--
-- In Parameters:
--   p_validate
--     Determines if the process is to be validated. Setting this
--     boolean value to true will invoke the process to be validated. The
--     default is false. The validation is controlled by a savepoint and
--     rollback mechanism. The savepoint is issued at the beginning of the
--     process and is rollbacked at the end of the process
--     when all the processing has been completed. The rollback is controlled
--     by raising and handling the exception hr_api.validate_enabled. We use
--     the exception because, by raising the exception with the business
--     process, we can exit successfully without having any of the 'OUT'
--     parameters being set.
--
-- Post Success:
--   A fully validated row will be inserted into the specified entity
--   without being committed. If the p_validate parameter has been set to true
--   then all the work will be rolled back.
--
-- Post Failure:
--   If an error has occurred, an error message will be supplied with the work
--   rolled back.
--
-- Developer Implementation Notes:
--   None.
--
-- Access Status:
--   Internal Development Use Only.
--
-- {End Of Comments}
-- ----------------------------------------------------------------------------
Procedure ins
  (
  p_rec        in out nocopy ssp_mat_shd.g_rec_type,
  p_validate   in     boolean default false
  );
--
-- ----------------------------------------------------------------------------
-- |---------------------------------< ins >----------------------------------|
-- ----------------------------------------------------------------------------
-- {Start Of Comments}
--
-- Description:
--   This procedure is the attribute interface for the insert
--   process for the specified entity and is the outermost layer. The role
--   of this process is to insert a fully validated row into the HR schema
--   passing back to the calling process, any system generated values
--   (e.g. object version number attributes).The processing of this
--   procedure is as follows:
--   1) The attributes are converted into a local record structure by
--      calling the convert_args function.
--   2) After the conversion has taken place, the corresponding record ins
--      interface process is executed.
--   3) OUT parameters are then set to their corresponding record attributes.
--
-- Pre Conditions:
--
-- In Parameters:
--   p_validate
--     Determines if the process is to be validated. Setting this
--     Boolean value to true will invoke the process to be validated.
--     The default is false.
--
-- Post Success:
--   A fully validated row will be inserted for the specified entity
--   without being committed (or rollbacked depending on the p_validate
--   status).
--
-- Post Failure:
--   If an error has occurred, an error message will be supplied with the work
--   rolled back.
--
-- Developer Implementation Notes:
--   None.
--
-- Access Status:
--   Internal Development Use Only.
--
-- {End Of Comments}
-- ----------------------------------------------------------------------------
Procedure ins
  (
  p_maternity_id                 out nocopy number,
  p_object_version_number        out nocopy number,
  p_due_date                     in date,
  p_person_id                    in number,
  p_start_date_SMA in date	default null,
  p_notification_of_birth_date   in date	default null,
  p_unfit_for_scheduled_return   in varchar2	default 'N',
  p_stated_return_date           in date	default null,
  p_intend_to_return_flag        in varchar2	default 'Y',
  p_start_date_with_new_employer in date	default null,
  p_smp_must_be_paid_by_date     in date	default null,
  p_pay_smp_as_lump_sum          in varchar2	default 'N',
  p_live_birth_flag              in varchar2	default 'Y',
  p_actual_birth_date            in date	default null,
  p_mpp_start_date               in date	default null,
  p_attribute_category           in varchar2	default null,
  p_attribute1                   in varchar2	default null,
  p_attribute2                   in varchar2	default null,
  p_attribute3                   in varchar2	default null,
  p_attribute4                   in varchar2	default null,
  p_attribute5                   in varchar2	default null,
  p_attribute6                   in varchar2	default null,
  p_attribute7                   in varchar2	default null,
  p_attribute8                   in varchar2	default null,
  p_attribute9                   in varchar2	default null,
  p_attribute10                  in varchar2	default null,
  p_attribute11                  in varchar2	default null,
  p_attribute12                  in varchar2	default null,
  p_attribute13                  in varchar2	default null,
  p_attribute14                  in varchar2	default null,
  p_attribute15                  in varchar2	default null,
  p_attribute16                  in varchar2	default null,
  p_attribute17                  in varchar2	default null,
  p_attribute18                  in varchar2	default null,
  p_attribute19                  in varchar2	default null,
  p_attribute20                  in varchar2	default null,
  p_LEAVE_TYPE                   in VARCHAR2 default 'MA',
  p_MATCHING_DATE                in DATE default null,
  p_PLACEMENT_DATE               in DATE default null,
  p_DISRUPTED_PLACEMENT_DATE     in DATE default null,
  p_validate                     in boolean	default false,
  p_mat_information_category     in varchar2    default null,
  p_mat_information1             in varchar2    default null,
  p_mat_information2             in varchar2    default null,
  p_mat_information3             in varchar2    default null,
  p_mat_information4             in varchar2    default null,
  p_mat_information5             in varchar2    default null,
  p_mat_information6             in varchar2    default null,
  p_mat_information7             in varchar2    default null,
  p_mat_information8             in varchar2    default null,
  p_mat_information9             in varchar2    default null,
  p_mat_information10            in varchar2    default null,
  p_mat_information11            in varchar2    default null,
  p_mat_information12            in varchar2    default null,
  p_mat_information13            in varchar2    default null,
  p_mat_information14            in varchar2    default null,
  p_mat_information15            in varchar2    default null,
  p_mat_information16            in varchar2    default null,
  p_mat_information17            in varchar2    default null,
  p_mat_information18            in varchar2    default null,
  p_mat_information19            in varchar2    default null,
  p_mat_information20            in varchar2    default null,
  p_mat_information21            in varchar2    default null,
  p_mat_information22            in varchar2    default null,
  p_mat_information23            in varchar2    default null,
  p_mat_information24            in varchar2    default null,
  p_mat_information25            in varchar2    default null,
  p_mat_information26            in varchar2    default null,
  p_mat_information27            in varchar2    default null,
  p_mat_information28            in varchar2    default null,
  p_mat_information29            in varchar2    default null,
  p_mat_information30            in varchar2    default null,
  p_partner_stat_pay_start_date  in date default null,
  p_partner_return_to_work 	 in date default null,
  p_partner_death_date 		 in date default null
  );
--
end ssp_mat_ins;

/


GRANT EXECUTE ON APPS.SSP_MAT_INS TO INTG_NONHR_NONXX_RO;
