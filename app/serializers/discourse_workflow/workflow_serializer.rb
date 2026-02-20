# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowSerializer < ApplicationSerializer
    root "workflow"

    attributes :id,
              :name,
              :description,
              :enabled,
              :overdue_days,
              :kanban_compatible,
              :workflow_steps_count,
              :starting_category_id,
              :final_category_id,
              :validation_warnings

    has_many :workflow_steps,
             serializer: WorkflowStepSerializer,
             embed: :object,
             key: :workflow_steps

    def workflow_steps_count
      object.workflow_steps.count
    end

    def starting_category_id
      object.workflow_steps.order(:position).first&.category_id
    end

    def final_category_id
      object.workflow_steps.order(:position).last&.category_id
    end

    def validation_warnings
      object.validation_warnings
    end

    def kanban_compatible
      object.kanban_compatible?
    end
  end
end
