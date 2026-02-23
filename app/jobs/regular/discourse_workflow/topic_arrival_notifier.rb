# frozen_string_literal: true

module Jobs
  module DiscourseWorkflow
    class TopicArrivalNotifier < ::Jobs::Base
      def execute(args)
        return unless topic = Topic.find_by(id: args[:topic_id])

        PostAlerter.new.after_save_post(topic.first_post, true)
      end
    end
  end
end
