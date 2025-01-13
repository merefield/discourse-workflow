# frozen_string_literal: true

module DiscourseWorkflow
  module TopicExtension
    extend ActiveSupport::Concern

    prepended { validates_with NotMidwayValidator, on: :create }

    def is_workflow_topic?
      WorkflowState.exists?(topic_id: self.id)
    end
  end
end
