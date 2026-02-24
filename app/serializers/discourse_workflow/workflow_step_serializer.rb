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
               :overdue_days,
               :ai_enabled,
               :ai_prompt

    has_many :workflow_step_options,
             serializer: WorkflowStepOptionSerializer,
             embed: :object,
             key: :workflow_step_options
    has_one :category, serializer: WorkflowCategorySerializer, embed: :object

    def category
      object.category
    end
  end
end
