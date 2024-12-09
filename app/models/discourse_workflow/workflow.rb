# frozen_string_literal: true

module ::DiscourseWorkflow
  class Workflow < ActiveRecord::Base
    self.table_name = 'workflow'

   # validates :post_id, presence: true, uniqueness: true
  end
end