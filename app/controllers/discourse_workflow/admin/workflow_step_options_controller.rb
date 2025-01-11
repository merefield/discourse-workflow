# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowStepOptionsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :set_workflow_step, only: [:index, :new, :create]
      before_action :set_workflow_step_option, only: [:show, :edit, :update, :destroy]

      def index
        if @workflow_step.present?
          @workflow_step_options = WorkflowStepOption.where(workflow_step_id: @workflow_step.id).order(:position)
        else
          @workflow_step_options = WorkflowStepOption.all.order(:position)
        end
        render_json_dump(
          { workflow_step_options:
          ActiveModel::ArraySerializer.new(@workflow_step_options,
          each_serializer: DiscourseWorkflow::WorkflowStepOptionSerializer)
          })
      end

      def show
      end

      def new
        workflow_step_option = WorkflowStepOption.new(workflow_step_option_params)
        if workflow_step_option.save
          render json: {
            workflow_step_option: WorkflowStepOptionSerializer.new(workflow_step_option, root: false),
             },
                 status: :created
        else
          render_json_error workflow_step_option
        end
      end

      def create
        workflow_step_option = WorkflowStepOption.new(workflow_step_option_params)
        if !workflow_step_option.position.present?
          if WorkflowStepOption.count == 0 || WorkflowStepOption.where(workflow_step_id: workflow_step_option.workflow_step_id).count == 0
            workflow_step_option.position = 1
          else
            workflow_step_option.position = WorkflowStepOption..where(workflow_step_id: workflow_step_option.workflow_step_id).maximum(:position) + 1
          end
        end
        if workflow_step_option.save
          render json: {
            workflow_step_option: WorkflowStepOptionSerializer.new(workflow_step_option, root: false),
             },
                 status: :created
        else
          render_json_error workflow_step_option
        end
      end

      def edit
      end

      def update
        if @workflow_step_option.update(workflow_step_option_params)
          render json: {
            workflow_step_option: WorkflowStepOptionSerializer.new(@workflow_step_option, root: false),
             },
                 status: :ok
        else
          render_json_error @workflow_step_option
        end
      end

      def destroy
        if @workflow_step_option.destroy
          head :no_content
        else
          render_json_error @workflow_step_option
        end
      end

      private

      def set_workflow_step
        id = params.dig(:workflow_step_id)
        if id.present?
          @workflow_step = WorkflowStep.find(id)
        else
          @workflow_step = nil
        end
      end

      def set_workflow_step_option
        @workflow_step_option = WorkflowStepOption.find(params[:id])
      end

      def workflow_step_option_params
        params.require(:workflow_step_option).permit(:position, :workflow_step_id, :workflow_option_id, :target_step_id, :other_attributes...)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end
