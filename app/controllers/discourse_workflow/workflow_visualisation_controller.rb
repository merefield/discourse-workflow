module DiscourseWorkflow
  class WorkflowVisualisationController < ApplicationController

    def network
      topic = Topic.find(params[:topic_id])

      if topic.present?
        workflow_state = DiscourseWorkflow::WorkflowState.find_by(topic_id: topic.id)
        workflow = workflow_state.workflow

        lanes = workflow.workflow_step.order(:position).map do |step|
          {
            name: Category.find(step.category_id).name, 
            link: "/c/#{step.category_id}"
         }
        end.uniq { |lane| lane[:name] }

        nodes = workflow.workflow_step.order(:position).map do |step|
          {
             id: step.name,
             lane: lanes.find_index { |lane| lane[:name] == Category.find(step.category_id).name },
             active: step.id == workflow_state.workflow_step_id
          }
        end

        links = []

        workflow.workflow_step.order(:position).each do |step|
          step.workflow_step_option.each do |option|
            target_step = WorkflowStep.find(option.target_step_id)
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

        #   const workflowData = {
        # lanes: [
        #     { name: "Preparers", link: "https://example.com/preparers" },
        #     { name: "Reviewers", link: "https://example.com/reviewers" },
        #     { name: "Finalisers", link: "https://example.com/finalisers" },
        #     { name: "Approvers", link: "https://example.com/approvers" },
        #     { name: "Completed", link: "https://example.com/completed" }
        # ],
        # nodes: [
        #     { id: 'Step A', lane: 0, active: false },
        #     { id: 'Step B', lane: 1, active: false },
        #     { id: 'Step C', lane: 0, active: true },
        #     { id: 'Step D', lane: 2, active: false },
        #     { id: 'Step E', lane: 3, active: false },
        #     { id: 'Step F', lane: 4, active: false },

        # ],
        # links: [
        #     { source: 'Step A', target: 'Step B', action: 'start' },
        #     { source: 'Step B', target: 'Step A', action: 'reject' },
        #     { source: 'Step B', target: 'Step C', action: 'accept' },
        #     { source: 'Step C', target: 'Step D', action: 'process' },
        #     { source: 'Step D', target: 'Step E', action: 'finalize' },
        #     { source: 'Step E', target: 'Step F', action: 'confirmed' },
        #     { source: 'Step E', target: 'Step C', action: 'reopended' }
        # ]

      end
    end
  end
end