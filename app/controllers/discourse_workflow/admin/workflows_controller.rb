# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowsController < ::Admin::AdminController
      # requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :find_workflow, only: %i[edit update destroy create]

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
        workflow = Workflow.new(workflow_params)
      end

      def update
        @workflow.update(workflow_params)
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
            :system_prompt,
            :priority,
            :top_p,
            :temperature,
            :default_llm,
            :user_id,
            :max_context_posts,
            :vision_enabled,
            :vision_max_pixels,
            :rag_chunk_tokens,
            :rag_chunk_overlap_tokens,
            :rag_conversation_chunks,
            :question_consolidator_llm,
            :allow_chat_channel_mentions,
            :allow_chat_direct_messages,
            :allow_topic_mentions,
            :allow_workflowl_messages,
            :tool_details,
            :forced_tool_count,
            :force_default_llm,
            allowed_group_ids: [],
            rag_uploads: [:id],
          )

        if tools = params.dig(:workflow, :tools)
          permitted[:tools] = permit_tools(tools)
        end

        permitted
      end

      def permit_tools(tools)
        return [] if !tools.is_a?(Array)

        tools.filter_map do |tool, options, force_tool|
          break nil if !tool.is_a?(String)
          options&.permit! if options && options.is_a?(ActionController::Parameters)

          # this is simpler from a storage perspective, 1 way to store tools
          [tool, options, !!force_tool]
        end
      end
    end
  end
end