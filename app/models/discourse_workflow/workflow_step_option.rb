# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStepOption < ActiveRecord::Base
    self.table_name = 'workflow_step_options'
    belongs_to :workflow_step
    belongs_to :workflow_option
  end
end