DROP PACKAGE APPS.SSPWSMAT_PKG;

CREATE OR REPLACE PACKAGE APPS.SSPWSMAT_PKG AUTHID CURRENT_USER as
/* $Header: sspwsmat.pkh 120.1.12010000.2 2010/11/17 10:05:42 npannamp ship $ */

 procedure calculate_smp_form_fields
 (
  p_due_date            in date,
  p_ewc                 in out NOCOPY date,
  p_earliest_mpp_start  in out NOCOPY date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

  procedure calculate_sap_form_fields
 (
  p_due_date            in date,
  p_matching_date       in date,
  p_earliest_mpp_start  in out NOCOPY date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

  procedure calculate_pab_form_fields
 (
  p_due_date            in date,
  p_ewc                 in out NOCOPY date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

  procedure calculate_pad_form_fields
 (
  p_matching_date       in date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

  procedure calculate_apab_form_fields
 (
  p_due_date            in date,
  p_ewc                 in out NOCOPY date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

  procedure calculate_apad_form_fields
 (
  p_matching_date       in date,
  p_qw                  in out NOCOPY date,
  p_cont_emp_start_date in out NOCOPY date
 );

 procedure get_latest_absence_date
 (
  p_maternity_id           in     number,
  p_absence_attendance_id  in out NOCOPY number,
  p_abs_end_date           in out NOCOPY date,
  p_rec_found              in out NOCOPY boolean
 );

procedure upd_abse_end_date
 (
  p_maternity_id in number,
  p_absence_attendance_id in number,
  p_absence_end_date in date
 );

END SSPWSMAT_PKG;

/


GRANT EXECUTE ON APPS.SSPWSMAT_PKG TO INTG_NONHR_NONXX_RO;
