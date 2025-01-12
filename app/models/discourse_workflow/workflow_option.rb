# frozen_string_literal: true

module ::DiscourseWorkflow
  class WorkflowOption < ActiveRecord::Base
    self.table_name = 'workflow_options'
  end
end

# == Schema Information
#
# Table name: workflow_options
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
