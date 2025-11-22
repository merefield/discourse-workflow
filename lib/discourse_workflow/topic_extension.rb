# frozen_string_literal: true

module DiscourseWorkflow
  module TopicExtension
    extend ActiveSupport::Concern

    prepended do
      has_one :workflow_state,
              class_name: "DiscourseWorkflow::WorkflowState",
              foreign_key: :topic_id

      validates_with NotMidwayValidator, on: :create
    end

    def is_workflow_topic?
      workflow_state.present?
    end
  end
end
