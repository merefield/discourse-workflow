# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStepOption < ActiveRecord::Base
    self.table_name = 'workflow_step_options'
    belongs_to :workflow_step
    belongs_to :workflow_option
  end
end

# == Schema Information
#
# Table name: workflow_step_options
#
#  id                 :bigint           not null, primary key
#  position           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  target_step_id     :bigint
#  workflow_option_id :bigint
#  workflow_step_id   :bigint
#
# Indexes
#
#  index_workflow_step_options_on_workflow_option_id  (workflow_option_id)
#  index_workflow_step_options_on_workflow_step_id    (workflow_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_option_id => workflow_options.id)
#  fk_rails_...  (workflow_step_id => workflow_steps.id)
#
