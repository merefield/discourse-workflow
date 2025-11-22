# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowVisualisationController < ApplicationController
    requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

    def network
      topic = Topic.find(params[:topic_id])

      if topic.present?
        workflow_state = DiscourseWorkflow::WorkflowState.find_by(topic_id: topic.id)
        workflow       = workflow_state&.workflow

        raise Discourse::NotFound unless workflow

        # Preload steps + options (and their workflow_option) to avoid extra queries when iterating
        steps = workflow.workflow_steps.order(:position).includes(workflow_step_options: :workflow_option)

        # Lanes: unique categories in order of step position
        lanes = steps.map do |step|
          category = Category.find(step.category_id)
          {
            name: category.name,
            link: "/c/#{step.category_id}"
          }
        end.uniq { |lane| lane[:name] }

        # Nodes: one per step
        nodes = steps.map do |step|
          category_name = Category.find(step.category_id).name

          {
            id: step.name,
            lane: lanes.find_index { |lane| lane[:name] == category_name },
            active: step.id == workflow_state.workflow_step_id
          }
        end

        # Links: from each step via its options
        links = []

        # Build a hash of step_id => step to avoid N+1 queries
        steps_by_id = steps.index_by(&:id)

        steps.each do |step|
          step.workflow_step_options.each do |option|
            target_step = steps_by_id[option.target_step_id]
            next unless target_step # Skip if target step is not in this workflow

            links << {
              source: step.name,
              target: target_step.name,
              action: option.workflow_option.name
            }
          end
        end

        render json: {
          lanes: lanes,
          nodes: nodes,
          links: links
        }
      else
        raise Discourse::NotFound
      end
    end
  end
end
