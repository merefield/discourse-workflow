# app/controllers/discourse_workflow/admin/workflow_steps_controller.rb
module DiscourseWorkflow
  module Admin
    class WorkflowStepsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :set_workflow, only: [:index, :new, :create]
      before_action :set_workflow_step, only: [:show, :edit, :update, :destroy]

      def index
        @workflow_steps = @workflow.workflow_steps
      end

      def show
      end

      def new
        @workflow_step = @workflow.workflow_steps.build
      end

      def create
        @workflow_step = @workflow.workflow_steps.build(workflow_step_params)
        if @workflow_step.save
          redirect_to admin_plugins_discourse_workflow_workflows_path, notice: 'Workflow step was successfully created.'
        else
          render :new
        end
      end

      def edit
      end

      def update
        if @workflow_step.update(workflow_step_params)
          redirect_to admin_plugins_discourse_workflow_workflows_path, notice: 'Workflow step was successfully updated.'
        else
          render :edit
        end
      end

      def destroy
        @workflow_step.destroy
        redirect_to admin_plugins_discourse_workflow_workflows_path, notice: 'Workflow step was successfully destroyed.'
      end

      private

      def set_workflow
        @workflow = Workflow.find(params[:workflow_id])
      end

      def set_workflow_step
        @workflow_step = WorkflowStep.find(params[:id])
      end

      def workflow_step_params
        params.require(:workflow_step).permit(:name, :description, :position, :other_attributes...)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end
