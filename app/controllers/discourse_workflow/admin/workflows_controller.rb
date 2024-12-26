# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowsController < ::Admin::AdminController
      # requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :find_workflow, only: %i[edit update destroy]

      def index
        workflows =
          Workflow.ordered.map do |workflow|
            WorkflowSerializer.new(workflow, root: false)
          end
        render json: { workflows: workflows }
      end

      def new
      end

      def edit
        render json: WorkflowSerializer.new(@workflow)
      end

      def create
        #byebug
        workflow = Workflow.new(workflow_params)
        workflow.save!
      end

      def update
       if @workflow.update(workflow_params)
          render json: WorkflowSerializer.new(@workflow, root: false)
        else
          render_json_error @workflow
        end
      end

      def destroy
        if @workflow.destroy
          head :no_content
        else
          render_json_error @workflow
        end
      end

      def find_workflow
        @workflow = Workflow.find(params[:id])
      end

      def workflow_params
        permitted =
          params.require(:workflow).permit(
            :name,
            :description,
            :enabled,
          )

        # if tools = params.dig(:workflow, :tools)
        #   permitted[:tools] = permit_tools(tools)
        # end

        permitted
      end

      # def permit_tools(tools)
      #   return [] if !tools.is_a?(Array)

      #   tools.filter_map do |tool, options, force_tool|
      #     break nil if !tool.is_a?(String)
      #     options&.permit! if options && options.is_a?(ActionController::Parameters)

      #     # this is simpler from a storage perspective, 1 way to store tools
      #     [tool, options, !!force_tool]
      #   end
      # end
    end
  end
end