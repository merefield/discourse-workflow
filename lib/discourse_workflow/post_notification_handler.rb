# frozen_string_literal: true

##
# Handles :post_alerter_after_save_post events from
# core. Used for notifying users that their chat message
# has been quoted in a post.
module DiscourseWorkflow

  WATCHING_FIRST_POST = 4

  class PostNotificationHandler
    attr_reader :post

    def initialize(post, notified_users)
      @post = post
      @notified_users = notified_users
    end

    def handle
      return false if post.post_type == Post.types[:whisper]
      return false if post.topic.blank?
      return false if post.topic.private_message?
      return false if !post.topic.is_workflow_topic?

      workflow_state = DiscourseWorkflow::WorkflowState.find_by(topic_id: post.topic.id)

      data = { 
        topic_id: post.topic_id,
        user_id: post.user.id,
        username: post.user.username,
        workflow_name: workflow_state.workflow.name,
        workflow_step_name: workflow_state.workflow_step.name,
        topic_title: post.topic.title
      }

      ::CategoryUser.where(notification_level: WATCHING_FIRST_POST).each do |category_user|
        # PostAlerter.create_notification handles many edge cases, such as
        # muting, ignoring, double notifications etc.
        user = category_user.user
        user.notifications.create!(
          notification_type: ::Notification.types[:workflow_topic_arrival],
          high_priority: true,
          data: data.to_json,
        )
      end
    end
  end
end
