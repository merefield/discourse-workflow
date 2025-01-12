# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowAuditLog < ActiveRecord::Base
    self.table_name = 'workflow_audit_logs'
  end
end

# == Schema Information
#
# Table name: workflow_audit_logs
#
#  id                     :bigint           not null, primary key
#  user_id                :bigint
#  username               :string
#  topic_id               :bigint
#  topic_title            :string
#  workflow_id            :bigint
#  workflow_name          :string
#  starting_step_id       :bigint
#  starting_step_name     :string
#  ending_step_id         :bigint
#  ending_step_name       :string
#  starting_category_id   :bigint
#  starting_category_name :string
#  ending_category_id     :bigint
#  ending_category_name   :string
#  starting_position      :integer
#  ending_position        :integer
#  step_option_id         :bigint
#  step_option_name       :string
#  step_option_slug       :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
