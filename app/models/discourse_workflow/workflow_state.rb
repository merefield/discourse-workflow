# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowState < ActiveRecord::Base
    self.table_name = 'workflow_states'
    belongs_to :workflow
    belongs_to :workflow_step
  end
end

# == Schema Information
#
# Table name: workflow_states
#
#  id               :bigint           not null, primary key
#  topic_id         :bigint
#  workflow_id      :bigint
#  workflow_step_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_workflow_states_on_topic_id          (topic_id)
#  index_workflow_states_on_workflow_id       (workflow_id)
#  index_workflow_states_on_workflow_step_id  (workflow_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (topic_id => topics.id)
#  fk_rails_...  (workflow_id => workflows.id)
#  fk_rails_...  (workflow_step_id => workflow_steps.id)
#
