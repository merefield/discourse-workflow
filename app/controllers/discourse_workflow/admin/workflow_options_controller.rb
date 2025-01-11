# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowOptionsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      def index
        workflow_options = WorkflowOption.all.order(:id)
        render_json_dump(
          { workflow_options:
          ActiveModel::ArraySerializer.new(workflow_options,
          each_serializer: DiscourseWorkflow::WorkflowOptionSerializer)
          })
      end
    end
  end
end
