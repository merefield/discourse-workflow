# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowStepSerializer < ApplicationSerializer

    attributes :id,
              :workflow_id,
              :category_id,
              :position,
              :slug,
              :name,
              :description,
              :ai_enabled,
              :ai_prompt

    has_many :workflow_step_option, serializer: WorkflowStepOptionSerializer, embed: :object, key: :workflow_step_options
    has_one :category, serializer: CategorySerializer, embed: :object

    def category
      Category.find_by(id: object.category_id) if object.category_id.present?
    end
  end
end
