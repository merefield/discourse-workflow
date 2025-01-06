# frozen_string_literal: true

module DiscourseWorkflow
  module TopicQueryExtension
    def list_workflow
      create_list(:workflow) do |topics|
        topics.joins("INNER JOIN workflow_states
                              ON workflow_states.topic_id = topics.id
                      INNER JOIN workflows
                              ON workflows.id = workflow_states.workflow_id")
      end
    end
  end
end
