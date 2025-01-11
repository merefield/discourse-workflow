# frozen_string_literal: true
Fabricator(:workflow_option, class_name: "DiscourseWorkflow::WorkflowOption") do
  name { sequence(:name) { |i| "option #{i}" } }
  slug { sequence(:slug) { |i| "option-#{i}" } }
end
