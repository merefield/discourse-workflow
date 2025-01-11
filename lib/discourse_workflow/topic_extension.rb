# frozen_string_literal: true

module DiscourseWorkflow
  module TopicExtension
    extend ActiveSupport::Concern

    prepended { validates_with NotMidwayValidator, on: :create }
  end
end
