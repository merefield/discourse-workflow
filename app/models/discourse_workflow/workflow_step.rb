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

# == Schema Information
#
# Table name: workflow_steps
#
#  id          :bigint           not null, primary key
#  workflow_id :bigint
#  category_id :bigint
#  position    :integer
#  slug        :string
#  name        :string
#  description :text
#  ai_enabled  :boolean          default(FALSE)
#  ai_prompt   :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_workflow_steps_on_category_id  (category_id)
#  index_workflow_steps_on_workflow_id  (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (workflow_id => workflows.id)
#
