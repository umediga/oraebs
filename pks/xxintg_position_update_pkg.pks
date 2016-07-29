DROP PACKAGE APPS.XXINTG_POSITION_UPDATE_PKG;

CREATE OR REPLACE PACKAGE APPS.xxintg_position_update_pkg
as
procedure update_positions(x_position_id IN NUMBER
--,x_position_definition_id IN NUMBER
--,x_name IN VARCHAR2
,x_availability_status_id IN NUMBER
,x_entry_grade_rule_id IN NUMBER
,x_location_id IN NUMBER
,x_pay_freq_payroll_id IN NUMBER
,x_entry_grade_id IN NUMBER
,x_supervisor_position_id IN NUMBER
,x_frequency IN VARCHAR2
,x_fte  IN NUMBER
,x_max_persons IN NUMBER
,x_position_type IN VARCHAR2
,x_working_hours IN NUMBER
,x_pay_basis_id IN NUMBER
,x_supervisor_id IN NUMBER
,x_attribute5 IN VARCHAR2
,x_attribute6 IN VARCHAR2
,x_attribute7 IN VARCHAR2
,x_attribute8 IN VARCHAR2
,x_attribute9 IN VARCHAR2
--,x_object_version_number IN NUMBER
,x_effective_date IN DATE
,x_datetrack_mode IN VARCHAR2
);
end xxintg_position_update_pkg;
/
