# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowStepsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :set_workflow, only: %i[index new create]
      before_action :set_workflow_step, only: %i[show edit update destroy reorder]

      def index
        @workflow_steps =
          if @workflow.present?
            WorkflowStep.where(workflow_id: @workflow.id).order(:position).to_a
          else
            WorkflowStep.all.order(:position).to_a
          end
        ActiveRecord::Associations::Preloader.new(
          records: @workflow_steps,
          associations: [:category, { workflow_step_options: :workflow_option }],
        ).call
        workflow_categories = categories_for_visual(@workflow_steps)
        render_json_dump(
          {
            workflow_steps:
              ActiveModel::ArraySerializer.new(
                @workflow_steps,
                each_serializer: DiscourseWorkflow::WorkflowStepSerializer,
              ),
            workflow_categories:
              ActiveModel::ArraySerializer.new(
                workflow_categories,
                each_serializer: DiscourseWorkflow::WorkflowCategorySerializer,
              ),
          },
        )
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
          if WorkflowStep.count == 0 ||
               WorkflowStep.where(workflow_id: workflow_step.workflow_id).count == 0
            workflow_step.position = 1
          else
            workflow_step.position =
              WorkflowStep.where(workflow_id: workflow_step.workflow_id).maximum(:position).to_i + 1
          end
        end
        if workflow_step.save
          render json: {
                   workflow_step: WorkflowStepSerializer.new(workflow_step, root: false),
                 },
                 status: :created
          # redirect_to edit_workflow_workflow_step_path(workflow_id: workflow_step.workflow_id, id: workflow_step.id)
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

      def reorder
        WorkflowStep.transaction do
          reorder_params = workflow_step_reorder_params
          target_position = reorder_params[:position].to_i
          target_steps =
            WorkflowStep
              .where(workflow_id: @workflow_step.workflow_id, position: target_position)
              .where.not(id: @workflow_step.id)

          target_steps.update_all(position: @workflow_step.position, updated_at: Time.zone.now)
          @workflow_step.update!(reorder_params)
        end

        render json: {
                 workflow_step: WorkflowStepSerializer.new(@workflow_step, root: false),
               },
               status: :ok
      rescue ActiveRecord::RecordInvalid => err
        render_json_error err.record
      end

      def destroy
        WorkflowStep.transaction do
          WorkflowStepOption
            .where(workflow_step_id: @workflow_step.id)
            .or(WorkflowStepOption.where(target_step_id: @workflow_step.id))
            .destroy_all

          if @workflow_step.destroy
            head :no_content
          else
            render_json_error @workflow_step
            raise ActiveRecord::Rollback
          end
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
        params.require(:workflow_step).permit(
          :workflow_id,
          :position,
          :name,
          :description,
          :category_id,
          :ai_enabled,
          :ai_prompt,
          :overdue_days,
        )
      end

      def workflow_step_reorder_params
        params.require(:workflow_step).permit(:position, :category_id)
      end

      def categories_for_visual(workflow_steps)
        categories = workflow_steps.filter_map(&:category)
        parent_category_ids =
          categories.map { |category| category.parent_category_id || category.id }
        category_ids = categories.map(&:id)
        category_ids.concat(Category.where(parent_category_id: parent_category_ids).pluck(:id))

        Category.where(id: category_ids.uniq).order(:position)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end
