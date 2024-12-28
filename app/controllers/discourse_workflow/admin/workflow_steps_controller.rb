# app/controllers/discourse_workflow/admin/workflow_steps_controller.rb
module DiscourseWorkflow
  module Admin
    class WorkflowStepsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :set_workflow, only: [:index, :new, :create]
      before_action :set_workflow_step, only: [:show, :edit, :update, :destroy]

      def index
        if @workflow.present?
          @workflow_steps = WorkflowStep.where(workflow_id: @workflow.id)
        else
          @workflow_steps = WorkflowStep.all
        end
        render_json_dump (
          { workflow_steps:
          ActiveModel::ArraySerializer.new(@workflow_steps, 
          each_serializer: DiscourseWorkflow::WorkflowStepSerializer)
          })
      end

      def show
      end

      def new
        @workflow_step = @workflow.workflow_steps.build
      end

      def create
        # @workflow_step = @workflow.workflow_steps.build(workflow_step_params)
        # @workflow_step.save!
        workflow_step = WorkflowStep.new(workflow_step_params)
        workflow_step.save!
        # if @workflow_step.save
        #   redirect_to admin_plugins_discourse_workflow_workflows_path, notice: 'Workflow step was successfully created.'
        # else
        #   render :new
        # end
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
        workflow_id = params.dig(:workflow_id)
        if workflow_id.present?
            @workflow = Workflow.find(workflow_id)
        else
          @workflow = nil
        end
      end

      def set_workflow_step
        @workflow_step = WorkflowStep.find(params[:id])
      end

      def workflow_step_params
        params.require(:workflow_step).permit(:workflow_id, :name, :description, :position, :other_attributes...)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end