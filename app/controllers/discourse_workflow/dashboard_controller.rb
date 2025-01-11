# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowVisualisationController < ApplicationController
    requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

    def index
      workfow_id = params[:workflow_id]
      position_id = params[:position_id]
    end
  end
end
