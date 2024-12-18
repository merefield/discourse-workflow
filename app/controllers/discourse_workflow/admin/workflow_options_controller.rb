module DiscourseWorkflow
  module Admin
    class WorkflowOptionsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      def index
        workflow_options =
          WorkflowOption.ordered.map do |workflow_option|
            WorkflowOptionSerializer.new(workflow_option, root: false)
          end
        render json: { workflow_options: workflow_options }
      end
    end
  end
end