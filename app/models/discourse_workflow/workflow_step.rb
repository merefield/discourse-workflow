# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowStep < ActiveRecord::Base
    self.table_name = "workflow_steps"
    belongs_to :workflow
    belongs_to :category
    has_many :workflow_step_options
    has_many :workflow_states

    validates :category_id, presence: true
    validates :name, presence: true
    validates :overdue_days,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
              }
  end
end

# == Schema Information
#
# Table name: workflow_steps
#
#  id           :bigint           not null, primary key
#  ai_enabled   :boolean          default(FALSE)
#  ai_prompt    :text
#  description  :text
#  name         :string
#  overdue_days :integer
#  position     :integer
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  category_id  :bigint
#  workflow_id  :bigint
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
