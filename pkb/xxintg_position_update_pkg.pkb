DROP PACKAGE BODY APPS.XXINTG_POSITION_UPDATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXINTG_POSITION_UPDATE_PKG
AS
   PROCEDURE update_positions (
      x_position_id              IN   NUMBER
--,x_position_definition_id IN NUMBER
--,x_name IN VARCHAR2
   ,
      x_availability_status_id   IN   NUMBER,
      x_entry_grade_rule_id      IN   NUMBER,
      x_location_id              IN   NUMBER,
      x_pay_freq_payroll_id      IN   NUMBER,
      x_entry_grade_id           IN   NUMBER,
      x_supervisor_position_id   IN   NUMBER,
      x_frequency                IN   VARCHAR2,
      x_fte                      IN   NUMBER,
      x_max_persons              IN   NUMBER,
      x_position_type            IN   VARCHAR2,
      x_working_hours            IN   NUMBER,
      x_pay_basis_id             IN   NUMBER,
      x_supervisor_id            IN   NUMBER,
      x_attribute5               IN   VARCHAR2,
      x_attribute6               IN   VARCHAR2,
      x_attribute7               IN   VARCHAR2,
      x_attribute8               IN   VARCHAR2,
      x_attribute9               IN   VARCHAR2
--,x_object_version_number IN NUMBER
   ,
      x_effective_date           IN   DATE,
      x_datetrack_mode           IN   VARCHAR2
   )
   IS
      l_effective_start_date           DATE;
      l_effective_end_date             DATE;
      l_valid_grades_changed_warning   BOOLEAN;
      l_name                           VARCHAR2 (200);
      l_object_version_number          NUMBER;
      l_position_definition_id         NUMBER;

      CURSOR csr_pos_details
      IS
         SELECT NAME, position_definition_id, object_version_number
           FROM hr_all_positions_f
          WHERE TRUNC (SYSDATE) BETWEEN effective_start_date
                                    AND effective_end_date
            AND position_id = x_position_id;
   BEGIN
      OPEN csr_pos_details;

      FETCH csr_pos_details
       INTO l_name, l_position_definition_id, l_object_version_number;

      CLOSE csr_pos_details;

      BEGIN
         hr_position_api.update_position
            (p_position_id                       => x_position_id,
             p_effective_start_date              => l_effective_start_date,
             p_effective_end_date                => l_effective_end_date,
             p_position_definition_id            => l_position_definition_id,
             p_valid_grades_changed_warning      => l_valid_grades_changed_warning,
             p_name                              => l_name,
             p_availability_status_id            => x_availability_status_id,
             p_entry_grade_rule_id               => x_entry_grade_rule_id
--  ,p_business_group_id              in  number    default hr_api.g_number
  --  ,p_job_id                         in  number    default hr_api.g_number
         ,
             p_location_id                       => x_location_id
--  ,p_organization_id                in  number    default hr_api.g_number
         ,
             p_pay_freq_payroll_id               => x_pay_freq_payroll_id,
             p_entry_grade_id                    => x_entry_grade_id,
             p_supervisor_position_id            => x_supervisor_position_id,
             p_frequency                         => x_frequency,
             p_fte                               => x_fte,
             p_max_persons                       => x_max_persons,
             p_position_type                     => x_position_type,
             p_working_hours                     => x_working_hours,
             p_pay_basis_id                      => x_pay_basis_id
                                                                  --,p_copied_to_old_table_flag       in  varchar2    default hr_api.g_varchar2
         ,
             p_supervisor_id                     => x_supervisor_id,
             p_attribute5                        => x_attribute5,
             p_attribute6                        => x_attribute6,
             p_attribute7                        => x_attribute7,
             p_attribute8                        => x_attribute8,
             p_attribute9                        => x_attribute9,
             p_object_version_number             => l_object_version_number,
             p_effective_date                    => x_effective_date,
             p_datetrack_mode                    => x_datetrack_mode
            );
         COMMIT;
      END;
   END update_positions;
END xxintg_position_update_pkg;
/
