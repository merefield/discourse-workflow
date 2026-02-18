# frozen_string_literal: true

module DiscourseWorkflow
  module ListControllerExtension
    extend ActiveSupport::Concern

    prepended do
      before_action :ensure_discourse_workflow, only: %i[workflow]
      skip_before_action :ensure_logged_in, only: %i[workflow]
    end

    def workflow
      list_opts = build_topic_list_options
      user = list_target_user || current_user
      filtered_topic_ids = nil

      if user.present? && params[:my_categories] == "1"
        allowed_category_ids =
          Category.topic_create_allowed(Guardian.new(user)).pluck(:id)

        my_category_topic_ids =
          DiscourseWorkflow::WorkflowState
            .joins(:topic)
            .where(topics: { category_id: allowed_category_ids })
            .pluck(:topic_id)
            .uniq

        filtered_topic_ids =
          filtered_topic_ids ? (filtered_topic_ids & my_category_topic_ids) : my_category_topic_ids
      end

      if params[:overdue] == "1"
        default_overdue_days = SiteSetting.workflow_overdue_days_default.to_i
        overdue_topic_ids =
          DiscourseWorkflow::WorkflowState
            .joins(:workflow_step, :workflow)
            .where(
              "COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) > 0",
              default_overdue_days,
            )
            .where(
              "workflow_states.updated_at <= NOW() - (COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) * INTERVAL '1 day')",
              default_overdue_days,
            )
            .pluck(:topic_id)
            .uniq

        filtered_topic_ids =
          filtered_topic_ids ? (filtered_topic_ids & overdue_topic_ids) : overdue_topic_ids
      elsif params[:overdue_days].present? && params[:overdue_days].to_i > 0
        cutoff = params[:overdue_days].to_i.days.ago
        overdue_topic_ids =
          DiscourseWorkflow::WorkflowState
            .where("updated_at <= ?", cutoff)
            .pluck(:topic_id)
            .uniq

        filtered_topic_ids =
          filtered_topic_ids ? (filtered_topic_ids & overdue_topic_ids) : overdue_topic_ids
      end

      if params[:workflow_step_position].present? &&
           params[:workflow_step_position].to_i > 0
        position_topic_ids =
          DiscourseWorkflow::WorkflowState
            .joins(:workflow_step)
            .where(workflow_steps: { position: params[:workflow_step_position].to_i })
            .pluck(:topic_id)
            .uniq

        filtered_topic_ids =
          filtered_topic_ids ? (filtered_topic_ids & position_topic_ids) : position_topic_ids
      end

      if filtered_topic_ids
        list_opts[:topic_ids] = filtered_topic_ids.presence || [-1]
      end

      list = TopicQuery.new(user, list_opts).public_send("list_workflow")
      list.more_topics_url = url_for(construct_url_with(:next, list_opts))
      list.prev_topics_url = url_for(construct_url_with(:prev, list_opts))
      respond_with_list(list)
    end

    protected

    def ensure_discourse_workflow
      if !SiteSetting.workflow_enabled
        raise Discourse::NotFound
      end
    end
  end
end
