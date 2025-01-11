# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowOptionSerializer < ApplicationSerializer

    attributes :id,
              :name,
              :slug
  end
end
