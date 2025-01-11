# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowStepOptionSerializer < ApplicationSerializer

    attributes :id,
              :workflow_option_id,
              :workflow_step_id,
              :workflow_id,
              :position,
              :target_step_id

    has_one :workflow_option, serializer: WorkflowOptionSerializer, embed: :object, key: :workflow_option

    def workflow_id
      object.workflow_step.workflow_id
    end
  end
end
