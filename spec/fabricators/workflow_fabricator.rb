# frozen_string_literal: true
Fabricator(:workflow, class_name: "DiscourseWorkflow::Workflow") do
  name { sequence(:name) { |i| "This is a test workflow #{i}" } }
  description { sequence(:description) { |i| "This is a test description #{i}" } }
end
