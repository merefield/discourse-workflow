# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStepOption < ActiveRecord::Base
    self.table_name = 'workflow_step_options'
    belongs_to :workflow_step

   # validates :post_id, presence: true, uniqueness: true
  end
end