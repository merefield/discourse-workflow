# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowChartsController < ApplicationController
    requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :ensure_workflow_enabled
    before_action :ensure_can_view_charts

    def index
      weeks = normalized_weeks
      selected_workflow = selected_chart_workflow
      date_range = chart_date_range(weeks)

      render_json_dump(
        {
          weeks: weeks,
          labels: date_range.map(&:iso8601),
          range_start: date_range.first.iso8601,
          range_end: date_range.last.iso8601,
          selected_workflow_id: selected_workflow&.id,
          selected_workflow_name: selected_workflow&.name,
          series: build_series(selected_workflow, date_range),
        },
      )
    end

    private

    def ensure_workflow_enabled
      raise Discourse::NotFound if !SiteSetting.workflow_enabled
    end

    def ensure_can_view_charts
      return if ::DiscourseWorkflow::ChartsPermissions.can_view?(current_user)

      raise Discourse::InvalidAccess.new(
              nil,
              nil,
              custom_message: "discourse_workflow.errors.charts_access_denied",
            )
    end

    def normalized_weeks
      return 2 if params[:weeks].blank?

      requested = params[:weeks].to_i
      requested = 1 if requested <= 0
      [requested, 12].min
    end

    def selected_chart_workflow
      workflow_scope = ::DiscourseWorkflow::Workflow.where(enabled: true).ordered
      selected_id = params[:workflow_id].to_i

      if selected_id > 0
        selected_workflow = load_chart_workflow(workflow_scope.where(id: selected_id))
        return selected_workflow if selected_workflow.present?
      end

      load_chart_workflow(workflow_scope)
    end

    def load_chart_workflow(scope)
      scope.includes(workflow_steps: { category: :parent_category }).first
    end

    def chart_date_range(weeks)
      end_date = Date.current.end_of_week(:saturday)
      start_date = end_date - ((weeks * 7) - 1).days
      (start_date..end_date).to_a
    end

    def build_series(workflow, date_range)
      return [] if workflow.blank?

      steps = workflow.workflow_steps.sort_by { |step| step.position.to_i }
      return [] if steps.blank?
      today = Date.current

      step_ids = steps.map(&:id)
      stats =
        ::DiscourseWorkflow::WorkflowStat
          .where(workflow_id: workflow.id, workflow_step_id: step_ids)
          .where(cob_date: date_range.first.beginning_of_day..date_range.last.end_of_day)
          .group("DATE(cob_date)", :workflow_step_id)
          .sum(:count)
      counts_by_day_step =
        stats.each_with_object({}) do |((date_value, step_id), count), memo|
          memo[[date_value.to_date, step_id]] = count
        end

      steps.map do |step|
        category = step.category
        {
          step_id: step.id,
          step_name: step.name,
          step_position: step.position.to_i,
          color: category&.color || category&.parent_category&.color,
          data:
            date_range.map do |date|
              date > today ? nil : counts_by_day_step.fetch([date, step.id], 0)
            end,
        }
      end
    end
  end
end
