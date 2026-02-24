# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowCategorySerializer < ApplicationSerializer
    attributes :id, :name, :slug, :color, :text_color, :parent_category_id
  end
end
