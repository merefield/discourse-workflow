# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :find_workflow, only: %i[edit show update destroy]

      def index
        @workflows = Workflow.order(:enabled).order(:name).order(:id)
        render_json_dump(
          { workflows:
          ActiveModel::ArraySerializer.new(@workflows,
          each_serializer: DiscourseWorkflow::WorkflowSerializer)
          })
      end

      def new
      end

      def edit
        render json: WorkflowSerializer.new(@workflow)
      end

      def show
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

        permitted
      end
    end
  end
end
