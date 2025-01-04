module DiscourseWorkflow
  class WorkflowActionController < ApplicationController

    def act
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_create_topic_on_category!(topic.category_id)
      user_id = current_user.id
      option = params[:option]
      if user_id.present? && option.present? && topic.present?
        successful_transition = Transition.new.transition(user_id, topic, option)
      end
      if successful_transition
        render json: success_json
      else
        render json: failed_json
      end
    end
  end
end