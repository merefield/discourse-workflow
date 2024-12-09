# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStep < ActiveRecord::Base
    self.table_name = 'workflow_step_option'

   # validates :post_id, presence: true, uniqueness: true
  end
end