# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowState < ActiveRecord::Base
    self.table_name = 'workflow_states'
    belongs_to :workflow
    belongs_to :workflow_step
  end
end