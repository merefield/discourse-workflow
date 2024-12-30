# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStep < ActiveRecord::Base
    self.table_name = 'workflow_steps'
    belongs_to :workflow
    has_many :workflow_step_option
    has_many :workflow_state

   validates :category_id, presence: true
   validates :name, presence: true
  end
end