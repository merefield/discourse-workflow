# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStat < ActiveRecord::Base
    self.table_name = 'workflow_stats'
    has_one :workflow
    has_one :workflow_step
    validates :cob_date, presence: true
    validates :workflow_id, presence: true
    validates :workflow_step_id, presence: true
    validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
