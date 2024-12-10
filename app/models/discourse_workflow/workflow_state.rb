# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowState < ActiveRecord::Base
    self.table_name = 'workflow_states'
    belongs_to :workflow
    belongs_to :workflow_step

     # validates :post_id, presence: true, uniqueness: true
  end
end