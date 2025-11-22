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

        # Build a hash of category_id => category to avoid N+1 queries
        category_ids = steps.filter_map(&:category_id).uniq
        categories_by_id = Category.where(id: category_ids).index_by(&:id)

        # Build a hash of step_id => step for quick lookups in links
        steps_by_id = steps.index_by(&:id)

        # Lanes: unique categories in order of step position
        lanes = steps.map do |step|
          category = categories_by_id[step.category_id]
          next unless category

          {
            name: category.name,
            link: "/c/#{step.category_id}"
          }
        end.compact.uniq { |lane| lane[:name] }

        # Build lane name to index hash for efficient lookups
        lane_index_by_name = lanes.each_with_index.to_h { |lane, idx| [lane[:name], idx] }

        # Nodes: one per step
        nodes = steps.map do |step|
          category = categories_by_id[step.category_id]
          next unless category

          category_name = category.name

          {
            id: step.name,
            lane: lane_index_by_name[category_name],
            active: step.id == workflow_state.workflow_step_id
          }
        end.compact

        # Links: from each step via its options
        links = []

        steps.each do |step|
          step.workflow_step_options.each do |option|
            target_step = steps_by_id[option.target_step_id]
            next unless target_step

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
