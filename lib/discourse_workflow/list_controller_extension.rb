# frozen_string_literal: true

module DiscourseWorkflow
  module ListControllerExtension
    extend ActiveSupport::Concern

    prepended do
      before_action :ensure_discourse_workflow, only: %i[workflow workflow_charts]
      skip_before_action :ensure_logged_in, only: %i[workflow]
    end

    def workflow
      list_opts = build_topic_list_options
      user = list_target_user || current_user
      workflow_topic_ids_scope = DiscourseWorkflow::WorkflowState.all.select(:topic_id).distinct
      workflow_filters_applied = false

      if user.present? && params[:my_categories] == "1"
        allowed_category_ids = Category.topic_create_allowed(Guardian.new(user)).select(:id)
        workflow_topic_ids_scope =
          workflow_topic_ids_scope.joins(:topic).where(
            topics: {
              category_id: allowed_category_ids,
            },
          )
        workflow_filters_applied = true
      end

      if params[:overdue] == "1"
        default_overdue_days = SiteSetting.workflow_overdue_days_default.to_i
        workflow_topic_ids_scope =
          workflow_topic_ids_scope
            .joins(:workflow_step, :workflow)
            .where(
              "COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) > 0",
              default_overdue_days,
            )
            .where(
              "workflow_states.updated_at <= NOW() - (COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) * INTERVAL '1 day')",
              default_overdue_days,
            )
        workflow_filters_applied = true
      elsif params[:overdue_days].present? && params[:overdue_days].to_i > 0
        cutoff = params[:overdue_days].to_i.days.ago
        workflow_topic_ids_scope =
          workflow_topic_ids_scope.where("workflow_states.updated_at <= ?", cutoff)
        workflow_filters_applied = true
      end

      if params[:workflow_step_position].present? && params[:workflow_step_position].to_i > 0
        workflow_topic_ids_scope =
          workflow_topic_ids_scope.joins(:workflow_step).where(
            workflow_steps: {
              position: params[:workflow_step_position].to_i,
            },
          )
        workflow_filters_applied = true
      end

      list_opts[:topic_ids] = workflow_topic_ids_scope if workflow_filters_applied

      list = TopicQuery.new(user, list_opts).public_send("list_workflow")
      list_query_opts = list_opts.except(:topic_ids)
      list.more_topics_url = url_for(construct_url_with(:next, list_query_opts))
      list.prev_topics_url = url_for(construct_url_with(:prev, list_query_opts))
      respond_with_list(list)
    end

    def workflow_charts
      if !DiscourseWorkflow::ChartsPermissions.can_view?(current_user)
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "discourse_workflow.errors.charts_access_denied",
              )
      end

      workflow
    end

    protected

    def ensure_discourse_workflow
      raise Discourse::NotFound if !SiteSetting.workflow_enabled
    end
  end
end
