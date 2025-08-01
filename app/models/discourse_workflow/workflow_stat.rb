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

# == Schema Information
#
# Table name: workflow_stats
#
#  id               :bigint           not null, primary key
#  cob_date         :datetime
#  count            :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  workflow_id      :bigint
#  workflow_step_id :bigint
#
# Indexes
#
#  index_workflow_stats_on_workflow_id       (workflow_id)
#  index_workflow_stats_on_workflow_step_id  (workflow_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#  fk_rails_...  (workflow_step_id => workflow_steps.id)
#
