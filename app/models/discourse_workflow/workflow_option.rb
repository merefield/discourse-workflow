# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowOption < ActiveRecord::Base
    self.table_name = 'workflow_options'

    belongs_to :workflow_step_option
  end
end