# app/controllers/discourse_workflow/admin/workflow_steps_controller.rb
module DiscourseWorkflow
  module Admin
    class WorkflowStepsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :set_workflow, only: [:index, :new, :create]
      before_action :set_workflow_step, only: [:show, :edit, :update, :destroy]

      def index
        if @workflow.present?
          @workflow_steps = WorkflowStep.where(workflow_id: @workflow.id).order(:position)
        else
          @workflow_steps = WorkflowStep.all.order(:position)
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
        workflow_step = WorkflowStep.new(workflow_step_params)
        if workflow_step.save
          render json: {
            workflow_step: WorkflowStepSerializer.new(workflow_step, root: false),
             },
          status: :created
        else
          render_json_error workflow_step
        end
      end

      def create
        workflow_step = WorkflowStep.new(workflow_step_params)
        if !workflow_step.position.present?
          if WorkflowStep.count == 0 || WorkflowStep.where(workflow_id: workflow_step.workflow_id).count == 0
            workflow_step.position = 1
          else
            workflow_step.position = WorkflowStep.maximum(:position) + 1
          end
        end
        if workflow_step.save
          render json: {
            workflow_step: WorkflowStepSerializer.new(workflow_step, root: false),
             },
          status: :created
        else
          render_json_error workflow_step
        end
      end

      def edit
      end

      def update
        if @workflow_step.update(workflow_step_params)
          render json: {
            workflow_step: WorkflowStepSerializer.new(@workflow_step, root: false),
             },
          status: :ok
        else
          render_json_error @workflow_step
        end
      end

      def destroy
        if @workflow_step.destroy
          head :no_content
        else
          render_json_error @workflow_step
        end
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
        params.require(:workflow_step).permit(:workflow_id, :position, :name, :description, :category_id, :ai_enabled, :ai_prompt, :other_attributes...)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end
