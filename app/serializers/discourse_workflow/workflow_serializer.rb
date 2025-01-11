# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowSerializer < ApplicationSerializer
    root "workflow"

    attributes :id,
              :name,
              :description,
              :enabled,
              :workflow_steps_count,
              :starting_category_id,
              :final_category_id

    has_many :workflow_step, serializer: WorkflowStepSerializer, embed: :object, key: :workflow_steps

    def workflow_steps_count
      object.workflow_step.count
    end

    def starting_category_id
      object.workflow_step.first&.category_id
    end

    def final_category_id
      object.workflow_step.last&.category_id
    end
  end
end
