# frozen_string_literal: true

module DiscourseWorkflow
  module NotificationExtension
    extend ActiveSupport::Concern

    def types
      super.merge(
        workflow_topic_arrival: 1001 # Add a new notification type
      )
    end
  end
end
